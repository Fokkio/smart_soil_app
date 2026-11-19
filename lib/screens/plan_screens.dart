import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/plot_map.dart';
import 'measure_screens.dart';

List<Offset> gridPoints(int cols, int rows) => [
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < cols; c++)
          Offset(
            0.20 + (cols == 1 ? 0 : c * 0.58 / (cols - 1)),
            0.22 + (rows == 1 ? 0 : r * 0.53 / (rows - 1)),
          ),
    ];

// ---------------------------------------------------------------- NEW-01 Sampling plan

class SamplingPlanScreen extends StatefulWidget {
  const SamplingPlanScreen({super.key});
  @override
  State<SamplingPlanScreen> createState() => _SamplingPlanScreenState();
}

class _SamplingPlanScreenState extends State<SamplingPlanScreen> {
  static const spacings = [15, 20, 25];
  static const grids = [(6, 5), (5, 4), (4, 3)];
  int s = 1;
  int repeats = 3;
  int pattern = 0;

  @override
  Widget build(BuildContext context) {
    final (cols, rows) = grids[s];
    final pts = gridPoints(cols, rows);
    final n = pts.length;
    final corners = {0, cols - 1, n - cols, n - 1};
    return ScreenScaffold(
      title: 'แผนจุดวัด',
      bottom: FilledButton(
        onPressed: n < 20
            ? null
            : () => replaceWith(context, const FieldNavScreen()),
        child: Text(n < 20 ? 'จุดน้อยกว่า 20 จุด' : 'ยืนยันแผนและเริ่มวัด'),
      ),
      children: [
        AppCard(
          radius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: const Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${Mock.plotName} • 12.4 ไร่', style: TS.title),
                Text('ร่างแผน • ยังไม่เริ่มวัด', style: TS.small),
              ]),
            ),
            Pill('ร่าง', tone: Tone.amber),
          ]),
        ),
        const Gap(12),
        PlotMap(
          height: 280,
          grid: true,
          markers: [
            for (var i = 0; i < n; i++)
              PlotMarker(pts[i], MarkerKind.plan, label: corners.contains(i) ? 'P-${(i + 1).toString().padLeft(2, '0')}' : null),
          ],
        ),
        const Gap(12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Column(children: [
            _stepper('ระยะห่างระหว่างจุด', '${spacings[s]} ม.',
                s > 0 ? () => setState(() => s--) : null, s < spacings.length - 1 ? () => setState(() => s++) : null),
            const Divider(height: 1),
            _stepper('วัดซ้ำต่อจุด', '$repeats ครั้ง', repeats > 3 ? () => setState(() => repeats--) : null,
                repeats < 5 ? () => setState(() => repeats++) : null),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 8, 12),
              child: Row(children: [
                const Expanded(child: Text('จำนวนจุดวัด', style: TS.body)),
                Text('$n จุด', style: TS.title.copyWith(color: n < 20 ? AppColors.red : AppColors.ink)),
              ]),
            ),
          ]),
        ),
        const FieldLabel('รูปแบบการวางจุด'),
        Segmented(
          options: const ['กริดตามแนวปลูก', 'กริดสี่เหลี่ยม', 'สุ่มแบ่งชั้น'],
          selected: pattern,
          onChanged: (i) => setState(() => pattern = i),
        ),
        InfoBox(
          tone: n < 20 ? Tone.red : Tone.green,
          title: n < 20 ? 'จำนวนจุดต่ำกว่าเกณฑ์ขั้นต่ำ 20 จุด' : 'ผ่านเกณฑ์ขั้นต่ำ 20 จุดตามข้อเสนอโครงการ',
          body: 'ย้ายจุดได้ไม่เกิน 3 ม. หากติดแนวปลูก • ต้องบันทึกเหตุผลทุกครั้ง',
        ),
      ],
    );
  }

  Widget _stepper(String label, String value, VoidCallback? minus, VoidCallback? plus) {
    return Row(children: [
      Expanded(child: Text(label, style: TS.body)),
      IconButton(onPressed: minus, icon: const Icon(Icons.remove_circle_outline), color: AppColors.green),
      SizedBox(width: 56, child: Text(value, textAlign: TextAlign.center, style: TS.title)),
      IconButton(onPressed: plus, icon: const Icon(Icons.add_circle_outline), color: AppColors.green),
    ]);
  }
}

