import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'measure_screens.dart';
import 'onboarding_screens.dart';

// ---------------------------------------------------------------- MAIN-09 Device

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});
  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  bool remember = true;
  bool connected = true;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'อุปกรณ์ของฉัน',
      children: [
        AppCard(
          child: Row(children: [
            const IconCircle(Icons.sensors, size: 48),
            const Gap(12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ตัวอ่านค่าดิน #1', style: TS.h3),
                Text('แบต 78% • สอบเทียบล่าสุด 19 พ.ย.', style: TS.small),
              ]),
            ),
            Pill(connected ? 'เชื่อมต่ออยู่' : 'ตัดการเชื่อมต่อ', tone: connected ? Tone.green : Tone.grey, small: true),
          ]),
        ),
        const SectionHeader('ช่องทางเชื่อมต่อ'),
        ListRowCard(
          icon: Icons.bluetooth,
          title: 'Bluetooth',
          subtitle: 'แนะนำ • พบอุปกรณ์ใกล้คุณ',
          trailing: Pill(connected ? 'เชื่อมอยู่' : 'เชื่อมต่อ', icon: connected ? Icons.check : null, small: true),
          onTap: () => setState(() => connected = true),
        ),
        const ListRowCard(icon: Icons.wifi, tone: Tone.blue, title: 'Wi-Fi', subtitle: 'เชื่อมผ่านเครือข่ายเดียวกัน', trailing: Pill('ทางเลือก', tone: Tone.blue, small: true)),
        const ListRowCard(icon: Icons.usb, tone: Tone.grey, title: 'USB (Android OTG)', subtitle: 'ยังไม่ได้เชื่อมต่อสาย', trailing: Pill('ทางเลือก', tone: Tone.grey, small: true)),
        const Gap(4),
        ToggleCard(
          title: 'จำอุปกรณ์ที่เคยเชื่อมต่อ',
          subtitle: 'เชื่อมต่ออัตโนมัติในครั้งถัดไป',
          value: remember,
          onChanged: (v) => setState(() => remember = v),
        ),
        const Gap(12),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => go(context, const MeasureConnectScreen()), child: const Text('เพิ่มอุปกรณ์ใหม่'))),
          const Gap(10),
          Expanded(
            child: OutlinedButton(
              onPressed: () => go(context, const MaintenanceScreen()),
              child: const Text('บำรุงรักษา'),
            ),
          ),
        ]),
        const Gap(10),
        DangerButton(
          label: 'ตัดการเชื่อมต่อ',
          icon: Icons.link_off,
          onPressed: () => setState(() => connected = false),
        ),
        const Gap(6),
        const Text('ใช้เมื่อเปลี่ยนอุปกรณ์ หรือเมื่อการเชื่อมต่อมีปัญหา', style: TS.tiny, textAlign: TextAlign.center),
      ],
    );
  }
}

// ---------------------------------------------------------------- NEW-06 Maintenance

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'บำรุงรักษาอุปกรณ์',
      bottom: BottomActions(children: [
        FilledButton(onPressed: () => go(context, const CalibrationScreen()), child: const Text('บันทึกการสอบเทียบ')),
        OutlinedButton(onPressed: () => toast(context, 'บันทึกการเปลี่ยนอะไหล่แล้ว (ตัวอย่าง)'), child: const Text('บันทึกการเปลี่ยนอะไหล่')),
      ]),
      children: [
        AppCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            IconCircle(Icons.build_outlined, size: 44),
            Gap(12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ตัวอ่านค่าดิน #1', style: TS.h3),
                Text('หัววัด 7 พารามิเตอร์ • RS485/Modbus', style: TS.small),
                Gap(8),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  Pill('แบต 78%', small: true),
                  Pill('เชื่อมต่อผ่าน Bluetooth', tone: Tone.blue, small: true),
                ]),
              ]),
            ),
          ]),
        ),
        const Gap(12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('การสอบเทียบ', style: TS.title),
            KVRow('ล่าสุด', '19 พ.ย. 69 (บัฟเฟอร์ pH 4 / 7)'),
            KVRow('ครั้งถัดไป', '19 ธ.ค. 69 • อีก 30 วัน', valueColor: AppColors.amber, divider: false),
          ]),
        ),
        const Gap(12),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('คุณภาพการอ่านข้อมูล (7 วัน)', style: TS.title),
            Gap(6),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('98.6%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.green)),
              Spacer(),
              Text('เป้าหมาย ≥ 95%', style: TS.label),
            ]),
            Gap(8),
            Bar(0.986),
            Gap(8),
            Text('อ่าน 1,412 ครั้ง • ล้มเหลว 20 ครั้ง (checksum ไม่ผ่าน)', style: TS.tiny),
          ]),
        ),
        const SectionHeader('บันทึกค่าผิดปกติ'),
        const _LogRow(color: AppColors.amber, title: 'EC อ่านได้ 0.0 ติดกัน 3 ครั้ง', sub: '18 พ.ย. 10:12 • ทำความสะอาดหัววัดแล้ว'),
        const _LogRow(color: AppColors.red, title: 'แบตเตอรี่ต่ำกว่า 20%', sub: '15 พ.ย. 16:40 • เปลี่ยนแบตเตอรี่สำรอง'),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.color, required this.title, required this.sub});
  final Color color;
  final String title;
  final String sub;
  @override
  Widget build(BuildContext context) => AppCard(
        margin: const EdgeInsets.only(bottom: 8),
        radius: 12,
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
          const Gap(12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TS.title),
              Text(sub, style: TS.tiny),
            ]),
          ),
        ]),
      );
}

