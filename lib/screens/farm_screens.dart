import 'package:flutter/material.dart';

import '../data/app_scope.dart';
import '../data/farm_repository.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/plot_map.dart';
import 'data_screens.dart';
import 'main_tabs.dart';

Tone toneFor(SoilStatus s) => switch (s) {
      SoilStatus.normal => Tone.green,
      SoilStatus.watch => Tone.amber,
      SoilStatus.check => Tone.red,
    };

/// Return to the main shell (works both from onboarding and from inside the app).
void backToShell(BuildContext context, String msg) {
  final messenger = ScaffoldMessenger.of(context);
  openShell(context);
  messenger.showSnackBar(SnackBar(content: Text(msg)));
}

// ---------------------------------------------------------------- MAIN-02 Farm list

class FarmListScreen extends StatefulWidget {
  const FarmListScreen({super.key});
  @override
  State<FarmListScreen> createState() => _FarmListScreenState();
}

class _FarmListScreenState extends State<FarmListScreen> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final all = repo.farms;
    if (all.isEmpty) {
      return ScreenScaffold(
        title: 'ฟาร์มของฉัน',
        bell: true,
        children: [
          const InfoBox(tone: Tone.grey, title: 'ยังไม่มีฟาร์ม', body: 'เริ่มต้นด้วยการเพิ่มฟาร์มแรกของคุณ'),
          const Gap(12),
          OutlinedButton.icon(
            onPressed: () => go(context, const CreateFarmScreen()),
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มฟาร์ม'),
          ),
        ],
      );
    }
    final farms = all.where((f) => f.name.contains(q)).toList();
    return ScreenScaffold(
      title: 'ฟาร์มของฉัน',
      bell: true,
      children: [
        TextField(
          onChanged: (v) => setState(() => q = v),
          decoration: const InputDecoration(hintText: 'ค้นหาฟาร์ม', prefixIcon: Icon(Icons.search)),
        ),
        const Gap(12),
        Wrap(spacing: 8, runSpacing: 6, children: [
          Pill('ทั้งหมด ${all.length} ฟาร์ม', tone: Tone.grey),
          const Pill('ข้อมูลพร้อมใช้', tone: Tone.blue),
        ]),
        const SectionHeader('เลือกฟาร์ม', action: 'เรียงล่าสุด', top: 16),
        for (final f in farms) _farmCard(context, repo, f, highlighted: f.id == all.first.id),
        if (farms.isEmpty) const InfoBox(tone: Tone.grey, title: 'ไม่พบฟาร์มที่ค้นหา'),
        const SectionHeader('ทางลัดที่ใช้บ่อย'),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => go(context, const CreateFarmScreen()),
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มฟาร์ม'),
            ),
          ),
          const Gap(10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => go(context, const PlotListScreen()),
              icon: const Icon(Icons.crop_square),
              label: const Text('ดูทุกแปลง'),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _farmCard(BuildContext context, FarmRepository repo, FarmRecord f, {required bool highlighted}) {
    final status = repo.farmStatus(f.id);
    final when = formatWhen(f.updatedAt, repo.clock());
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: highlighted ? AppColors.green : AppColors.line,
      borderWidth: highlighted ? 1.5 : 1,
      onTap: () => go(context, PlotListScreen(farmId: f.id)),
      child: Column(
        children: [
          Row(
            children: [
              const IconCircle(Icons.agriculture_outlined),
              const Gap(12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.name, style: TS.h3),
                  const Gap(2),
                  Text(f.caretaker.isEmpty ? when : 'ผู้ดูแล: ${f.caretaker} • $when', style: TS.small),
                ]),
              ),
              Pill(status == SoilStatus.normal ? 'ปกติ' : 'เฝ้าดู',
                  tone: toneFor(status), icon: status == SoilStatus.normal ? Icons.check : Icons.priority_high),
            ],
          ),
          const Divider(height: 24),
          Row(children: [
            Text('${repo.plotsOf(f.id).length} แปลง', style: TS.title),
            const Spacer(),
            const Text('ดูแปลง', style: TS.link),
            const Icon(Icons.chevron_right, color: AppColors.green),
          ]),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- MAIN-03 Plot list

const _cropOptions = ['มันสำปะหลัง', 'ข้าว', 'อ้อย', 'ข้าวโพด', 'อื่น ๆ'];

List<String> _withExtra(List<String> options, String value) =>
    value.isEmpty || options.contains(value) ? options : [value, ...options];

/// Farm names for a picker; later duplicates get ' (2)', ' (3)' so each label maps to one index.
List<String> _farmLabels(List<FarmRecord> farms) {
  final seen = <String, int>{};
  final out = <String>[];
  for (final f in farms) {
    final n = (seen[f.name] ?? 0) + 1;
    seen[f.name] = n;
    out.add(n == 1 ? f.name : '${f.name} ($n)');
  }
  return out;
}

String _statusText(SoilStatus s) => s == SoilStatus.normal ? 'ดินโดยรวมปกติ' : 'ควรเฝ้าดู';

class PlotListScreen extends StatefulWidget {
  const PlotListScreen({super.key, this.farmId});
  final String? farmId;
  @override
  State<PlotListScreen> createState() => _PlotListScreenState();
}

class _PlotListScreenState extends State<PlotListScreen> {
  int view = 0;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final id = widget.farmId ?? (repo.farms.isEmpty ? null : repo.farms.first.id);
    final farm = id == null ? null : repo.farm(id);
    if (farm == null) {
      return const ScreenScaffold(
        title: 'แปลงในฟาร์ม',
        bell: true,
        children: [InfoBox(tone: Tone.grey, title: 'ไม่พบฟาร์มนี้')],
      );
    }
    final now = repo.clock();
    final plots = repo.plotsOf(farm.id);
    final farmStatus = repo.farmStatus(farm.id);
    return ScreenScaffold(
      title: 'แปลงในฟาร์ม',
      bell: true,
      bottom: FilledButton.icon(
        onPressed: () => go(context, CreatePlotScreen(farmId: farm.id)),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มแปลงใหม่'),
      ),
      children: [
        AppCard(
          child: Row(children: [
            const IconCircle(Icons.agriculture_outlined),
            const Gap(12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(farm.name, style: TS.h3),
                Text('${plots.length} แปลง • อัปเดตล่าสุด ${formatWhen(farm.updatedAt, now)}', style: TS.small),
              ]),
            ),
            Pill(farmStatus == SoilStatus.normal ? 'ปกติ' : 'เฝ้าดู',
                tone: toneFor(farmStatus), icon: farmStatus == SoilStatus.normal ? Icons.check : Icons.priority_high),
            IconButton(
              tooltip: 'แก้ไขฟาร์ม',
              onPressed: () => go(context, CreateFarmScreen(farmId: farm.id)),
              icon: const Icon(Icons.edit_outlined),
            ),
          ]),
        ),
        const Gap(12),
        Segmented(options: const ['การ์ด', 'ลิสต์'], selected: view, onChanged: (i) => setState(() => view = i)),
        SectionHeader('แปลงทั้งหมด',
            action: '+ เพิ่มแปลง', onAction: () => go(context, CreatePlotScreen(farmId: farm.id)), top: 16),
        if (plots.isEmpty) const InfoBox(tone: Tone.grey, title: 'ยังไม่มีแปลง', body: 'เริ่มต้นด้วยการเพิ่มแปลงแรก'),
        for (final p in plots) _plotItem(context, repo, p, now),
      ],
    );
  }

  Widget _plotItem(BuildContext context, FarmRepository repo, PlotRecord p, DateTime now) {
    final status = repo.plotStatus(p.id);
    final latest = repo.latestRound(p.id);
    final checked = latest == null ? 'ยังไม่เคยวัด' : 'ตรวจล่าสุด ${formatWhen(latest.takenAt, now)}';
    void open() => go(context, PlotDetailScreen(plotId: p.id));
    if (view != 0) {
      return ListRowCard(
        icon: Icons.crop_square,
        title: p.name,
        subtitle: '${p.crop} • ${p.rai.toStringAsFixed(1)} ไร่ • $checked',
        tone: toneFor(status),
        onTap: open,
      );
    }
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      onTap: open,
      child: Row(children: [
        SizedBox(
          width: 72,
          child: PlotMap(
            height: 72,
            radius: 12,
            polygon: p.boundary,
            closed: p.boundary.length >= 3,
            markers: [PlotMarker(const Offset(0.5, 0.5), kindForStatus(status))],
          ),
        ),
        const Gap(14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: TS.h3),
            Text('พืช: ${p.crop}', style: TS.small),
            const Gap(6),
            Pill(_statusText(status), tone: toneFor(status), small: true),
            const Gap(4),
            Text(checked, style: TS.tiny),
          ]),
        ),
        Text('${p.rai.toStringAsFixed(1)} ไร่', style: TS.title),
      ]),
    );
  }
}