// ---------------------------------------------------------------- NEW-02 Field navigation

class FieldNavScreen extends StatelessWidget {
  const FieldNavScreen({super.key, this.done = 7});
  final int done;

  @override
  Widget build(BuildContext context) {
    const total = 20;
    final pts = gridPoints(5, 4);
    final next = done.clamp(0, total - 1).toInt();
    final nextId = 'P-${(next + 1).toString().padLeft(2, '0')}';
    final np = pts[next];
    final user = Offset((np.dx - 0.14).clamp(0.08, 0.92).toDouble(), (np.dy + 0.16).clamp(0.08, 0.92).toDouble());
    return ScreenScaffold(
      title: 'วัดตามแผน',
      step: '${next + 1} / $total จุด',
      bottom: BottomActions(children: [
        FilledButton(
          onPressed: () => go(context, MeasureReadyScreen(pointId: nextId)),
          child: Text('เริ่มวัดที่ $nextId'),
        ),
        OutlinedButton(
          onPressed: () => _skip(context, nextId),
          child: const Text('ข้ามจุดนี้ (ต้องระบุเหตุผล)'),
        ),
      ]),
      children: [
        Text('วัดแล้ว $done จุด • เหลือ ${total - done} จุด', style: TS.small),
        const Gap(6),
        Bar(done / total),
        const Gap(12),
        PlotMap(
          height: 280,
          grid: true,
          user: user,
          routeTo: np,
          markers: [
            for (var i = 0; i < total; i++)
              PlotMarker(pts[i], i < done ? MarkerKind.done : (i == next ? MarkerKind.next : MarkerKind.todo)),
          ],
        ),
        const Gap(12),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('จุดถัดไป', style: TS.small),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(nextId, style: TS.h1),
              const Gap(12),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('ห่างไป 18 ม. • ทิศตะวันออกเฉียงเหนือ', style: TS.title),
                ),
              ),
            ]),
            const Gap(8),
            const Wrap(spacing: 8, runSpacing: 6, children: [
              Pill('GPS ±3.8 ม.', tone: Tone.blue, small: true),
              Pill('ถึงจุดเมื่อห่าง ≤ 5 ม.', tone: Tone.grey, small: true),
            ]),
          ]),
        ),
        const Gap(12),
        Wrap(children: [
          _legend(AppColors.green, 'วัดแล้ว', true),
          _legend(AppColors.blue, 'จุดถัดไป', true),
          _legend(AppColors.hint, 'ยังไม่วัด', false),
        ]),
      ],
    );
  }

  Widget _legend(Color c, String t, bool fill) => Padding(
        padding: const EdgeInsets.only(right: 18),
        child: Row(children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: fill ? c : Colors.white,
              shape: BoxShape.circle,
              border: fill ? null : Border.all(color: c, width: 1.6),
            ),
          ),
          const Gap(6),
          Text(t, style: TS.small.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
        ]),
      );

  Future<void> _skip(BuildContext context, String id) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ข้าม $id'),
        content: TextField(
          controller: reason,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'เหตุผล เช่น น้ำขัง / ติดแนวปลูก'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ยืนยันข้าม')),
        ],
      ),
    );
    final text = reason.text.trim();
    if (ok == true && context.mounted) {
      toast(context, text.isEmpty ? 'ต้องระบุเหตุผลก่อนข้ามจุด' : 'ข้าม $id แล้ว • เหตุผล: $text');
    }
  }
}

// ---------------------------------------------------------------- NEW-08 Expert review

class ReviewItem {
  ReviewItem(this.title, this.evidence, {this.state = 0});
  final String title;
  final String evidence;
  int state; // 0 pending, 1 approved, 2 returned
}

