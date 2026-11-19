import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/plot_map.dart';
import 'device_screens.dart';
import 'main_tabs.dart';
import 'plan_screens.dart';

// ---------------------------------------------------------------- FLOW-07 Point detail

class PointDetailScreen extends StatelessWidget {
  const PointDetailScreen({super.key, required this.point});
  final SoilPoint point;

  @override
  Widget build(BuildContext context) {
    final r = point.r;
    final avgM = Mock.avg((p) => p.r.moisture);
    final moistLow = r.moisture < 24;
    Widget st(bool watch) => Pill(watch ? 'เฝ้าดู' : 'ปกติ', tone: watch ? Tone.amber : Tone.green, small: true);
    return ScreenScaffold(
      title: 'จุดตรวจ ${point.id}',
      bell: true,
      bottom: BottomActions(children: [
        FilledButton(onPressed: () => go(context, const AiChatScreen()), child: const Text('ถาม AI โดยใช้ข้อมูลทั้งแปลง')),
        OutlinedButton(onPressed: () => go(context, const ReferenceEntryScreen()), child: const Text('กรอกค่าอ้างอิงของจุดนี้')),
      ]),
      children: [
        AppCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.place_outlined, color: AppColors.green),
            const Gap(10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(Mock.plotName, style: TS.h3),
                Text('${Mock.lastMeasured} • โซน${point.zone}ของแปลง', style: TS.small),
                Text('16.2451, 103.2512 • GPS ±3.8 ม.', style: TS.tiny),
                const Gap(8),
                Pill(statusLabel(point.status), tone: point.status == SoilStatus.normal ? Tone.green : Tone.amber, small: true),
              ]),
            ),
          ]),
        ),
        if (point.status != SoilStatus.normal)
          InfoBox(
            tone: Tone.amber,
            title: 'สรุปจุดนี้',
            body: 'ความชื้นต่ำกว่าค่าเฉลี่ยแปลง (${avgM.toStringAsFixed(0)}%) • ควรวัดซ้ำรอบถัดไป',
          ),
        const Gap(12),
        TwoCol(children: [
          ValueTile(label: 'ความชื้น', value: '${r.moisture.toStringAsFixed(0)} %', status: st(moistLow)),
          ValueTile(label: 'อุณหภูมิ', value: '${r.temp} °C', status: st(false)),
          ValueTile(label: 'pH', value: '${r.ph}', status: st(r.ph < 5.8 || r.ph > 6.8)),
          ValueTile(label: 'EC', value: '${r.ec}', note: 'mS/cm', status: st(r.ec > 1.4)),
        ]),
        const Text('เกณฑ์สถานะ: เทียบค่าเฉลี่ยของแปลง ± 1 SD (รอเกณฑ์จากผู้เชี่ยวชาญ)', style: TS.tiny),
        const Gap(10),
        NpkCard(n: r.n, p: r.p, k: r.k, note: 'ไม่แสดงสถานะจนกว่าจะผ่านการสอบเทียบ'),
        const Gap(10),
        AppCard(
          radius: 12,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('การวัดซ้ำและค่าอ้างอิง', style: TS.title),
            const Gap(6),
            Text(
              'ความชื้น ${(r.moisture - 1).toStringAsFixed(0)} • ${r.moisture.toStringAsFixed(0)} • '
              '${(r.moisture + 1).toStringAsFixed(0)} %  (CV 4%)',
              style: TS.body,
            ),
            const Gap(4),
            Row(children: const [
              Expanded(child: Text('ผลแล็บ: รอผลตัวอย่าง S-08', style: TS.small)),
              Pill('รอผล', tone: Tone.blue, small: true),
            ]),
          ]),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- FLOW-08 AI observation