// ---------------------------------------------------------------- FLOW-06 Plot detail

class PlotDetailScreen extends StatefulWidget {
  const PlotDetailScreen({super.key, this.plotId});
  final String? plotId;
  @override
  State<PlotDetailScreen> createState() => _PlotDetailScreenState();
}

class _PlotDetailScreenState extends State<PlotDetailScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final p = repo.plot(widget.plotId ?? SeedIds.plotA);
    if (p == null) {
      return const ScreenScaffold(
        title: 'รายละเอียดแปลง',
        bell: true,
        children: [InfoBox(tone: Tone.grey, title: 'ไม่พบแปลงนี้')],
      );
    }
    final now = repo.clock();
    final latest = repo.latestRound(p.id);
    final status = repo.plotStatus(p.id);
    final farmName = repo.farm(p.farmId)?.name ?? '';
    final watch = latest?.watchCount ?? 0;
    final moisture = latest?.avg((r) => r.moisture);
    final ph = latest?.avg((r) => r.ph);
    return ScreenScaffold(
      title: 'รายละเอียดแปลง',
      bell: true,
      actions: [
        IconButton(
          tooltip: 'แก้ไขแปลง',
          onPressed: () => go(context, EditPlotScreen(plotId: p.id)),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      children: [
        AppCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.eco_outlined, color: AppColors.green),
            const Gap(10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: TS.h2),
                Text('$farmName • ${p.rai.toStringAsFixed(1)} ไร่ • ${p.crop}', style: TS.small),
                const Gap(8),
                Pill(_statusText(status), tone: toneFor(status), small: true),
              ]),
            ),
            if (latest != null) Text(formatWhen(latest.takenAt, now), style: TS.small),
          ]),
        ),
        const Gap(12),
        TwoCol(children: [
          ValueTile(label: 'จุดวัดล่าสุด', value: latest == null ? '—' : '${latest.points.length} จุด'),
          ValueTile(label: 'ความชื้นเฉลี่ย', value: moisture == null ? '—' : '${moisture.toStringAsFixed(0)}%'),
          ValueTile(label: 'pH เฉลี่ย', value: ph == null ? '—' : ph.toStringAsFixed(1)),
          ValueTile(label: 'จุดเฝ้าดู', value: latest == null ? '—' : '$watch จุด'),
        ]),
        if (latest == null)
          const InfoBox(
            tone: Tone.grey,
            title: 'ยังไม่มีผลการวัด',
            body: 'เริ่มวัดดินในแปลงนี้เพื่อดูค่าเฉลี่ยและประวัติ',
            margin: EdgeInsets.only(top: 12),
          ),
        const Gap(4),
        Segmented(options: const ['ภาพรวม', 'แผนที่', 'AI', 'ประวัติ'], selected: tab, onChanged: (i) => setState(() => tab = i)),
        const Gap(14),
        ..._tabBody(context, repo, p.id, watch),
      ],
    );
  }

  List<Widget> _tabBody(BuildContext context, FarmRepository repo, String plotId, int watch) {
    return switch (tab) {
      0 => _overview(context, watch),
      1 => [
          PlotMap(
            markers: soilMarkers(labels: true),
            zones: true,
            height: 320,
            onTapMarker: (i) => go(context, PointDetailScreen(point: Mock.points[i])),
          ),
          const Gap(8),
          const Text('แตะจุดเพื่อดูรายละเอียด • โซนสีเป็นค่าประมาณ', style: TS.tiny),
        ],
      2 => [
          _aiCard(context),
          const Gap(12),
          OutlinedButton(onPressed: () => go(context, const AiObservationScreen()), child: const Text('ดูข้อสังเกตทั้งหมด')),
        ],
      _ => _history(context, repo, plotId),
    };
  }

  List<Widget> _history(BuildContext context, FarmRepository repo, String plotId) {
    final rounds = repo.roundsOf(plotId);
    final now = repo.clock();
    if (rounds.isEmpty) return const [InfoBox(tone: Tone.grey, title: 'ยังไม่มีประวัติการวัด')];
    return [
      for (final r in rounds)
        ListRowCard(
          icon: Icons.history,
          title: formatWhen(r.takenAt, now),
          subtitle: 'ตรวจครบ ${r.points.length} จุด • เฝ้าดู ${r.watchCount} จุด',
          onTap: () => go(context, const CompareScreen()),
        ),
    ];
  }

  List<Widget> _overview(BuildContext context, int watch) => [
        AppCard(
          onTap: () => setState(() => tab = 1),
          child: Row(children: [
            SizedBox(width: 120, child: PlotMap(markers: soilMarkers(), height: 80, radius: 12)),
            const Gap(14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ค่าส่วนใหญ่ปกติ', style: TS.h3),
                if (watch > 0) ...[
                  const Gap(4),
                  Text('! $watch จุดควรตรวจสอบเพิ่มเติม', style: TS.small),
                  const Gap(6),
                  Text('ดู $watch จุดบนแผนที่ →', style: TS.link),
                ],
              ]),
            ),
          ]),
        ),
        const Gap(12),
        _aiCard(context),
      ];

  Widget _aiCard(BuildContext context) => DarkCard(
        title: 'AI ข้อสังเกต • 14 จุด',
        lines: const ['ค่าส่วนใหญ่อยู่ใกล้ค่าเฉลี่ยของแปลง', 'โซนล่างความชื้นต่ำ ควรวัดซ้ำ'],
        footer: 'ยังไม่ผ่านการทบทวนโดยผู้เชี่ยวชาญ',
        action: SizedBox(
          height: 36,
          child: FilledButton(
            onPressed: () => go(context, const AiChatScreen()),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.dark,
              minimumSize: const Size(0, 36),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            child: const Text('ถาม AI'),
          ),
        ),
      );
}

