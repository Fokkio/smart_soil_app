import 'package:flutter/material.dart';

import '../data/mock_data.dart';
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
    final farms = Mock.farms.where((f) => f.name.contains(q)).toList();
    return ScreenScaffold(
      title: 'ฟาร์มของฉัน',
      bell: true,
      children: [
        TextField(
          onChanged: (v) => setState(() => q = v),
          decoration: const InputDecoration(hintText: 'ค้นหาฟาร์ม', prefixIcon: Icon(Icons.search)),
        ),
        const Gap(12),
        Row(children: [
          Pill('ทั้งหมด ${Mock.farms.length} ฟาร์ม', tone: Tone.grey),
          const Gap(8),
          const Pill('ข้อมูลพร้อมใช้', tone: Tone.blue),
        ]),
        const SectionHeader('เลือกฟาร์ม', action: 'เรียงล่าสุด', top: 16),
        for (final f in farms)
          AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            borderColor: f == Mock.farms.first ? AppColors.green : AppColors.line,
            borderWidth: f == Mock.farms.first ? 1.5 : 1,
            onTap: () => go(context, const PlotListScreen()),
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
                        Text(f.caretaker, style: TS.small),
                      ]),
                    ),
                    Pill(f.status == SoilStatus.normal ? 'ปกติ' : 'เฝ้าดู',
                        tone: toneFor(f.status), icon: f.status == SoilStatus.normal ? Icons.check : Icons.priority_high),
                  ],
                ),
                const Divider(height: 24),
                Row(children: [
                  Text('${f.plots} แปลง', style: TS.title),
                  const Spacer(),
                  const Text('ดูแปลง', style: TS.link),
                  const Icon(Icons.chevron_right, color: AppColors.green),
                ]),
              ],
            ),
          ),
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
}

// ---------------------------------------------------------------- MAIN-03 Plot list

class PlotListScreen extends StatefulWidget {
  const PlotListScreen({super.key});
  @override
  State<PlotListScreen> createState() => _PlotListScreenState();
}

class _PlotListScreenState extends State<PlotListScreen> {
  int view = 0;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'แปลงในฟาร์ม',
      bell: true,
      bottom: FilledButton.icon(
        onPressed: () => go(context, const CreatePlotScreen()),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มแปลงใหม่'),
      ),
      children: [
        AppCard(
          child: Row(children: [
            const IconCircle(Icons.agriculture_outlined),
            const Gap(12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(Mock.farmName, style: TS.h3),
                Text('3 แปลง • อัปเดตล่าสุดวันนี้ 14:32', style: TS.small),
              ]),
            ),
            const Pill('ปกติ', icon: Icons.check),
          ]),
        ),
        const Gap(12),
        Segmented(options: const ['การ์ด', 'ลิสต์'], selected: view, onChanged: (i) => setState(() => view = i)),
        SectionHeader('แปลงทั้งหมด', action: '+ เพิ่มแปลง', onAction: () => go(context, const CreatePlotScreen()), top: 16),
        for (final p in Mock.plots)
          view == 0
              ? AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  onTap: () => go(context, PlotDetailScreen(plot: p)),
                  child: Row(children: [
                    SizedBox(
                      width: 72,
                      child: PlotMap(
                        height: 72,
                        radius: 12,
                        markers: [PlotMarker(const Offset(0.5, 0.5), kindForStatus(p.status))],
                      ),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, style: TS.h3),
                        Text('พืช: ${p.crop}', style: TS.small),
                        const Gap(6),
                        Pill(p.status == SoilStatus.normal ? 'ดินโดยรวมปกติ' : 'ควรเฝ้าดู', tone: toneFor(p.status), small: true),
                        const Gap(4),
                        Text(p.lastChecked, style: TS.tiny),
                      ]),
                    ),
                    Text('${p.rai} ไร่', style: TS.title),
                  ]),
                )
              : ListRowCard(
                  icon: Icons.crop_square,
                  title: p.name,
                  subtitle: '${p.crop} • ${p.rai} ไร่ • ${p.lastChecked}',
                  tone: toneFor(p.status),
                  onTap: () => go(context, PlotDetailScreen(plot: p)),
                ),
      ],
    );
  }
}

