import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'data_screens.dart';
import 'main_tabs.dart';
import 'plan_screens.dart';

// ---------------------------------------------------------------- FLOW-01 Connection

class MeasureConnectScreen extends StatelessWidget {
  const MeasureConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void pick(String via) => go(context, MeasureReadyScreen(via: via));
    return ScreenScaffold(
      title: 'วัดดิน',
      step: 'ขั้นที่ 1/3',
      children: [
        const Text('เลือกวิธีรับข้อมูล', style: TS.h1),
        const Text('ฟาร์ม มมส. • แปลง A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark)),
        const Text('ระบบเลือกวิธีที่เหมาะสมให้แล้ว', style: TS.small),
        const Gap(16),
        ListRowCard(
          icon: Icons.bluetooth,
          title: 'Bluetooth',
          subtitle: 'พบตัวอ่านค่าดิน #1 ใกล้คุณ • พร้อมเชื่อมต่อ',
          trailing: const Pill('แนะนำ', tone: Tone.blue, small: true),
          onTap: () => pick('Bluetooth'),
        ),
        ListRowCard(icon: Icons.wifi, title: 'Wi-Fi (วิธีอื่น)', subtitle: 'รับข้อมูลผ่านเครือข่ายเดียวกัน', onTap: () => pick('Wi-Fi')),
        ListRowCard(icon: Icons.usb, title: 'USB (วิธีอื่น)', subtitle: 'ต่อสาย OTG กับตัวอ่านค่า (Android)', onTap: () => pick('USB')),
        ListRowCard(
          icon: Icons.download_outlined,
          title: 'นำเข้าข้อมูลเดิม',
          subtitle: 'ข้อมูลที่บันทึกไว้ในตัวอ่านค่า',
          onTap: () => toast(context, 'นำเข้า 3 รายการจากหน่วยความจำของตัวอ่านค่า (ตัวอย่าง)'),
        ),
        const InfoBox(
          tone: Tone.green,
          icon: Icons.cloud_off_outlined,
          title: 'ข้อมูลไม่หายเมื่อไม่มีอินเทอร์เน็ต',
          body: 'บันทึกข้อมูลในเครื่องได้ และซิงก์ภายหลัง',
        ),
        const Gap(8),
        Center(
          child: TextButton(
            onPressed: () => go(context, const ConnectionErrorScreen()),
            child: const Text('(Demo) จำลองกรณีหาอุปกรณ์ไม่พบ'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- FLOW-02 Ready

class MeasureReadyScreen extends StatelessWidget {
  const MeasureReadyScreen({super.key, this.via = 'Bluetooth', this.pointId = 'P-08'});
  final String via;
  final String pointId;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'วัดดิน',
      step: 'ขั้นที่ 2/3',
      bottom: BottomActions(children: [
        FilledButton.icon(
          onPressed: () => replaceWith(context, MeasureReceivingScreen(pointId: pointId, via: via)),
          icon: const Icon(Icons.download_rounded),
          label: Text('เริ่มวัดจุด $pointId'),
        ),
        const Text('บันทึกพิกัด GPS อัตโนมัติ • วัดซ้ำ 3 ครั้งต่อจุด', style: TS.tiny, textAlign: TextAlign.center),
      ]),
      children: [
        const Text('พร้อมรับข้อมูล', style: TS.h1),
        const Text('ตรวจสอบว่ากำลังบันทึกไปยังแปลงที่ถูกต้อง', style: TS.small),
        const Gap(16),
        AppCard(
          child: Row(children: [
            const IconCircle(Icons.sensors, size: 48),
            const Gap(14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ตัวอ่านค่าดิน #1', style: TS.h3),
                const Gap(6),
                const Pill('เชื่อมต่อแล้ว', icon: Icons.circle, small: true),
                const Gap(4),
                Text('ผ่าน $via', style: TS.small),
              ]),
            ),
          ]),
        ),
        const SectionHeader('ยืนยันพื้นที่ที่จะบันทึก'),
        ListRowCard(
          icon: Icons.eco_outlined,
          title: Mock.plotName,
          subtitle: Mock.farmName,
          onTap: () => toast(context, 'เปลี่ยนแปลงได้จากหน้าเลือกแปลง'),
        ),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Expanded(child: Text('จุดตามแผนสุ่มวัด', style: TS.small)),
              Pill('GPS ±3.8 ม.', tone: Tone.blue, small: true),
            ]),
            const Gap(6),
            Text('$pointId • กริด 20 ม.', style: TS.h3),
            const Text('วัดแล้ว 7 / 20 จุด • ต้องวัดซ้ำ 3 ครั้ง', style: TS.small),
          ]),
        ),
        const InfoBox(
          tone: Tone.blue,
          title: 'ข้อมูลที่จะได้รับ',
          body: 'ความชื้น • อุณหภูมิ • pH • EC\nN • P • K (ค่าประมาณ ยังไม่สอบเทียบ)',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- STATE-01 Receiving (x3)

class MeasureReceivingScreen extends StatefulWidget {
  const MeasureReceivingScreen({super.key, this.pointId = 'P-08', this.via = 'Bluetooth'});
  final String pointId;
  final String via;
  @override
  State<MeasureReceivingScreen> createState() => _MeasureReceivingScreenState();
}

class _MeasureReceivingScreenState extends State<MeasureReceivingScreen> {
  static const params = ['ความชื้น', 'อุณหภูมิ', 'pH', 'EC', 'N / P / K'];
  static const rounds = [
    ['21%', '27.3°C', '6.1', '1.0', '41/18/55'],
    ['22%', '27.4°C', '6.2', '1.2', '42/18/56'],
    ['23%', '27.5°C', '6.3', '1.1', '43/19/57'],
  ];
  int round = 0; // 0..2
  double progress = 0;
  bool waitingReinsert = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _start(initial: true);
  }

  void _start({bool initial = false}) {
    _t?.cancel();
    if (initial) {
      progress = 0;
      waitingReinsert = false;
    } else {
      setState(() {
        progress = 0;
        waitingReinsert = false;
      });
    }
    _t = Timer.periodic(const Duration(milliseconds: 60), (t) {
      if (!mounted) return;
      setState(() => progress = math.min(1.0, progress + 0.025));
      if (progress >= 1) {
        t.cancel();
        if (round < 2) {
          setState(() => waitingReinsert = true);
        } else {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) replaceWith(context, RepeatSummaryScreen(pointId: widget.pointId));
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final got = math.min(params.length, (progress * params.length).floor());
    return ScreenScaffold(
      title: 'กำลังรับข้อมูล',
      step: 'ขั้นที่ 3/3',
      bottom: BottomActions(children: [
        if (waitingReinsert)
          FilledButton(
            onPressed: () {
              setState(() => round++);
              _start();
            },
            child: Text('ปักหัววัดใหม่แล้ว • วัดครั้งที่ ${round + 2}'),
          )
        else
          const InfoBox(
            margin: EdgeInsets.zero,
            tone: Tone.amber,
            title: 'อย่าถอดอุปกรณ์จนกว่าการรับข้อมูลจะเสร็จ',
          ),
        Text('${widget.via} เชื่อมต่ออยู่ • จุด ${widget.pointId}', style: TS.tiny, textAlign: TextAlign.center),
      ]),
      children: [
        _RoundStepper(current: round, done: progress >= 1 ? round + 1 : round),
        const Gap(20),
        Center(
          child: SizedBox(
            width: 150,
            height: 150,
            child: Stack(fit: StackFit.expand, children: [
              CircularProgressIndicator(value: progress, strokeWidth: 10, color: AppColors.green, backgroundColor: AppColors.light),
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${(progress * 100).round()}%', style: TS.h1.copyWith(color: AppColors.green, fontSize: 30)),
                  const Text('กำลังรับข้อมูล', style: TS.small),
                ]),
              ),
            ]),
          ),
        ),
        const Gap(16),
        Center(child: Text('ครั้งที่ ${round + 1}/3 • ได้รับแล้ว $got/${params.length} ค่า', style: TS.title)),
        const Gap(14),
        for (var i = 0; i < params.length; i++)
          AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            radius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Expanded(child: Text(params[i], style: TS.title)),
              Text(i < got ? rounds[round][i] : 'กำลังอ่าน…', style: i < got ? TS.title : TS.small),
              const Gap(10),
              Icon(i < got ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: i < got ? AppColors.green : AppColors.line, size: 22),
            ]),
          ),
      ],
    );
  }
}

