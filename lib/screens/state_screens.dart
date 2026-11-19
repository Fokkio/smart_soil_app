import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'farm_screens.dart';
import 'measure_screens.dart';

// ---------------------------------------------------------------- STATE-04 Empty states

class EmptyStatesScreen extends StatelessWidget {
  const EmptyStatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget block(IconData icon, Tone tone, String title, String body, String action, VoidCallback onTap, {bool primary = false}) {
      return AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          IconCircle(icon, tone: tone, size: 52),
          const Gap(12),
          Text(title, style: TS.h2, textAlign: TextAlign.center),
          const Gap(4),
          Text(body, style: TS.small, textAlign: TextAlign.center),
          const Gap(14),
          primary
              ? FilledButton.icon(onPressed: onTap, icon: const Icon(Icons.add), label: Text(action))
              : OutlinedButton(onPressed: onTap, child: Text(action)),
        ]),
      );
    }

    return ScreenScaffold(
      title: 'ยังไม่มีข้อมูล',
      children: [
        block(Icons.eco_outlined, Tone.green, 'ยังไม่มีฟาร์ม', 'เริ่มต้นด้วยการสร้างฟาร์มแรกของคุณ', 'เพิ่มฟาร์มใหม่',
            () => go(context, const CreateFarmScreen()),
            primary: true),
        block(Icons.pentagon_outlined, Tone.blue, 'ฟาร์มนี้ยังไม่มีแปลง', 'เพิ่มแปลงและกำหนดขอบเขตบนแผนที่', 'เพิ่มแปลงแรก',
            () => go(context, const CreatePlotScreen())),
        block(Icons.place_outlined, Tone.amber, 'ยังไม่มีข้อมูลการวัด', 'เริ่มวัดดินเพื่อดูแผนที่และข้อสังเกต', 'ไปที่การวัดดิน',
            () => go(context, const MeasureConnectScreen())),
      ],
    );
  }
}

// ---------------------------------------------------------------- STATE-05 Loading states

class LoadingStatesScreen extends StatelessWidget {
  const LoadingStatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget skel(double w) => Container(
          height: 10,
          width: w,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: const Color(0xFFE6EBE7), borderRadius: BorderRadius.circular(6)),
        );
    return ScreenScaffold(
      title: 'กำลังโหลด',
      children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('กำลังโหลดแผนที่แปลง', style: TS.h3),
            const Text('ระบบกำลังเตรียมข้อมูลตำแหน่งและเลเยอร์ดิน', style: TS.small),
            const Gap(12),
            Container(
              height: 110,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFEFF2EF), borderRadius: BorderRadius.circular(12)),
              child: Stack(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [skel(110), skel(200), skel(150)]),
                const Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.green)),
                ),
              ]),
            ),
          ]),
        ),
        const Gap(12),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.auto_awesome, color: AppColors.green, size: 20),
              Gap(8),
              Flexible(child: Text('AI กำลังวิเคราะห์ข้อมูลดิน', style: TS.h3, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const Text('อาจใช้เวลาเล็กน้อยหากมีหลายจุดตรวจ', style: TS.small),
            const Gap(12),
            skel(240),
            skel(200),
            skel(160),
          ]),
        ),
        const Gap(12),
        const AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.green)),
              Gap(10),
              Text('กำลังซิงก์ข้อมูล', style: TS.h3),
            ]),
            Text('ส่งข้อมูล 3 จาก 8 รายการไปยังระบบ', style: TS.small),
            Gap(12),
            Bar(3 / 8),
          ]),
        ),
      ],
    );
  }
}