class AiObservationScreen extends StatelessWidget {
  const AiObservationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'ข้อสังเกตจากข้อมูล',
      bottom: BottomActions(children: [
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => go(context, const SoilMapScreen()), child: const Text('ดูบนแผนที่'))),
          const Gap(10),
          Expanded(
            child: FilledButton(
              onPressed: () => go(context, const AiChatScreen()),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              child: const Text('ถาม AI ต่อ'),
            ),
          ),
        ]),
        const Text('ข้อสังเกตนี้ยังไม่ผ่านการทบทวน', style: TS.tiny, textAlign: TextAlign.center),
      ]),
      children: [
        AppCard(
          radius: 12,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Expanded(child: Text('ข้อมูลที่ใช้วิเคราะห์', style: TS.small)),
              Text('วันนี้ 14:32', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue)),
            ]),
            const Gap(4),
            const Text('แปลง A • 14 จุด • pH / EC / ความชื้น / อุณหภูมิ', style: TS.title),
          ]),
        ),
        const Gap(12),
        const DarkCard(
          title: 'AI ข้อสังเกต',
          lines: [
            'ความชื้นโซนด้านล่าง (จุด #08–#09) ต่ำกว่าค่าเฉลี่ยของแปลงประมาณ 6%',
            'pH, EC และอุณหภูมิ อยู่ใกล้ค่าเฉลี่ยของแปลง',
          ],
          footer: 'ความมั่นใจ: ปานกลาง • 2 จุดติดกัน วัดซ้ำครบ',
        ),
        const SectionHeader('สิ่งที่ควรตรวจสอบต่อ'),
        NumberedRow(
          n: 1,
          title: 'ดูจุดข้างเคียงบนแผนที่',
          subtitle: 'ยืนยันว่าเป็นทั้งโซน ไม่ใช่แค่จุดเดียว',
          onTap: () => go(context, const SoilMapScreen()),
        ),
        NumberedRow(
          n: 2,
          title: 'วัดซ้ำหลังให้น้ำรอบถัดไป',
          subtitle: 'เปรียบเทียบกับผลรอบนี้',
          onTap: () => go(context, const FieldNavScreen()),
        ),
        NumberedRow(
          n: 3,
          title: 'ส่งให้ผู้ดูแลฟาร์มทบทวน',
          subtitle: 'ก่อนสรุปเป็นข้อเสนอแนะ',
          onTap: () => go(context, const ExpertReviewScreen()),
        ),
        const InfoBox(
          tone: Tone.grey,
          title: 'ไม่วิเคราะห์ N-P-K และไม่ให้คำแนะนำปุ๋ย',
          body: 'จนกว่าหัววัดผ่านการสอบเทียบและผู้เชี่ยวชาญรับรอง',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- MAIN-06 History

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int range = 3;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'ประวัติการวัด',
      bell: true,
      children: [
        AppCard(
          child: Row(children: const [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('แปลงที่เลือก', style: TS.small),
                Text(Mock.plotName, style: TS.h3),
              ]),
            ),
            Pill('14 จุดวัดล่าสุด', tone: Tone.blue),
          ]),
        ),
        const Gap(12),
        Segmented(options: const ['วัน', 'สัปดาห์', 'เดือน', 'ทั้งหมด'], selected: range, onChanged: (i) => setState(() => range = i)),
        const SectionHeader('รายการย้อนหลัง'),
        for (var i = 0; i < Mock.history.length; i++)
          _round(context, Mock.history[i], i),
      ],
    );
  }

  Widget _round(BuildContext context, HistoryRound h, int i) {
    final tone = i == 0 ? Tone.amber : (i == 1 ? Tone.blue : (i == 2 ? Tone.green : Tone.grey));
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => go(context, const CompareScreen()),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const IconCircle(Icons.history, tone: Tone.amber, size: 36),
        const Gap(12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.date, style: TS.h3),
            Text(h.time, style: TS.tiny),
            const Gap(6),
            Text(h.summary, style: TS.body),
          ]),
        ),
        Pill(h.tag, tone: tone, small: true),
      ]),
    );
  }
}