// ---------------------------------------------------------------- NEW-05 Calibration report

class CalibrationScreen extends StatelessWidget {
  const CalibrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('pH', 'MAE 0.18 • Bias +0.12 • เกณฑ์ ±0.3', true),
      ('EC (mS/cm)', 'MAE 0.12 • Bias +0.08 • เกณฑ์ ±0.2', true),
      ('ความชื้น (%)', 'MAE 2.6 • Bias −2.4 • เกณฑ์ ±2.0', false),
      ('อุณหภูมิ (°C)', 'MAE 0.3 • Bias +0.1 • เกณฑ์ ±0.5', true),
    ];
    return ScreenScaffold(
      title: 'ผลสอบเทียบหัววัด',
      bottom: BottomActions(children: [
        FilledButton(
          onPressed: () => toast(context, 'บันทึกค่าชดเชยความชื้น +2.4% แล้ว (ตัวอย่าง)'),
          child: const Text('บันทึกค่าชดเชยความชื้น (offset)'),
        ),
        OutlinedButton(
          onPressed: () => go(context, const ExportScreen()),
          child: const Text('ส่งออกตารางความคลาดเคลื่อน'),
        ),
      ]),
      children: [
        AppCard(
          child: Row(children: const [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('เทียบกับค่าอ้างอิง 8 จุด', style: TS.h3),
                Text('รอบล่าสุด 19 พ.ย. 69 • หัววัด #1', style: TS.small),
              ]),
            ),
            Pill('ผ่าน 3/4'),
          ]),
        ),
        const Gap(12),
        for (final it in items)
          AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            radius: 14,
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it.$1, style: TS.h3),
                  const Gap(2),
                  Text(it.$2, style: TS.small),
                ]),
              ),
              Pill(it.$3 ? 'ผ่าน' : 'ต้องปรับค่า', tone: it.$3 ? Tone.green : Tone.amber),
            ]),
          ),
        AppCard(
          color: AppColors.grey,
          borderColor: Colors.transparent,
          radius: 14,
          child: Row(children: const [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('N / P / K', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.muted)),
                Text('รอผลแล็บ • ไม่ใช้ตีความจนกว่าผ่านเกณฑ์', style: TS.small),
              ]),
            ),
            Pill('ยังไม่ประเมิน', tone: Tone.grey),
          ]),
        ),
        const Gap(10),
        const Text('n = 8 จุด • MAE = ค่าคลาดเคลื่อนเฉลี่ย • Bias = ค่าเบี่ยงเฉลี่ย', style: TS.tiny),
        const Gap(10),
        OutlinedButton.icon(
          onPressed: () => go(context, const ReferenceEntryScreen()),
          icon: const Icon(Icons.add),
          label: const Text('เพิ่มค่าอ้างอิง'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- NEW-04 Reference entry

class ReferenceEntryScreen extends StatefulWidget {
  const ReferenceEntryScreen({super.key});
  @override
  State<ReferenceEntryScreen> createState() => _ReferenceEntryScreenState();
}

class _ReferenceEntryScreenState extends State<ReferenceEntryScreen> {
  int source = 0;
  String point = 'P-08 • ${Mock.plotName}';
  final sample = TextEditingController(text: 'S-08');
  final date = TextEditingController(text: '19 พ.ย. 69');
  // label, probe value, reference controller
  late final rows = <(String, double, TextEditingController)>[
    ('pH', 6.2, TextEditingController(text: '6.0')),
    ('EC mS/cm', 1.1, TextEditingController(text: '0.95')),
    ('ความชื้น %', 22.0, TextEditingController(text: '24')),
  ];

  @override
  void dispose() {
    sample.dispose();
    date.dispose();
    for (final r in rows) {
      r.$3.dispose();
    }
    super.dispose();
  }

  String _diff(double probe, String ref) {
    final v = double.tryParse(ref);
    if (v == null) return '–';
    final d = probe - v;
    final s = d.abs() < 0.995 ? d.abs().toStringAsFixed(2) : d.abs().toStringAsFixed(1);
    return '${d >= 0 ? '+' : '−'}$s';
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'ค่าอ้างอิง',
      bottom: BottomActions(children: [
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            toast(context, 'บันทึกค่าอ้างอิง ${sample.text} แล้ว');
          },
          child: const Text('บันทึกค่าอ้างอิง'),
        ),
        const Text('แนบรูปใบผลแล็บได้ • ทุกการแก้ไขถูกเก็บประวัติ', style: TS.tiny, textAlign: TextAlign.center),
      ]),
      children: [
        const Text('กรอกค่าอ้างอิง', style: TS.h1),
        const Text('ใช้สอบเทียบหัววัดกับผลแล็บหรือเครื่องมือมาตรฐาน', style: TS.small),
        const FieldLabel('จุดที่เก็บตัวอย่าง'),
        PickerField(
          value: point,
          icon: Icons.place_outlined,
          options: [for (final p in Mock.points.take(10)) 'P-${p.id.substring(1)} • ${Mock.plotName}'],
          onChanged: (v) => setState(() => point = v),
        ),
        const FieldLabel('แหล่งค่าอ้างอิง'),
        Segmented(
          options: const ['ผลแล็บ', 'เครื่องมือมาตรฐาน', 'ข้อมูลเดิมฟาร์ม'],
          selected: source,
          onChanged: (i) => setState(() => source = i),
        ),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FieldLabel('รหัสตัวอย่าง'),
              TextField(controller: sample),
            ]),
          ),
          const Gap(10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FieldLabel('วันที่เก็บตัวอย่าง'),
              TextField(controller: date),
            ]),
          ),
        ]),
        const Gap(16),
        AppCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(children: [
            const Row(children: [
              Expanded(flex: 3, child: Text('ค่า', style: TS.label)),
              Expanded(flex: 2, child: Text('หัววัด', style: TS.label, textAlign: TextAlign.center)),
              Expanded(flex: 3, child: Text('อ้างอิง', style: TS.label, textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('ส่วนต่าง', style: TS.label, textAlign: TextAlign.right)),
            ]),
            const Divider(height: 20),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Expanded(flex: 3, child: Text(r.$1, style: TS.title)),
                  Expanded(flex: 2, child: Text(r.$2 % 1 == 0 ? r.$2.toStringAsFixed(0) : '${r.$2}', style: TS.body, textAlign: TextAlign.center)),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: r.$3,
                        onChanged: (_) => setState(() {}),
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TS.title,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(color: AppColors.green, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(color: AppColors.green),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(_diff(r.$2, r.$3.text), style: TS.title.copyWith(color: AppColors.muted), textAlign: TextAlign.right),
                  ),
                ]),
              ),
            const Divider(height: 12),
            const Row(children: [
              Expanded(child: Text('N / P / K', style: TS.label)),
              Text('รอผลแล็บ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue)),
            ]),
          ]),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- NEW-07 Export

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});
  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  int format = 2;
  final opts = <String, bool>{
    'ค่าดินดิบทุกครั้ง (รวมการวัดซ้ำ)': true,
    'พิกัด GPS ความแม่นยำ และเวลา': true,
    'ผลเทียบกับค่าอ้างอิง / ผลแล็บ': true,
    'แผนที่จุดวัดและโซน': true,
    'ข้อสังเกตที่ผู้เชี่ยวชาญรับรองแล้ว': true,
    'ค่า N-P-K (ยังไม่สอบเทียบ)': false,
  };

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'ส่งออกรายงาน',
      bottom: BottomActions(children: [
        FilledButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.check_circle, color: AppColors.green, size: 40),
              title: const Text('ส่งออกสำเร็จ'),
              content: Text(
                'smart_soil_plotA_20261119.${format == 0 ? 'pdf' : format == 1 ? 'csv' : 'pdf + .csv'}\n'
                'SHA-256: 3f9a…c21e (ตัวอย่าง)',
                textAlign: TextAlign.center,
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ปิด'))],
            ),
          ),
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('ส่งออกรายงาน'),
        ),
        const Text('ไฟล์บันทึกในเครื่องและแชร์ต่อได้', style: TS.tiny, textAlign: TextAlign.center),
      ]),
      children: [
        const ListRowCard(
          icon: Icons.crop_square,
          title: Mock.plotName,
          subtitle: '8 ก.ย. – 19 พ.ย. 69 • 4 รอบการวัด',
        ),
        const SectionHeader('ข้อมูลที่รวมในรายงาน', top: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            for (final e in opts.entries)
              CheckboxListTile(
                value: e.value,
                onChanged: (v) => setState(() => opts[e.key] = v ?? false),
                title: Text(e.key, style: TS.body.copyWith(color: e.value ? AppColors.ink : AppColors.muted)),
                dense: true,
                activeColor: AppColors.green,
                controlAffinity: ListTileControlAffinity.leading,
              ),
          ]),
        ),
        const SectionHeader('รูปแบบไฟล์'),
        Segmented(options: const ['PDF รายงาน', 'CSV ข้อมูลดิบ', 'ทั้งสองแบบ'], selected: format, onChanged: (i) => setState(() => format = i)),
        const InfoBox(
          tone: Tone.blue,
          icon: Icons.verified_user_outlined,
          title: 'ตรวจสอบย้อนกลับได้',
          body: 'ทุกแถวมีรหัสจุด เวลา รหัสอุปกรณ์ • แนบ checksum ของไฟล์',
          margin: EdgeInsets.only(top: 16),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- MAIN-10 Settings

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool autoSync = true;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'การตั้งค่า',
      children: [
        AppCard(
          child: Row(children: const [
            IconCircle(Icons.person_outline, size: 48),
            Gap(12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('คุณสมชาย ใจดี', style: TS.h3),
                Text('ผู้ดูแลฟาร์ม • ฟาร์ม มมส.', style: TS.small),
              ]),
            ),
            Pill('โปรไฟล์', tone: Tone.blue),
          ]),
        ),
        const Gap(12),
        ListRowCard(icon: Icons.badge_outlined, title: 'บัญชีผู้ใช้', subtitle: 'ชื่อ เบอร์โทร และบทบาท', onTap: () => go(context, const ChooseRoleScreen())),
        const ListRowCard(icon: Icons.notifications_none, title: 'การแจ้งเตือน', subtitle: 'เลือกฟาร์มและระดับความสำคัญที่ต้องการรับแจ้ง'),
        const ListRowCard(icon: Icons.language, title: 'ภาษา', subtitle: 'ภาษาไทย'),
        const ListRowCard(icon: Icons.straighten, title: 'หน่วยวัด', subtitle: 'ไร่ • °C • pH • EC (mS/cm)'),
        ListRowCard(icon: Icons.lock_outline, title: 'สิทธิ์การเข้าถึง', subtitle: 'ตำแหน่ง Bluetooth การแจ้งเตือน', onTap: () => go(context, const PermissionsScreen())),
        ToggleCard(
          title: 'ซิงก์อัตโนมัติเมื่อออนไลน์',
          subtitle: 'ลดข้อมูลค้างในเครื่องนานเกินไป',
          value: autoSync,
          onChanged: (v) => setState(() => autoSync = v),
        ),
        const InfoBox(
          tone: Tone.green,
          title: 'ตั้งค่าแนะนำสำหรับภาคสนาม',
          body: 'เปิดซิงก์อัตโนมัติ และเปิดตำแหน่งที่ตั้งแบบแม่นยำสูงขณะวัด',
        ),
        const Gap(16),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (r) => false,
          ),
          child: const Text('ออกจากระบบ'),
        ),
      ],
    );
  }
}
