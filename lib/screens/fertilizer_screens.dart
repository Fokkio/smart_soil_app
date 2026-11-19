import 'package:flutter/material.dart';

import '../data/app_scope.dart';
import '../data/farm_repository.dart';
import '../data/fertilizer.dart';
import '../data/fertilizer_calc.dart';
import '../data/seed.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _ruleCropOptions = ['มันสำปะหลัง', 'ข้าว', 'อ้อย', 'ข้าวโพด', 'อื่น ๆ'];

const _fieldKeys = ['lowBelow', 'highFrom', 'rateLow', 'rateMedium', 'rateHigh'];
const _fieldLabels = {
  'lowBelow': 'ต่ำกว่า (mg/kg)',
  'highFrom': 'สูงตั้งแต่ (mg/kg)',
  'rateLow': 'อัตรา ระดับต่ำ (กก./ไร่)',
  'rateMedium': 'อัตรา ระดับปานกลาง (กก./ไร่)',
  'rateHigh': 'อัตรา ระดับสูง (กก./ไร่)',
};

const _numKeyboard = TextInputType.numberWithOptions(decimal: true);

double? _parseNum(String text) => double.tryParse(text.trim().replaceAll(',', ''));

String _fmtNum(double v) {
  final s = v.toString();
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String _statusText(CropRuleSet s, DateTime now) =>
    s.isConfirmed ? 'ยืนยันโดย ${s.confirmedBy} • ${formatWhen(s.confirmedAt!, now)}' : 'ยังไม่ผ่านการยืนยัน';

/// Lists crop rule tables (expert-entered) and holds the fertilizer prices form.
class FertilizerRulesScreen extends StatefulWidget {
  const FertilizerRulesScreen({super.key});
  @override
  State<FertilizerRulesScreen> createState() => _FertilizerRulesScreenState();
}

class _FertilizerRulesScreenState extends State<FertilizerRulesScreen> {
  final urea = TextEditingController();
  final tsp = TextEditingController();
  final mop = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final p = AppScope.read(context).prices;
    String show(double v) => v == 0 ? '' : _fmtNum(v);
    urea.text = show(p.urea);
    tsp.text = show(p.tsp);
    mop.text = show(p.mop);
  }

  @override
  void dispose() {
    urea.dispose();
    tsp.dispose();
    mop.dispose();
    super.dispose();
  }

  /// Blank = 0; null when the text is not a number.
  double? _price(TextEditingController c) => c.text.trim().isEmpty ? 0 : _parseNum(c.text);

  Future<void> _savePrices() async {
    final repo = AppScope.read(context);
    final u = _price(urea), t = _price(tsp), m = _price(mop);
    if (u == null || t == null || m == null) {
      toast(context, 'กรอกราคาเป็นตัวเลข');
      return;
    }
    setState(() => _saving = true);
    try {
      await repo.setPrices(FertilizerPrices(urea: u, tsp: t, mop: m));
      if (!mounted) return;
      setState(() => _saving = false);
      toast(context, 'บันทึกราคาแล้ว');
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      toast(context, '${e.message}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      toast(context, 'บันทึกไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  Widget _priceField(String key, String label, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          key: Key(key),
          controller: c,
          keyboardType: _numKeyboard,
          decoration: InputDecoration(labelText: label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final sets = repo.ruleSets;
    final now = repo.clock();
    return ScreenScaffold(
      title: 'ตารางอัตราปุ๋ย',
      children: [
        const InfoBox(
          tone: Tone.amber,
          title: 'ตัวเลขทุกค่าต้องมาจากแหล่งอ้างอิงและผู้เชี่ยวชาญ',
          body: 'แอปไม่มีค่าอัตราปุ๋ยในตัว ผู้เชี่ยวชาญหรือทีมงานต้องกรอกและยืนยันตารางก่อนใช้งาน',
        ),
        const SectionHeader('ตารางของแต่ละพืช'),
        if (sets.isEmpty)
          const InfoBox(tone: Tone.grey, title: 'ยังไม่มีตารางอัตราปุ๋ย', margin: EdgeInsets.only(bottom: 10))
        else
          for (final s in sets)
            ListRowCard(
              icon: Icons.grass,
              title: s.crop,
              subtitle: _statusText(s, now),
              tone: s.isConfirmed ? Tone.green : Tone.amber,
              onTap: () => go(context, RuleSetEditScreen(crop: s.crop)),
            ),
        OutlinedButton.icon(
          onPressed: () => go(context, const RuleSetEditScreen()),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('เพิ่มตารางพืช'),
        ),
        const SectionHeader('ราคาปุ๋ย (บาท/กก.)'),
        _priceField('price-urea', 'ยูเรีย (46-0-0)', urea),
        _priceField('price-tsp', 'ทริปเปิลซูเปอร์ฟอสเฟต (0-46-0)', tsp),
        _priceField('price-mop', 'โพแทสเซียมคลอไรด์ (0-0-60)', mop),
        FilledButton(
          onPressed: _saving ? null : _savePrices,
          child: const Text('บันทึกราคา'),
        ),
      ],
    );
  }
}

/// Add (crop == null) or edit one crop's rule table.
class RuleSetEditScreen extends StatefulWidget {
  const RuleSetEditScreen({super.key, this.crop});
  final String? crop;
  @override
  State<RuleSetEditScreen> createState() => _RuleSetEditScreenState();
}

class _RuleSetEditScreenState extends State<RuleSetEditScreen> {
  final source = TextEditingController();
  final Map<String, TextEditingController> _c = {
    for (final n in Nutrient.values)
      for (final f in _fieldKeys) '${n.name}-$f': TextEditingController(),
  };
  final Map<Nutrient, bool> _on = {for (final n in Nutrient.values) n: true};
  String? crop;
  bool _loaded = false;
  bool _saving = false;
  bool _dirty = false;

  void _markDirty() => _dirty = true;

  @override
  void initState() {
    super.initState();
    source.addListener(_markDirty);
    for (final c in _c.values) {
      c.addListener(_markDirty);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final repo = AppScope.read(context);
    final existing = widget.crop == null ? null : repo.ruleSetFor(widget.crop!);
    if (existing != null) {
      crop = existing.crop;
      source.text = existing.source;
      for (final n in Nutrient.values) {
        final r = existing.ruleFor(n);
        _on[n] = r != null;
        if (r == null) continue;
        final vals = [r.lowBelow, r.highFrom, r.rateLow, r.rateMedium, r.rateHigh];
        for (var i = 0; i < _fieldKeys.length; i++) {
          _c['${n.name}-${_fieldKeys[i]}']!.text = _fmtNum(vals[i]);
        }
      }
    } else if (widget.crop == null) {
      final avail = _available(repo);
      crop = avail.isEmpty ? null : avail.first;
    }
    _dirty = false;
  }

  @override
  void dispose() {
    source.dispose();
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _available(FarmRepository repo) =>
      [for (final o in _ruleCropOptions) if (repo.ruleSetFor(o) == null) o];

  Future<void> _save() async {
    final repo = AppScope.read(context);
    final cropName = crop;
    if (cropName == null) return;
    final rules = <NutrientRule>[];
    for (final n in Nutrient.values) {
      if (!_on[n]!) continue;
      final v = [for (final f in _fieldKeys) _parseNum(_c['${n.name}-$f']!.text)];
      if (v.any((x) => x == null)) {
        toast(context, 'กรอกตัวเลขให้ครบทุกช่อง');
        return;
      }
      rules.add(NutrientRule(
        nutrient: n,
        lowBelow: v[0]!,
        highFrom: v[1]!,
        rateLow: v[2]!,
        rateMedium: v[3]!,
        rateHigh: v[4]!,
      ));
    }
    setState(() => _saving = true);
    try {
      await repo.saveRuleSet(CropRuleSet(crop: cropName, source: source.text, rules: rules, confirmedBy: ''));
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('บันทึกตารางแล้ว (รอผู้เชี่ยวชาญยืนยัน)')));
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      toast(context, '${e.message}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      toast(context, 'บันทึกไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  Future<void> _confirmByExpert() async {
    if (_dirty) {
      toast(context, 'บันทึกตารางก่อนยืนยัน');
      return;
    }
    final repo = AppScope.read(context);
    final cropName = crop;
    if (cropName == null) return;
    final name = await showDialog<String>(context: context, builder: (_) => const _ExpertNameDialog());
    if (name == null || !mounted) return;
    try {
      await repo.confirmRuleSet(cropName, name);
      if (!mounted) return;
      toast(context, 'ยืนยันตารางแล้ว');
    } on ArgumentError catch (e) {
      if (!mounted) return;
      toast(context, '${e.message}');
    } catch (_) {
      if (!mounted) return;
      toast(context, 'บันทึกไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  Future<void> _delete() async {
    final repo = AppScope.read(context);
    final cropName = crop;
    if (cropName == null) return;
    final ok = await confirm(context, 'ลบตารางของ $cropName?', 'ต้องกรอกและให้ผู้เชี่ยวชาญยืนยันใหม่ถ้าจะใช้อีก', ok: 'ลบ', danger: true);
    if (!ok || !mounted) return;
    try {
      await repo.deleteRuleSet(cropName);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('ลบตารางแล้ว')));
    } catch (_) {
      if (!mounted) return;
      toast(context, 'บันทึกไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  Widget _nutrientSection(Nutrient n) {
    final label = nutrientLabel(n);
    final soil = soilLabel(n);
    // Thresholds compare the soil reading (element, mg/kg); rates are fertilizer (oxide, kg/rai).
    String fieldLabel(String f) =>
        (f == 'lowBelow' || f == 'highFrom') ? '$soil ในดิน: ${_fieldLabels[f]}' : '$label: ${_fieldLabels[f]}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Gap(14),
        ToggleCard(
          title: soil == label ? 'ใช้ธาตุ $label' : 'ใช้ธาตุ $soil (อัตราเป็น $label)',
          subtitle: 'ปิดถ้าตารางไม่ได้กำหนดธาตุนี้',
          value: _on[n]!,
          onChanged: (v) => setState(() {
            _on[n] = v;
            _dirty = true;
          }),
        ),
        if (_on[n]!)
          for (final f in _fieldKeys)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextField(
                key: Key('${n.name}-$f'),
                controller: _c['${n.name}-$f'],
                keyboardType: _numKeyboard,
                decoration: InputDecoration(labelText: fieldLabel(f)),
              ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final editing = widget.crop != null;
    final existing = editing ? repo.ruleSetFor(widget.crop!) : null;
    final title = editing ? 'แก้ไขตารางอัตราปุ๋ย' : 'เพิ่มตารางพืช';
    if (editing && existing == null) {
      return ScreenScaffold(
        title: title,
        children: const [InfoBox(tone: Tone.grey, title: 'ไม่พบตารางของพืชนี้')],
      );
    }
    final avail = editing ? const <String>[] : _available(repo);
    if (!editing && avail.isEmpty) {
      return ScreenScaffold(
        title: title,
        bottom: const FilledButton(onPressed: null, child: Text('บันทึกตาราง')),
        children: const [InfoBox(tone: Tone.grey, title: 'มีตารางครบทุกชนิดพืชแล้ว')],
      );
    }
    return ScreenScaffold(
      title: title,
      bottom: BottomActions(children: [
        FilledButton(onPressed: _saving ? null : _save, child: const Text('บันทึกตาราง')),
        if (editing) ...[
          OutlinedButton(onPressed: _confirmByExpert, child: const Text('ยืนยันตาราง (ผู้เชี่ยวชาญ)')),
          DangerButton(label: 'ลบตาราง', onPressed: _delete),
        ],
      ]),
      children: [
        if (existing != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Pill(
              _statusText(existing, repo.clock()),
              tone: existing.isConfirmed ? Tone.green : Tone.amber,
            ),
          ),
        const FieldLabel('ชนิดพืช'),
        if (editing)
          Text(crop ?? '', style: TS.h3)
        else
          PickerField(
            value: crop ?? avail.first,
            icon: Icons.eco_outlined,
            options: avail,
            onChanged: (v) => setState(() => crop = v),
          ),
        const FieldLabel('แหล่งอ้างอิง'),
        TextField(key: const Key('rule-source'), controller: source),
        for (final n in Nutrient.values) _nutrientSection(n),
      ],
    );
  }
}

class _ExpertNameDialog extends StatefulWidget {
  const _ExpertNameDialog();
  @override
  State<_ExpertNameDialog> createState() => _ExpertNameDialogState();
}

class _ExpertNameDialogState extends State<_ExpertNameDialog> {
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ยืนยันตารางโดยผู้เชี่ยวชาญ', style: TS.h3),
      content: TextField(
        key: const Key('expert-name'),
        controller: ctrl,
        decoration: const InputDecoration(labelText: 'ชื่อผู้เชี่ยวชาญ'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
        TextButton(
          onPressed: () {
            final n = ctrl.text.trim();
            if (n.isEmpty) {
              toast(context, 'กรุณาใส่ชื่อผู้เชี่ยวชาญ');
              return;
            }
            Navigator.pop(context, n);
          },
          child: const Text('ยืนยัน'),
        ),
      ],
    );
  }
}

Tone _levelTone(NutrientLevel l) => switch (l) {
      NutrientLevel.low => Tone.amber,
      NutrientLevel.medium => Tone.green,
      NutrientLevel.high => Tone.blue,
    };

/// Straight-fertilizer plan for one plot, from its latest round and the expert rule table.
class FertilizerScreen extends StatelessWidget {
  const FertilizerScreen({super.key, this.plotId});
  final String? plotId;

  @override
  Widget build(BuildContext context) {
    const title = 'ปุ๋ยที่ควรใส่';
    final repo = AppScope.of(context);
    final p = repo.plot(plotId ?? SeedIds.plotA);
    const warning = InfoBox(
      tone: Tone.amber,
      title: 'N-P-K เป็นค่าประมาณ ยังไม่สอบเทียบ',
      body: 'ใช้ประกอบการตัดสินใจเท่านั้น',
    );
    if (p == null) {
      return const ScreenScaffold(title: title, children: [warning, InfoBox(tone: Tone.grey, title: 'ไม่พบแปลงนี้')]);
    }
    final now = repo.clock();
    final round = repo.latestRound(p.id);
    final rules = repo.ruleSetFor(p.crop);
    final r = calculateFertilizer(rai: p.rai, round: round, rules: rules, prices: repo.prices);
    return ScreenScaffold(
      title: title,
      children: [
        warning,
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: TS.h2),
            Text('${p.crop} • ${p.rai.toStringAsFixed(1)} ไร่ (พื้นที่โดยประมาณ)', style: TS.small),
            if (round != null) Text('ผลวัด ${formatWhen(round.takenAt, now)}', style: TS.small),
          ]),
        ),
        const Gap(12),
        if (r.issue == FertilizerIssue.noRound)
          const InfoBox(tone: Tone.grey, title: 'ยังไม่มีผลการวัด', body: 'วัดดินในแปลงนี้ก่อนจึงจะคำนวณปุ๋ยได้')
        else if (r.issue == FertilizerIssue.noRules) ...[
          InfoBox(
            tone: Tone.grey,
            title: 'ยังไม่มีตารางอัตราปุ๋ยของ${p.crop}',
            body: 'ผู้เชี่ยวชาญต้องกรอกและยืนยันตารางก่อน',
            margin: const EdgeInsets.only(bottom: 10),
          ),
          OutlinedButton(
            onPressed: () => go(context, const FertilizerRulesScreen()),
            child: const Text('ไปที่ตารางอัตราปุ๋ย'),
          ),
        ] else ..._plan(rules!, r, now),
      ],
    );
  }

  List<Widget> _plan(CropRuleSet rules, FertilizerResult r, DateTime now) => [
        if (r.confirmed)
          Align(
            alignment: Alignment.centerLeft,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Pill('ยืนยันโดย ${rules.confirmedBy}', tone: Tone.green),
              if (rules.confirmedAt != null) ...[
                const Gap(8),
                Text(formatWhen(rules.confirmedAt!, now), style: TS.small),
              ],
            ]),
          )
        else
          const InfoBox(tone: Tone.red, title: 'ตารางอัตราปุ๋ยยังไม่ผ่านการยืนยันจากผู้เชี่ยวชาญ'),
        const Gap(6),
        Text('แหล่งอ้างอิง: ${r.source.isEmpty ? '—' : r.source}', style: TS.small),
        const SectionHeader('ธาตุอาหารในดิน'),
        for (final n in r.nutrients)
          AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${soilLabel(n.nutrient)} ${n.measured.toStringAsFixed(0)} mg/kg', style: TS.h3),
                  const Gap(4),
                  Align(alignment: Alignment.centerLeft, child: Pill(levelLabel(n.level), tone: _levelTone(n.level), small: true)),
                ]),
              ),
              Text('${n.ratePerRai.toStringAsFixed(1)} กก. ${nutrientLabel(n.nutrient)}/ไร่', style: TS.small),
            ]),
          ),
        const SectionHeader('ปุ๋ยเดี่ยวที่ควรใส่'),
        if (r.products.isEmpty)
          const InfoBox(tone: Tone.grey, title: 'ไม่ต้องใส่ปุ๋ยเดี่ยวตามตารางนี้')
        else
          for (final pr in r.products)
            AppCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pr.product.name, style: TS.h3),
                    Text(
                      '${pr.kgPerRai.toStringAsFixed(1)} กก./ไร่ • รวม ${pr.totalKg.toStringAsFixed(1)} กก.',
                      style: TS.small,
                    ),
                  ]),
                ),
                Text(pr.cost == null ? '—' : '${pr.cost!.toStringAsFixed(0)} บาท', style: TS.small),
              ]),
            ),
        const Gap(4),
        Text(
          r.totalCost == null ? 'ต้นทุนรวม —' : 'ต้นทุนรวม ${r.totalCost!.toStringAsFixed(0)} บาท',
          style: TS.h3,
        ),
      ];
}