// ---------------------------------------------------------------- FLOW-09 Compare

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});
  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  int metric = 0;
  static const metrics = ['ความชื้น', 'pH', 'EC', 'จุดเฝ้าดู'];
  static const series = <List<double>>[
    [23, 26, 24, 28],
    [6.0, 6.1, 6.1, 6.2],
    [1.0, 1.0, 1.0, 1.1],
    [0, 1, 5, 2],
  ];
  static const units = ['%', '', '', ''];

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'เปรียบเทียบผล',
      children: [
        Row(children: const [
          Expanded(child: _RoundBox(label: 'รอบล่าสุด', value: 'วันนี้ 14:32')),
          Gap(10),
          Expanded(child: _RoundBox(label: 'เทียบกับ', value: '30 ก.ย. 09:10')),
        ]),
        const Gap(12),
        const DarkCard(
          icon: Icons.insights,
          title: 'สรุปการเปลี่ยนแปลง',
          lines: ['ความชื้นเฉลี่ยเพิ่มขึ้น 4%', 'จุดเฝ้าดูลดจาก 5 เหลือ 2 จุด'],
          footer: 'เทียบเฉพาะจุดที่วัดตำแหน่งเดิมทั้งสองรอบ',
        ),
        const Gap(12),
        const TwoCol(children: [
          ValueTile(label: 'ความชื้น', value: '24% → 28%', status: Pill('ดีขึ้น', small: true)),
          ValueTile(label: 'pH', value: '6.1 → 6.2', status: Pill('คงที่', tone: Tone.blue, small: true)),
          ValueTile(label: 'EC', value: '1.0 → 1.1', status: Pill('คงที่', tone: Tone.blue, small: true)),
          ValueTile(label: 'จุดเฝ้าดู', value: '5 → 2 จุด', status: Pill('ลดลง', small: true)),
        ]),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('แนวโน้มตามตัวชี้วัดที่เลือก', style: TS.h3),
            const Text('4 รอบล่าสุด', style: TS.small),
            const Gap(10),
            ChipBar(options: metrics, selected: metric, onChanged: (i) => setState(() => metric = i)),
            const Gap(10),
            TrendChart(
              values: series[metric],
              labels: const ['8 ก.ย.', '21 ก.ย.', '30 ก.ย.', 'วันนี้'],
              unit: units[metric],
            ),
          ]),
        ),
      ],
    );
  }
}

class _RoundBox extends StatelessWidget {
  const _RoundBox({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => AppCard(
        radius: 12,
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TS.small),
          const Gap(2),
          Text(value, style: TS.title.copyWith(fontSize: 15)),
        ]),
      );
}

// ---------------------------------------------------------------- MAIN-07 Notifications

class NotiItem {
  final IconData icon;
  final Tone tone;
  final String title, sub, time, body, action, cat;
  final Widget Function() page;
  const NotiItem(this.icon, this.tone, this.title, this.sub, this.time, this.body, this.action, this.cat, this.page);
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int tab = 0;

  static final items = <NotiItem>[
    NotiItem(Icons.notifications_active_outlined, Tone.amber, 'ความชื้นลดลง', 'โซนด้านล่าง • ${Mock.plotName}', 'วันนี้ 14:35',
        'พบ 2 จุดมีค่าต่ำกว่าค่าเฉลี่ย', 'ดูจุดบนแผนที่ →', 'แจ้งเตือน', () => const SoilMapScreen()),
    NotiItem(Icons.sync, Tone.blue, 'ซิงก์ข้อมูลสำเร็จ', Mock.farmName, 'วันนี้ 14:33', 'ระบบบันทึกผลการวัด 14 จุดเรียบร้อย',
        'ดูประวัติซิงก์ →', 'ระบบ', () => const SyncScreen()),
    NotiItem(Icons.replay, Tone.red, 'ควรวัดซ้ำ', 'จุดตรวจ #08', 'วันนี้ 14:32', 'ค่าต่างจากเฉลี่ย ควรวัดซ้ำหลังให้น้ำ',
        'ไปวัดตามแผน →', 'ต้องทำ', () => const FieldNavScreen()),
    NotiItem(Icons.tune, Tone.grey, 'ถึงรอบสอบเทียบหัววัด', 'ตัวอ่านค่าดิน #1', '30 ก.ย. 09:15', 'ครบ 30 วันจากการสอบเทียบครั้งล่าสุด',
        'ไปหน้าสอบเทียบ →', 'ต้องทำ', () => const MaintenanceScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    const tabs = ['ทั้งหมด', 'ต้องทำ', 'แจ้งเตือน', 'ระบบ'];
    final list = tab == 0 ? items : items.where((e) => e.cat == tabs[tab]).toList();
    return ScreenScaffold(
      title: 'การแจ้งเตือน',
      children: [
        Segmented(options: tabs, selected: tab, onChanged: (i) => setState(() => tab = i)),
        const Gap(12),
        for (final n in list)
          AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            onTap: () => go(context, n.page()),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconCircle(n.icon, tone: n.tone, size: 36),
              const Gap(12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(n.title, style: TS.h3)),
                    Text(n.time, style: TS.tiny),
                  ]),
                  Text(n.sub, style: TS.tiny),
                  const Gap(6),
                  Text(n.body, style: TS.body),
                  const Gap(6),
                  Align(alignment: Alignment.centerRight, child: Text(n.action, style: TS.link.copyWith(fontSize: 12))),
                ]),
              ),
            ]),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- MAIN-08 Sync

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});
  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