// ---------------------------------------------------------------- FLOW-10 Create / edit farm

class CreateFarmScreen extends StatefulWidget {
  const CreateFarmScreen({super.key, this.farmId});
  final String? farmId;
  @override
  State<CreateFarmScreen> createState() => _CreateFarmScreenState();
}

class _CreateFarmScreenState extends State<CreateFarmScreen> {
  static const _caretakerOptions = ['เจ้าหน้าที่ฟาร์ม (ผู้ดูแลหลัก)', 'ทีมโครงการ', 'นักวิจัย / นิสิต'];
  static const _locationOptions = ['อ.กันทรวิชัย จ.มหาสารคาม', 'อ.เมือง จ.มหาสารคาม', 'ใช้ตำแหน่งปัจจุบัน'];

  final name = TextEditingController();
  final note = TextEditingController();
  String caretaker = _caretakerOptions.first;
  String location = _locationOptions.first;
  bool notify = true;
  bool _loaded = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final id = widget.farmId;
    if (id == null) return;
    final f = AppScope.read(context).farm(id);
    if (f == null) return;
    name.text = f.name;
    note.text = f.note;
    caretaker = f.caretaker;
    location = f.location;
    notify = f.notify;
  }

  @override
  void dispose() {
    name.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = AppScope.read(context);
    final n = name.text.trim();
    if (n.isEmpty) {
      toast(context, 'กรุณาใส่ชื่อฟาร์ม');
      return;
    }
    setState(() => _saving = true);
    try {
      final id = widget.farmId;
      if (id == null) {
        await repo.addFarm(name: n, caretaker: caretaker, location: location, note: note.text.trim(), notify: notify);
      } else {
        final existing = repo.farm(id);
        if (existing == null) throw StateError('Farm not found: $id');
        await repo.updateFarm(existing.copyWith(
            name: n, caretaker: caretaker, location: location, note: note.text.trim(), notify: notify));
      }
      if (!mounted) return;
      backToShell(context, 'บันทึกฟาร์ม "$n" แล้ว');
    } on ArgumentError {
      if (!mounted) return;
      setState(() => _saving = false);
      toast(context, 'กรุณาใส่ชื่อฟาร์ม');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      toast(context, 'บันทึกไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  Future<void> _delete() async {
    final repo = AppScope.read(context);
    final ok = await confirm(context, 'ลบฟาร์มนี้?', 'แปลงและประวัติการวัดทั้งหมดจะถูกลบถาวร', ok: 'ลบถาวร', danger: true);
    if (!ok || !mounted) return;
    try {
      await repo.deleteFarm(widget.farmId!);
      if (!mounted) return;
      backToShell(context, 'ลบฟาร์มแล้ว');
    } catch (_) {
      if (!mounted) return;
      toast(context, 'บันทึกไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.farmId != null;
    if (editing && AppScope.of(context).farm(widget.farmId!) == null) {
      return const ScreenScaffold(
        title: 'แก้ไขฟาร์ม',
        children: [InfoBox(tone: Tone.grey, title: 'ไม่พบฟาร์มนี้')],
      );
    }
    return ScreenScaffold(
      title: editing ? 'แก้ไขฟาร์ม' : 'สร้างฟาร์ม',
      bottom: FilledButton(
        onPressed: _saving ? null : _save,
        child: const Text('บันทึกฟาร์ม'),
      ),
      children: [
        const Text('ข้อมูลฟาร์ม', style: TS.h1),
        Text(editing ? 'แก้ไขข้อมูลฟาร์มเดิม' : 'สร้างฟาร์มใหม่', style: TS.small),
        const FieldLabel('ชื่อฟาร์ม'),
        TextField(
          key: const Key('farm-name'),
          controller: name,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.eco_outlined)),
        ),
        const FieldLabel('ผู้ดูแลพื้นที่'),
        PickerField(
          value: caretaker,
          icon: Icons.person_outline,
          options: _withExtra(_caretakerOptions, caretaker),
          onChanged: (v) => setState(() => caretaker = v),
        ),
        const FieldLabel('ตำแหน่ง / พื้นที่'),
        PickerField(
          value: location,
          icon: Icons.place_outlined,
          options: _withExtra(_locationOptions, location),
          onChanged: (v) => setState(() => location = v),
        ),
        const FieldLabel('คำอธิบาย (ไม่บังคับ)'),
        TextField(
          controller: note,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'เช่น พื้นที่นำร่อง 1 แปลง สำหรับทดสอบต้นแบบ'),
        ),
        const Gap(14),
        ToggleCard(
          title: 'รับการแจ้งเตือนของฟาร์มนี้',
          subtitle: 'จุดเฝ้าดู การซิงก์ และรอบสอบเทียบ',
          value: notify,
          onChanged: (v) => setState(() => notify = v),
        ),
        if (editing) ...[
          const FieldLabel('การจัดการข้อมูล'),
          DangerButton(label: 'ลบฟาร์ม…', onPressed: _delete),
          const Gap(8),
          const Text('การลบจะลบแปลงและประวัติการวัดทั้งหมด • ต้องยืนยันอีกครั้ง', style: TS.tiny, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- FLOW-04 Create plot

class CreatePlotScreen extends StatefulWidget {
  const CreatePlotScreen({super.key, this.farmId});
  final String? farmId;
  @override
  State<CreatePlotScreen> createState() => _CreatePlotScreenState();
}

class _CreatePlotScreenState extends State<CreatePlotScreen> {
  final name = TextEditingController();
  final note = TextEditingController();
  String crop = _cropOptions.first;
  String? farmId;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final farms = AppScope.read(context).farms;
    if (farms.isEmpty) return;
    final want = widget.farmId;
    farmId = farms.any((f) => f.id == want) ? want : farms.first.id;
  }

  @override
  void dispose() {
    name.dispose();
    note.dispose();
    super.dispose();
  }

  void _next() {
    final repo = AppScope.read(context);
    final n = name.text.trim();
    final fid = farmId;
    if (n.isEmpty) {
      toast(context, 'กรุณาใส่ชื่อแปลง');
      return;
    }
    if (fid == null) return;
    final c = crop;
    final nt = note.text.trim();
    go(
      context,
      DrawBoundaryScreen(
        plotName: n,
        initial: const [],
        onSave: (pts) => repo.addPlot(farmId: fid, name: n, crop: c, boundary: pts, note: nt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farms = AppScope.of(context).farms;
    final hasFarms = farms.isNotEmpty;
    final labels = _farmLabels(farms);
    final idx = farms.indexWhere((f) => f.id == farmId);
    final selected = idx < 0 ? 0 : idx;
    return ScreenScaffold(
      title: 'เพิ่มแปลง',
      step: 'ขั้นที่ 1/2',
      bottom: FilledButton.icon(
        onPressed: hasFarms ? _next : null,
        icon: const Icon(Icons.add),
        label: const Text('ไปยังการวาดขอบเขต'),
      ),
      children: [
        const Text('ข้อมูลแปลง', style: TS.h1),
        const Text('ตั้งชื่อ เลือกฟาร์ม และชนิดพืช • แก้ไขภายหลังได้', style: TS.small),
        if (!hasFarms)
          const InfoBox(
            tone: Tone.amber,
            title: 'ยังไม่มีฟาร์ม',
            body: 'สร้างฟาร์มก่อนจึงจะเพิ่มแปลงได้',
            margin: EdgeInsets.only(top: 16),
          )
        else ...[
          const FieldLabel('เลือกฟาร์ม'),
          PickerField(
            value: labels[selected],
            icon: Icons.agriculture_outlined,
            options: labels,
            onChanged: (v) => setState(() => farmId = farms[labels.indexOf(v)].id),
          ),
        ],
        const FieldLabel('ชื่อแปลง'),
        TextField(key: const Key('plot-name'), controller: name),
        const FieldLabel('ชนิดพืช'),
        PickerField(
          value: crop,
          icon: Icons.eco_outlined,
          options: _cropOptions,
          onChanged: (v) => setState(() => crop = v),
        ),
        const FieldLabel('หมายเหตุ (ไม่บังคับ)'),
        TextField(
          controller: note,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'เช่น พื้นที่ด้านตะวันตกของฟาร์ม'),
        ),
        const InfoBox(
          tone: Tone.green,
          icon: Icons.pentagon_outlined,
          title: 'ขั้นตอนถัดไป',
          body: 'วาดขอบเขตแปลงบนแผนที่ หรือใช้ตำแหน่งปัจจุบันช่วยเริ่มต้น',
          margin: EdgeInsets.only(top: 16),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- FLOW-05 Draw boundary

class DrawBoundaryScreen extends StatefulWidget {
  const DrawBoundaryScreen({super.key, this.plotName = 'แปลงใหม่', this.initial, this.onSave, this.successMessage});
  final String plotName;
  final List<Offset>? initial;
  final Future<void> Function(List<Offset> points)? onSave;
  final String? successMessage;
  @override
  State<DrawBoundaryScreen> createState() => _DrawBoundaryScreenState();
}

class _DrawBoundaryScreenState extends State<DrawBoundaryScreen> {
  late List<Offset> pts = List.of(widget.initial ?? Mock.polygon);
  bool _saving = false;

  Future<void> _use() async {
    final rai = Mock.areaRai(pts);
    final defaultMsg = 'บันทึก ${widget.plotName} (${rai.toStringAsFixed(1)} ไร่) แล้ว';
    final onSave = widget.onSave;
    if (onSave == null) {
      backToShell(context, defaultMsg);
      return;
    }
    setState(() => _saving = true);
    try {
      await onSave(List.of(pts));
      if (!mounted) return;
      final custom = widget.successMessage;
      if (custom == null) {
        backToShell(context, defaultMsg);
      } else {
        // Editing an existing plot: go back to the edit form rather than the shell.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(SnackBar(content: Text(custom)));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      toast(context, 'บันทึกไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rai = Mock.areaRai(pts);
    return ScreenScaffold(
      title: 'วาดขอบเขตแปลง',
      step: 'ขั้นที่ 2/2',
      bottom: FilledButton.icon(
        onPressed: pts.length < 3 || _saving ? null : _use,
        icon: const Icon(Icons.check),
        label: const Text('ใช้ขอบเขตนี้'),
      ),
      children: [
        PlotMap(
          polygon: pts,
          closed: pts.length >= 3,
          height: 360,
          user: const Offset(0.72, 0.62),
          markers: [for (final p in pts) PlotMarker(p, MarkerKind.vertex)],
          onTapMap: (o) => setState(() => pts.add(o)),
        ),
        const Gap(14),
        const Text('กำหนดขอบเขตแปลง', style: TS.h3),
        const Text('แตะบนแผนที่เพื่อเพิ่มจุด • ตรวจพื้นที่ก่อนบันทึก', style: TS.small),
        const Gap(10),
        Row(children: [
          Pill('${pts.length} จุดแล้ว', tone: Tone.blue),
          const Gap(8),
          Pill('พื้นที่ ${rai.toStringAsFixed(1)} ไร่', tone: Tone.grey),
        ]),
        const Gap(12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: pts.isEmpty ? null : () => setState(() => pts.removeLast()),
              icon: const Icon(Icons.undo),
              label: const Text('ย้อนกลับ'),
            ),
          ),
          const Gap(10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => pts.clear()),
              icon: const Icon(Icons.delete_outline),
              label: const Text('ล้างจุด'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
            ),
          ),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------- FLOW-11 Edit plot

class EditPlotScreen extends StatefulWidget {
  const EditPlotScreen({super.key, required this.plotId});
  final String plotId;
  @override
  State<EditPlotScreen> createState() => _EditPlotScreenState();
}

class _EditPlotScreenState extends State<EditPlotScreen> {
  final name = TextEditingController();
  String crop = _cropOptions.first;
  String farmId = '';
  bool visible = true;
  bool _loaded = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final p = AppScope.read(context).plot(widget.plotId);
    if (p == null) return;
    name.text = p.name;
    crop = p.crop;
    farmId = p.farmId;
    visible = !p.archived;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = AppScope.read(context);
    final n = name.text.trim();
    if (n.isEmpty) {
      toast(context, 'กรุณาใส่ชื่อแปลง');
      return;
    }
    setState(() => _saving = true);
    try {
      final existing = repo.plot(widget.plotId);
      if (existing == null) throw StateError('Plot not found: ${widget.plotId}');
      await repo.updatePlot(existing.copyWith(farmId: farmId, name: n, crop: crop, archived: !visible));
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('บันทึกการแก้ไขแล้ว')));
    } on ArgumentError {
      if (!mounted) return;
      setState(() => _saving = false);
      toast(context, 'กรุณาใส่ชื่อแปลง');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      toast(context, 'บันทึกไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  Future<void> _archive() async {
    final repo = AppScope.read(context);
    final ok = await confirm(context, 'เก็บแปลงถาวร?', 'แปลงจะถูกซ่อน แต่ข้อมูลเดิมยังอยู่ และกู้คืนได้');
    if (!ok || !mounted) return;
    try {
      await repo.setPlotArchived(widget.plotId, true);
      if (!mounted) return;
      backToShell(context, 'เก็บแปลงถาวรแล้ว');
    } catch (_) {
      if (!mounted) return;
      toast(context, 'บันทึกไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  Future<void> _delete() async {
    final repo = AppScope.read(context);
    final ok = await confirm(context, 'ลบแปลงถาวร?', 'ข้อมูลการวัดของแปลงนี้จะหายถาวร', ok: 'ลบถาวร', danger: true);
    if (!ok || !mounted) return;
    try {
      await repo.deletePlot(widget.plotId);
      if (!mounted) return;
      backToShell(context, 'ลบแปลงแล้ว');
    } catch (_) {
      if (!mounted) return;
      toast(context, 'บันทึกไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final plot = repo.plot(widget.plotId);
    if (plot == null) {
      return const ScreenScaffold(
        title: 'แก้ไขแปลง',
        children: [InfoBox(tone: Tone.grey, title: 'ไม่พบแปลงนี้')],
      );
    }
    final farms = repo.farms;
    final labels = _farmLabels(farms);
    final idx = farms.indexWhere((f) => f.id == farmId);
    return ScreenScaffold(
      title: 'แก้ไขแปลง',
      bottom: FilledButton(
        onPressed: _saving ? null : _save,
        child: const Text('บันทึกการแก้ไข'),
      ),
      children: [
        Text(plot.name, style: TS.h2),
        const Text('ปรับข้อมูลแปลง ชนิดพืช และขอบเขตพื้นที่', style: TS.small),
        const FieldLabel('ชื่อแปลง'),
        TextField(key: const Key('plot-name'), controller: name),
        const FieldLabel('ฟาร์มที่สังกัด'),
        PickerField(
          value: idx < 0 ? '' : labels[idx],
          icon: Icons.place_outlined,
          options: labels,
          onChanged: (v) => setState(() => farmId = farms[labels.indexOf(v)].id),
        ),
        const FieldLabel('ชนิดพืช'),
        PickerField(
          value: crop,
          icon: Icons.eco_outlined,
          options: _withExtra(_cropOptions, crop),
          onChanged: (v) => setState(() => crop = v),
        ),
        const Gap(14),
        AppCard(
          radius: 12,
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('พื้นที่และขอบเขต', style: TS.title),
                Text('${plot.rai.toStringAsFixed(1)} ไร่ • ${plot.boundary.length} จุดขอบเขต', style: TS.small),
              ]),
            ),
            TextButton(
              onPressed: () => go(
                context,
                DrawBoundaryScreen(
                  plotName: plot.name,
                  initial: plot.boundary,
                  // Re-read at save time so unsaved-form fields never clobber the stored plot.
                  onSave: (pts) async {
                    final latest = repo.plot(widget.plotId);
                    if (latest == null) throw StateError('Plot not found: ${widget.plotId}');
                    await repo.updatePlot(latest.copyWith(boundary: pts));
                  },
                  successMessage: 'บันทึกขอบเขตแล้ว',
                ),
              ),
              child: const Text('แก้ไขขอบเขต'),
            ),
          ]),
        ),
        const Gap(10),
        ToggleCard(
          title: 'แสดงแปลงนี้ในหน้าหลัก',
          subtitle: 'ปิด = เก็บถาวร ข้อมูลเดิมยังอยู่',
          value: visible,
          onChanged: (v) => setState(() => visible = v),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 20, bottom: 8),
          child: Text('การกระทำที่มีผลถาวร', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.red)),
        ),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _archive,
              icon: const Icon(Icons.archive_outlined, size: 18),
              label: const Text('เก็บถาวร'),
            ),
          ),
          const Gap(10),
          Expanded(child: DangerButton(label: 'ลบถาวร…', onPressed: _delete)),
        ]),
        const Gap(8),
        const Text('เก็บถาวร = ซ่อน ข้อมูลยังอยู่ • ลบ = หายถาวร', style: TS.tiny, textAlign: TextAlign.center),
      ],
    );
  }
}

/// Convenience to open the shell from anywhere (used by onboarding).
void openShell(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AppShell()), (r) => false);
}