// ---------------------------------------------------------------- FLOW-06 Plot detail

class PlotDetailScreen extends StatefulWidget {
  const PlotDetailScreen({super.key, this.plot = const Plot('แปลงมันสำปะหลัง A', 'มันสำปะหลัง', 12.4, SoilStatus.normal, '')});
  final Plot plot;
  @override
  State<PlotDetailScreen> createState() => _PlotDetailScreenState();
}

class _PlotDetailScreenState extends State<PlotDetailScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.plot;
    final tabBody = _tabBody(context);
    return ScreenScaffold(
      title: 'รายละเอียดแปลง',
      bell: true,
      actions: [
        IconButton(
          tooltip: 'แก้ไขแปลง',
          onPressed: () => go(context, EditPlotScreen(plot: p)),
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
                Text('${Mock.farmName} • ${p.rai} ไร่ • ${p.crop}', style: TS.small),
                const Gap(8),
                Pill(p.status == SoilStatus.normal ? 'ดินโดยรวมปกติ' : 'ควรเฝ้าดู', tone: toneFor(p.status), small: true),
              ]),
            ),
            const Text('วันนี้ 14:32', style: TS.small),
          ]),
        ),
        const Gap(12),
        const TwoCol(children: [
          ValueTile(label: 'จุดวัดล่าสุด', value: '14 จุด'),
          ValueTile(label: 'ความชื้นเฉลี่ย', value: '28%'),
          ValueTile(label: 'pH เฉลี่ย', value: '6.2'),
          ValueTile(label: 'จุดเฝ้าดู', value: '2 จุด'),
        ]),
        const Gap(4),
        Segmented(options: const ['ภาพรวม', 'แผนที่', 'AI', 'ประวัติ'], selected: tab, onChanged: (i) => setState(() => tab = i)),
        const Gap(14),
        ...tabBody,
      ],
    );
  }

  List<Widget> _tabBody(BuildContext context) {
    return switch (tab) {
          0 => _overview(context),
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
          _ => [
              for (final h in Mock.history)
                ListRowCard(
                  icon: Icons.history,
                  title: '${h.date} ${h.time}',
                  subtitle: h.summary,
                  onTap: () => go(context, const CompareScreen()),
                ),
            ],
        };
  }

  List<Widget> _overview(BuildContext context) => [
        AppCard(
          onTap: () => setState(() => tab = 1),
          child: Row(children: [
            SizedBox(width: 120, child: PlotMap(markers: soilMarkers(), height: 80, radius: 12)),
            const Gap(14),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ค่าส่วนใหญ่ปกติ', style: TS.h3),
                Gap(4),
                Text('! 2 จุดควรตรวจสอบเพิ่มเติม', style: TS.small),
                Gap(6),
                Text('ดู 2 จุดบนแผนที่ →', style: TS.link),
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
  const CreateFarmScreen({super.key, this.editing = false});
  final bool editing;
  @override
  State<CreateFarmScreen> createState() => _CreateFarmScreenState();
}

class _CreateFarmScreenState extends State<CreateFarmScreen> {
  final name = TextEditingController(text: Mock.farmName);
  String caretaker = 'เจ้าหน้าที่ฟาร์ม (ผู้ดูแลหลัก)';
  String location = 'อ.กันทรวิชัย จ.มหาสารคาม';
  bool notify = true;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'สร้าง / แก้ไขฟาร์ม',
      bottom: FilledButton(
        onPressed: () => backToShell(context, 'บันทึกฟาร์ม "${name.text}" แล้ว'),
        child: const Text('บันทึกฟาร์ม'),
      ),
      children: [
        const Align(alignment: Alignment.centerLeft, child: Pill('ใช้ฟอร์มเดียวกัน', tone: Tone.blue, small: true)),
        const Gap(8),
        const Text('ข้อมูลฟาร์ม', style: TS.h1),
        const Text('ใช้สร้างฟาร์มใหม่ หรือแก้ไขข้อมูลฟาร์มเดิม', style: TS.small),
        const FieldLabel('ชื่อฟาร์ม'),
        TextField(controller: name, decoration: const InputDecoration(prefixIcon: Icon(Icons.eco_outlined))),
        const FieldLabel('ผู้ดูแลพื้นที่'),
        PickerField(
          value: caretaker,
          icon: Icons.person_outline,
          options: const ['เจ้าหน้าที่ฟาร์ม (ผู้ดูแลหลัก)', 'ทีมโครงการ', 'นักวิจัย / นิสิต'],
          onChanged: (v) => setState(() => caretaker = v),
        ),
        const FieldLabel('ตำแหน่ง / พื้นที่'),
        PickerField(
          value: location,
          icon: Icons.place_outlined,
          options: const ['อ.กันทรวิชัย จ.มหาสารคาม', 'อ.เมือง จ.มหาสารคาม', 'ใช้ตำแหน่งปัจจุบัน'],
          onChanged: (v) => setState(() => location = v),
        ),
        const FieldLabel('คำอธิบาย (ไม่บังคับ)'),
        const TextField(maxLines: 2, decoration: InputDecoration(hintText: 'เช่น พื้นที่นำร่อง 1 แปลง สำหรับทดสอบต้นแบบ')),
        const Gap(14),
        ToggleCard(
          title: 'รับการแจ้งเตือนของฟาร์มนี้',
          subtitle: 'จุดเฝ้าดู การซิงก์ และรอบสอบเทียบ',
          value: notify,
          onChanged: (v) => setState(() => notify = v),
        ),
        const FieldLabel('การจัดการข้อมูล'),
        DangerButton(
          label: 'ลบฟาร์ม…',
          onPressed: () async {
            final ok = await confirm(context, 'ลบฟาร์มนี้?', 'แปลงและประวัติการวัดทั้งหมดจะถูกลบถาวร', ok: 'ลบถาวร', danger: true);
            if (ok && context.mounted) backToShell(context, 'ลบฟาร์มแล้ว (ตัวอย่าง)');
          },
        ),
        const Gap(8),
        const Text('การลบจะลบแปลงและประวัติการวัดทั้งหมด • ต้องยืนยันอีกครั้ง', style: TS.tiny, textAlign: TextAlign.center),
      ],
    );
  }
}

// ---------------------------------------------------------------- FLOW-04 Create plot

class CreatePlotScreen extends StatefulWidget {
  const CreatePlotScreen({super.key});
  @override
  State<CreatePlotScreen> createState() => _CreatePlotScreenState();
}

class _CreatePlotScreenState extends State<CreatePlotScreen> {
  String farm = Mock.farmName;
  String crop = 'มันสำปะหลัง';
  final name = TextEditingController(text: 'แปลงมันสำปะหลัง D');

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'เพิ่มแปลง',
      step: 'ขั้นที่ 1/2',
      bottom: FilledButton.icon(
        onPressed: () => go(context, DrawBoundaryScreen(plotName: name.text)),
        icon: const Icon(Icons.add),
        label: const Text('ไปยังการวาดขอบเขต'),
      ),
      children: [
        const Text('ข้อมูลแปลง', style: TS.h1),
        const Text('ตั้งชื่อ เลือกฟาร์ม และชนิดพืช • แก้ไขภายหลังได้', style: TS.small),
        const FieldLabel('เลือกฟาร์ม'),
        PickerField(
          value: farm,
          icon: Icons.agriculture_outlined,
          options: const [Mock.farmName, 'จุดสอบเทียบ (แล็บ)'],
          onChanged: (v) => setState(() => farm = v),
        ),
        const FieldLabel('ชื่อแปลง'),
        TextField(controller: name),
        const FieldLabel('ชนิดพืช'),
        PickerField(
          value: crop,
          icon: Icons.eco_outlined,
          options: const ['มันสำปะหลัง', 'ข้าว', 'อ้อย', 'ข้าวโพด', 'อื่น ๆ'],
          onChanged: (v) => setState(() => crop = v),
        ),
        const FieldLabel('หมายเหตุ (ไม่บังคับ)'),
        const TextField(maxLines: 2, decoration: InputDecoration(hintText: 'เช่น พื้นที่ด้านตะวันตกของฟาร์ม')),
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
  const DrawBoundaryScreen({super.key, this.plotName = 'แปลงใหม่'});
  final String plotName;
  @override
  State<DrawBoundaryScreen> createState() => _DrawBoundaryScreenState();
}

class _DrawBoundaryScreenState extends State<DrawBoundaryScreen> {
  late List<Offset> pts = List.of(Mock.polygon);

  @override
  Widget build(BuildContext context) {
    final rai = Mock.areaRai(pts);
    return ScreenScaffold(
      title: 'วาดขอบเขตแปลง',
      step: 'ขั้นที่ 2/2',
      bottom: FilledButton.icon(
        onPressed: pts.length < 3 ? null : () => backToShell(context, 'บันทึก ${widget.plotName} (${rai.toStringAsFixed(1)} ไร่) แล้ว'),
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
  const EditPlotScreen({super.key, required this.plot});
  final Plot plot;
  @override
  State<EditPlotScreen> createState() => _EditPlotScreenState();
}

class _EditPlotScreenState extends State<EditPlotScreen> {
  late final name = TextEditingController(text: widget.plot.name);
  late String crop = widget.plot.crop;
  bool visible = true;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'แก้ไขแปลง',
      bottom: FilledButton(
        onPressed: () {
          Navigator.pop(context);
          toast(context, 'บันทึกการแก้ไขแล้ว');
        },
        child: const Text('บันทึกการแก้ไข'),
      ),
      children: [
        Text(widget.plot.name, style: TS.h2),
        const Text('ปรับข้อมูลแปลง ชนิดพืช และขอบเขตพื้นที่', style: TS.small),
        const FieldLabel('ชื่อแปลง'),
        TextField(controller: name),
        const FieldLabel('ฟาร์มที่สังกัด'),
        PickerField(value: Mock.farmName, icon: Icons.place_outlined, options: const [Mock.farmName], onChanged: (_) {}),
        const FieldLabel('ชนิดพืช'),
        PickerField(
          value: crop,
          icon: Icons.eco_outlined,
          options: const ['มันสำปะหลัง', 'ข้าว', 'อ้อย', 'ข้าวโพด'],
          onChanged: (v) => setState(() => crop = v),
        ),
        const Gap(14),
        AppCard(
          radius: 12,
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('พื้นที่และขอบเขต', style: TS.title),
                Text('${widget.plot.rai} ไร่ • 6 จุดขอบเขต', style: TS.small),
              ]),
            ),
            TextButton(onPressed: () => go(context, DrawBoundaryScreen(plotName: name.text)), child: const Text('แก้ไขขอบเขต')),
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
              onPressed: () async {
                final ok = await confirm(context, 'เก็บแปลงถาวร?', 'แปลงจะถูกซ่อน แต่ข้อมูลเดิมยังอยู่ และกู้คืนได้');
                if (ok && context.mounted) backToShell(context, 'เก็บแปลงถาวรแล้ว');
              },
              icon: const Icon(Icons.archive_outlined, size: 18),
              label: const Text('เก็บถาวร'),
            ),
          ),
          const Gap(10),
          Expanded(
            child: DangerButton(
              label: 'ลบถาวร…',
              onPressed: () async {
                final ok = await confirm(context, 'ลบแปลงถาวร?', 'ข้อมูลการวัดของแปลงนี้จะหายถาวร', ok: 'ลบถาวร', danger: true);
                if (ok && context.mounted) backToShell(context, 'ลบแปลงแล้ว (ตัวอย่าง)');
              },
            ),
          ),
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