class _RoundStepper extends StatelessWidget {
  const _RoundStepper({required this.current, required this.done});
  final int current;
  final int done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) Expanded(child: Container(height: 3, color: i <= done ? AppColors.green : AppColors.line)),
          Column(children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: i < done ? AppColors.green : (i == current ? AppColors.light : AppColors.grey),
              child: i < done
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: i == current ? AppColors.green : AppColors.muted)),
            ),
            const Gap(4),
            Text('ครั้งที่ ${i + 1}', style: TS.tiny),
          ]),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- NEW-03 Repeat summary

class RepeatSummaryScreen extends StatelessWidget {
  const RepeatSummaryScreen({super.key, this.pointId = 'P-08'});
  final String pointId;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['ความชื้น %', '21', '22', '23', '22', '4%'],
      ['อุณหภูมิ °C', '27.3', '27.4', '27.5', '27.4', '0.4%'],
      ['pH', '6.1', '6.2', '6.3', '6.2', '1.6%'],
      ['EC mS/cm', '1.0', '1.2', '1.1', '1.1', '9%'],
    ];
    TextStyle head = const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted);
    Widget cell(String s, {TextStyle? style, TextAlign align = TextAlign.center}) =>
        Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Text(s, textAlign: align, style: style ?? TS.body));
    return ScreenScaffold(
      title: 'วัดดิน',
      step: 'ขั้นที่ 3/3',
      bottom: BottomActions(children: [
        FilledButton(
          onPressed: () => replaceWith(context, MeasureResultScreen(pointId: pointId)),
          child: const Text('บันทึกค่าเฉลี่ยของจุดนี้'),
        ),
        OutlinedButton(
          onPressed: () => replaceWith(context, MeasureReceivingScreen(pointId: pointId)),
          child: const Text('วัดใหม่ทั้ง 3 ครั้ง'),
        ),
      ]),
      children: [
        const Text('วัดซ้ำครบ 3 ครั้ง', style: TS.h1),
        Text('จุด $pointId • ถอนแล้วปักหัววัดใหม่ห่างกันประมาณ 10 ซม.', style: TS.small),
        const Gap(16),
        const _RoundStepper(current: 2, done: 3),
        const Gap(16),
        AppCard(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(children: [
            Table(
              columnWidths: const {0: FlexColumnWidth(2.2), 5: FlexColumnWidth(1.2)},
              border: const TableBorder(horizontalInside: BorderSide(color: AppColors.line)),
              children: [
                TableRow(children: [
                  cell('ค่า', style: head, align: TextAlign.left),
                  cell('#1', style: head),
                  cell('#2', style: head),
                  cell('#3', style: head),
                  cell('เฉลี่ย', style: head),
                  cell('CV', style: head, align: TextAlign.right),
                ]),
                for (final r in rows)
                  TableRow(children: [
                    cell(r[0], style: TS.body.copyWith(fontWeight: FontWeight.w600), align: TextAlign.left),
                    cell(r[1]),
                    cell(r[2]),
                    cell(r[3]),
                    cell(r[4], style: TS.body.copyWith(fontWeight: FontWeight.w700)),
                    cell(r[5],
                        align: TextAlign.right,
                        style: TS.body.copyWith(
                            fontWeight: FontWeight.w700, color: r[5] == '9%' ? AppColors.amber : AppColors.green)),
                  ]),
              ],
            ),
            const Gap(4),
            const Align(alignment: Alignment.centerLeft, child: Text('CV = ความแปรปรวนระหว่าง 3 ครั้ง', style: TS.tiny)),
          ]),
        ),
        const InfoBox(
          tone: Tone.amber,
          icon: Icons.warning_amber_rounded,
          title: 'EC แกว่งใกล้เกณฑ์ (CV 9%)',
          body: 'ถ้า CV เกิน 10% ระบบจะขอให้วัดครั้งที่ 4',
        ),
        const InfoBox(tone: Tone.grey, title: 'N / P / K บันทึกเป็นค่าประมาณ • ยังไม่ใช้ตีความ'),
        const Gap(12),
        AppCard(
          radius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: const [
            Icon(Icons.place_outlined, color: AppColors.green),
            Gap(10),
            Expanded(child: Text('พิกัด 3 ครั้งห่างกันไม่เกิน 1.2 ม.', style: TS.title)),
            Pill('GPS ±3.8 ม.', tone: Tone.blue, small: true),
          ]),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- FLOW-03 Result

class MeasureResultScreen extends StatelessWidget {
  const MeasureResultScreen({super.key, this.pointId = 'P-08'});
  final String pointId;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'ผลการวัด',
      bell: true,
      bottom: BottomActions(children: [
        FilledButton(
          onPressed: () => replaceWith(context, const FieldNavScreen(done: 8)),
          child: const Text('วัดจุดถัดไป (P-09)'),
        ),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => go(context, const SoilMapScreen()), child: const Text('ดูบนแผนที่'))),
          const Gap(10),
          Expanded(child: OutlinedButton(onPressed: () => go(context, const AiObservationScreen()), child: const Text('ถาม AI'))),
        ]),
      ]),
      children: [
        Row(children: [
          Expanded(child: Text('จุดตรวจ $pointId • ตามแผน 8/20', style: TS.small)),
          const Pill('บันทึกแล้ว', icon: Icons.check, small: true),
        ]),
        const Gap(4),
        const Text('ค่าเฉลี่ยจากการวัด 3 ครั้ง', style: TS.h2),
        const Text('วันนี้ 14:32 • ฟาร์ม มมส. • แปลง A', style: TS.tiny),
        const Gap(8),
        const Wrap(spacing: 8, runSpacing: 6, children: [
          Pill('GPS ±3.8 ม.', tone: Tone.blue, small: true),
          Pill('ค่าวัดซ้ำนิ่ง (CV < 10%)', small: true),
        ]),
        const Gap(14),
        const TwoCol(children: [
          ValueTile(label: 'ความชื้น', value: '22 %'),
          ValueTile(label: 'อุณหภูมิ', value: '27.4 °C'),
          ValueTile(label: 'pH', value: '6.2'),
          ValueTile(label: 'EC', value: '1.1', note: 'mS/cm'),
        ]),
        const NpkCard(),
        const Gap(12),
        DarkCard(
          title: 'AI ข้อสังเกต',
          lines: const ['ความชื้นจุดนี้ต่ำกว่าค่าเฉลี่ยของแปลง', 'ควรวัดซ้ำหรือตรวจจุดข้างเคียง'],
          footer: 'ยังไม่ผ่านการทบทวนโดยผู้เชี่ยวชาญ',
        ),
        const Gap(12),
        GestureDetector(
          onTap: () => go(context, const SyncScreen()),
          child: AppCard(
            radius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: const [
              Expanded(child: Text('สถานะซิงก์', style: TS.label)),
              Pill('ซิงก์แล้ว', icon: Icons.check, small: true),
            ]),
          ),
        ),
        const Gap(8),
        Center(
          child: TextButton(
            onPressed: () => go(context, const OfflineSavedScreen()),
            child: const Text('(Demo) ดูกรณีบันทึกแบบออฟไลน์'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- STATE-02 Offline saved

class OfflineSavedScreen extends StatelessWidget {
  const OfflineSavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'บันทึกสำเร็จ',
      bottom: BottomActions(children: [
        FilledButton(onPressed: () => replaceWith(context, const FieldNavScreen(done: 8)), child: const Text('วัดจุดถัดไป')),
        const Text('ระบบจะลองซิงก์ให้อัตโนมัติเมื่อมีอินเทอร์เน็ต', style: TS.tiny, textAlign: TextAlign.center),
      ]),
      children: [
        const Gap(20),
        const Center(child: IconCircle(Icons.check_rounded, size: 88)),
        const Gap(18),
        const Text('บันทึกข้อมูลในเครื่องแล้ว', style: TS.h2, textAlign: TextAlign.center),
        const Gap(6),
        const Text('ไม่จำเป็นต้องเชื่อมต่ออินเทอร์เน็ตตอนวัด\nข้อมูลจะถูกซิงก์เมื่อออนไลน์อีกครั้ง',
            style: TS.small, textAlign: TextAlign.center),
        const InfoBox(
          tone: Tone.amber,
          icon: Icons.cloud_queue,
          title: '1 รายการรอซิงก์',
          body: 'ข้อมูลปลอดภัยอยู่ในเครื่องนี้',
          margin: EdgeInsets.only(top: 20),
        ),
        const Gap(12),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('จุดตรวจล่าสุด', style: TS.small),
            const Gap(4),
            const Text('แปลง A • P-08 • ข้อมูลครบ 7 ค่า', style: TS.h3),
            const Gap(6),
            Row(children: const [
              Expanded(child: Text('22% • pH 6.2 • EC 1.1 • 27.4°C', style: TS.small)),
              Pill('รอซิงก์', tone: Tone.amber, small: true),
            ]),
          ]),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- STATE-03 Connection error

class ConnectionErrorScreen extends StatelessWidget {
  const ConnectionErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'การเชื่อมต่อมีปัญหา',
      bottom: Row(children: [
        Expanded(
          child: FilledButton(
            onPressed: () => replaceWith(context, const MeasureReadyScreen()),
            child: const Text('ค้นหาอีกครั้ง'),
          ),
        ),
        const Gap(10),
        Expanded(
          child: OutlinedButton(
            onPressed: () => replaceWith(context, const MeasureReadyScreen(via: 'USB')),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('ลองผ่าน USB'),
          ),
        ),
      ]),
      children: [
        const Gap(8),
        const Center(child: IconCircle(Icons.error_outline, tone: Tone.red, size: 80)),
        const Gap(14),
        const Text('หาอุปกรณ์ไม่พบ', style: TS.h2, textAlign: TextAlign.center),
        const Text('ตรวจว่าอุปกรณ์เปิดอยู่และอยู่ใกล้โทรศัพท์', style: TS.small, textAlign: TextAlign.center),
        const SectionHeader('สิ่งที่แนะนำให้ลอง'),
        const NumberedRow(n: 1, title: 'เปิด Bluetooth บนมือถือ', subtitle: 'เช็กที่การตั้งค่าของโทรศัพท์'),
        const NumberedRow(n: 2, title: 'ตรวจสอบตัวอ่านค่าดิน', subtitle: 'ดูว่าเปิดเครื่องและแบตเตอรี่เพียงพอ'),
        const NumberedRow(n: 3, title: 'ขยับเข้าใกล้อุปกรณ์', subtitle: 'ระยะไกลเกินไปอาจค้นหาไม่พบ'),
        const InfoBox(
          tone: Tone.amber,
          title: 'ยังวัดต่อได้',
          body: 'บันทึกไว้ในตัวอ่านค่าก่อน แล้วนำเข้าภายหลังผ่าน Wi-Fi หรือ USB',
        ),
        const Gap(12),
        ListRowCard(
          icon: Icons.wifi,
          title: 'ใช้ Wi-Fi หรือนำเข้าข้อมูล',
          subtitle: 'เหมาะเมื่อวัดเสร็จแล้วและส่งข้อมูลภายหลัง',
          onTap: () => replaceWith(context, const MeasureConnectScreen()),
        ),
      ],
    );
  }
}