enum SyncState { pending, failed, done }

class _SyncScreenState extends State<SyncScreen> {
  int tab = 0;
  final rows = <List<dynamic>>[
    ['จุดตรวจ #08', 'แปลง A • วันนี้ 14:32', SyncState.pending],
    ['จุดตรวจ #09', 'แปลง A • วันนี้ 14:36', SyncState.pending],
    ['จุดตรวจ #10', 'แปลง A • วันนี้ 14:41', SyncState.failed],
    ['จุดตรวจ #03', 'แปลง B • วันนี้ 11:20', SyncState.done],
  ];

  void _syncAll({bool failedOnly = false}) {
    setState(() {
      for (final r in rows) {
        final s = r[2] as SyncState;
        if (!failedOnly || s == SyncState.failed) r[2] = SyncState.done;
      }
    });
    toast(context, failedOnly ? 'ลองส่งรายการที่ล้มเหลวใหม่แล้ว' : 'ซิงก์ครบทุกรายการแล้ว');
  }

  @override
  Widget build(BuildContext context) {
    final pending = rows.where((r) => r[2] != SyncState.done).length;
    const tabs = ['ทั้งหมด', 'รอส่ง', 'ผิดพลาด', 'สำเร็จ'];
    final filtered = rows.where((r) {
      final s = r[2] as SyncState;
      return switch (tab) {
        1 => s == SyncState.pending,
        2 => s == SyncState.failed,
        3 => s == SyncState.done,
        _ => true,
      };
    }).toList();
    return ScreenScaffold(
      title: 'การซิงก์ข้อมูล',
      bottom: Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: _syncAll, icon: const Icon(Icons.sync), label: const Text('ซิงก์ทั้งหมด'))),
        const Gap(10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _syncAll(failedOnly: true),
            icon: const Icon(Icons.replay),
            label: const Text('ส่งใหม่ที่ล้มเหลว'),
          ),
        ),
      ]),
      children: [
        DarkCard(
          icon: Icons.sync,
          title: pending == 0 ? 'ข้อมูลทั้งหมดอยู่บนระบบแล้ว' : '$pending รายการรอส่งขึ้นระบบ',
          lines: const ['ข้อมูลในเครื่องปลอดภัยแล้ว'],
          footer: 'ออนไลน์ • กำลังซิงก์อัตโนมัติ',
        ),
        const Gap(12),
        Segmented(options: tabs, selected: tab, onChanged: (i) => setState(() => tab = i)),
        const Gap(12),
        for (final r in filtered) _row(r[0] as String, r[1] as String, r[2] as SyncState),
      ],
    );
  }

  Widget _row(String t, String s, SyncState st) {
    final (label, tone, icon) = switch (st) {
      SyncState.pending => ('รอซิงก์', Tone.amber, Icons.schedule),
      SyncState.failed => ('ล้มเหลว', Tone.red, Icons.error_outline),
      SyncState.done => ('สำเร็จ', Tone.green, Icons.check),
    };
    return ListRowCard(icon: icon, tone: tone, title: t, subtitle: s, trailing: Pill(label, tone: tone, small: true));
  }
}