class ExpertReviewScreen extends StatefulWidget {
  const ExpertReviewScreen({super.key});
  @override
  State<ExpertReviewScreen> createState() => _ExpertReviewScreenState();
}

class _ExpertReviewScreenState extends State<ExpertReviewScreen> {
  int tab = 0;
  final items = <ReviewItem>[
    ReviewItem('โซนล่างความชื้นต่ำกว่าเฉลี่ย ~6%', 'หลักฐาน: จุด #08–#09 • วัดซ้ำ 3 ครั้ง • 2 รอบ'),
    ReviewItem('EC จุด #12 สูงกว่าจุดอื่นในแปลง', 'หลักฐาน: 1 จุด • ยังไม่มีผลแล็บยืนยัน'),
    ReviewItem('pH ทั้งแปลงอยู่ในช่วงแคบ 6.0–6.4', 'หลักฐาน: 14 จุด • ผลแล็บ 8 จุดสอดคล้อง', state: 1),
    ReviewItem('ความชื้นเฉลี่ยเพิ่มขึ้นหลังรอบให้น้ำ', 'หลักฐาน: 4 รอบการวัด • จุดเดิม', state: 1),
    ReviewItem('อุณหภูมิดินไม่ต่างกันระหว่างโซน', 'หลักฐาน: 14 จุด • ต่างกันไม่เกิน 0.5 °C', state: 1),
    ReviewItem('N ต่ำในโซนด้านบน', 'ตีกลับ: N-P-K ยังไม่ผ่านการสอบเทียบ', state: 2),
  ];

  @override
  Widget build(BuildContext context) {
    final counts = [0, 1, 2].map((s) => items.where((e) => e.state == s).length).toList();
    final list = items.where((e) => e.state == tab).toList();
    final approved = counts[1];
    return ScreenScaffold(
      title: 'ทบทวนข้อสังเกต',
      children: [
        const InfoBox(
          tone: Tone.blue,
          icon: Icons.verified_outlined,
          title: 'ข้อสังเกตจะส่งถึงผู้ดูแลฟาร์ม',
          body: 'หลังผู้เชี่ยวชาญรับรองแล้วเท่านั้น',
          margin: EdgeInsets.zero,
        ),
        const Gap(12),
        Segmented(
          options: ['รอทบทวน (${counts[0]})', 'รับรองแล้ว (${counts[1]})', 'ตีกลับ (${counts[2]})'],
          selected: tab,
          onChanged: (i) => setState(() => tab = i),
        ),
        const Gap(12),
        if (list.isEmpty) const InfoBox(tone: Tone.grey, title: 'ไม่มีรายการในหมวดนี้', margin: EdgeInsets.zero),
        for (final it in list)
          AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Pill(
                  ['รอทบทวน', 'รับรองแล้ว', 'ตีกลับ'][it.state],
                  tone: [Tone.amber, Tone.green, Tone.red][it.state],
                  small: true,
                ),
                const Spacer(),
                const Text('AI • 19 พ.ย.', style: TS.tiny),
              ]),
              const Gap(10),
              Text(it.title, style: TS.h3),
              const Gap(2),
              Text(it.evidence, style: TS.tiny),
              if (it.state == 0) ...[
                const Gap(12),
                Row(children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => setState(() => it.state = 1),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        backgroundColor: AppColors.light,
                        foregroundColor: AppColors.green,
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('รับรอง'),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => it.state = 2),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40), foregroundColor: AppColors.muted),
                      child: const Text('ตีกลับ / แก้ไข'),
                    ),
                  ),
                ]),
              ],
            ]),
          ),
        const Gap(4),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('ข้อเสนอแนะที่รับรองแล้ว', style: TS.title)),
              Text('$approved / เป้า 3–5', style: TS.title.copyWith(color: AppColors.green)),
            ]),
            const Gap(8),
            Bar(approved / 5),
            const Gap(6),
            const Text('ใช้ในรายงานส่งมอบพื้นที่นำร่อง', style: TS.tiny),
          ]),
        ),
      ],
    );
  }
}
