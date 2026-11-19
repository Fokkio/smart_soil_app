import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'farm_screens.dart';

// ---------------------------------------------------------------- FLOW-12 Welcome

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(color: AppColors.light, shape: BoxShape.circle),
                child: Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.eco, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
            const Gap(20),
            const Text('Smart Soil', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.dark)),
            const Gap(6),
            const Text('เข้าใจดินของคุณได้ง่ายขึ้น', textAlign: TextAlign.center, style: TS.h2),
            const Gap(6),
            const Text('เริ่มจากฟาร์มแรก แล้วค่อยตั้งค่าอุปกรณ์ภายหลังได้', textAlign: TextAlign.center, style: TS.small),
            const Gap(28),
            const ListRowCard(
              icon: Icons.map_outlined,
              title: 'เห็นความต่างในแปลง',
              subtitle: 'ค่าดินทุกจุดผูกพิกัดและแสดงบนแผนที่',
              trailing: SizedBox(),
            ),
            const ListRowCard(
              icon: Icons.cloud_off_outlined,
              title: 'ทำงานได้แม้ออฟไลน์',
              subtitle: 'บันทึกข้อมูลก่อน แล้วค่อยซิงก์ภายหลัง',
              trailing: SizedBox(),
            ),
            const ListRowCard(
              icon: Icons.verified_outlined,
              title: 'ตรวจสอบย้อนกลับได้',
              subtitle: 'ทุกค่ามีเวลา ประวัติ และค่าอ้างอิงให้เทียบ',
              trailing: SizedBox(),
            ),
            const Gap(24),
            FilledButton(onPressed: () => go(context, const LoginScreen()), child: const Text('เริ่มต้นใช้งาน')),
            const Gap(8),
            TextButton(onPressed: () => go(context, const LoginScreen()), child: const Text('มีบัญชีอยู่แล้ว? เข้าสู่ระบบ')),
            const Gap(4),
            TextButton(
              onPressed: () => openShell(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.muted),
              child: const Text('(Demo) ข้ามไปหน้าหลัก'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- FLOW-13 Login

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool hide = true;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'เข้าสู่ระบบ',
      children: [
        const Gap(8),
        const Center(child: IconCircle(Icons.eco_outlined, size: 64)),
        const Gap(16),
        const Text('ยินดีต้อนรับกลับ', style: TS.h1),
        const Text('เข้าสู่ระบบเพื่อดูข้อมูลฟาร์มและผลการวัดของคุณ', style: TS.small),
        const FieldLabel('อีเมลหรือเบอร์โทร'),
        const TextField(
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(hintText: 'example@email.com', prefixIcon: Icon(Icons.mail_outline)),
        ),
        const FieldLabel('รหัสผ่าน'),
        TextField(
          obscureText: hide,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () => setState(() => hide = !hide),
              icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => toast(context, 'ส่งลิงก์รีเซ็ตรหัสผ่านแล้ว (ตัวอย่าง)'), child: const Text('ลืมรหัสผ่าน?')),
        ),
        const Gap(8),
        FilledButton(onPressed: () => go(context, const ChooseRoleScreen()), child: const Text('เข้าสู่ระบบ')),
        const Gap(10),
        const Center(child: Text('หรือ', style: TS.small)),
        const Gap(10),
        OutlinedButton(onPressed: () => go(context, const ChooseRoleScreen()), child: const Text('เข้าสู่ระบบด้วยเบอร์โทร + OTP')),
        const Gap(16),
        Center(child: TextButton(onPressed: () => go(context, const ChooseRoleScreen()), child: const Text('ยังไม่มีบัญชี? สร้างบัญชี'))),
      ],
    );
  }
}

// ---------------------------------------------------------------- FLOW-14 Choose role

class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});
  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  int role = 0;
  static const roles = [
    (Icons.agriculture_outlined, 'ผู้ดูแลฟาร์ม', ['สร้างแปลง วัดดิน และดูแผนที่', 'อนุมัติสิทธิ์ให้นักวิจัยและนิสิต']),
    (Icons.school_outlined, 'นักวิจัย / นิสิต', ['วัดตามแผนจุดวัด บันทึกค่าอ้างอิง', 'ส่งออกข้อมูลเพื่อวิเคราะห์']),
    (Icons.verified_outlined, 'ผู้เชี่ยวชาญ', ['ทบทวนข้อสังเกตก่อนส่งถึงผู้ดูแล', 'ดูรายงานสอบเทียบ (อ่านอย่างเดียว)']),
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'ตั้งค่าบัญชีครั้งแรก',
      step: 'ขั้นที่ 1/3',
      bottom: FilledButton(onPressed: () => go(context, const FirstSetupScreen()), child: const Text('ดำเนินการต่อ')),
      children: [
        const Text('คุณใช้งานในบทบาทไหน?', style: TS.h1),
        const Text('เมนูและสิทธิ์จะปรับตามบทบาทของคุณ', style: TS.small),
        const Gap(16),
        for (var i = 0; i < roles.length; i++)
          AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            borderColor: role == i ? AppColors.green : AppColors.line,
            borderWidth: role == i ? 2 : 1,
            onTap: () => setState(() => role = i),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconCircle(roles[i].$1, tone: role == i ? Tone.green : Tone.blue),
                const Gap(12),
                Expanded(child: Text(roles[i].$2, style: TS.h3)),
                role == i
                    ? const Pill('เลือกแล้ว', small: true)
                    : const Icon(Icons.radio_button_unchecked, color: AppColors.line),
              ]),
              const Gap(10),
              for (final b in roles[i].$3)
                Padding(padding: const EdgeInsets.only(left: 4, bottom: 2), child: Text('• $b', style: TS.small)),
            ]),
          ),
        const InfoBox(
          tone: Tone.green,
          title: 'เปลี่ยนบทบาทภายหลังได้จากการตั้งค่า',
          body: 'สิทธิ์บางอย่างต้องได้รับอนุมัติจากผู้ดูแลฟาร์ม',
          margin: EdgeInsets.zero,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- FLOW-15 First setup

class FirstSetupScreen extends StatelessWidget {
  const FirstSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'ตั้งค่าเริ่มต้น',
      step: 'ขั้นที่ 2/3',
      bottom: BottomActions(children: [
        FilledButton(onPressed: () => go(context, const CreateFarmScreen()), child: const Text('สร้างฟาร์มแรก')),
        TextButton(onPressed: () => go(context, const PermissionsScreen(onboarding: true)), child: const Text('ข้ามตอนนี้ แล้วตั้งค่าภายหลัง')),
      ]),
      children: [
        const Text('เตรียมพื้นที่ให้พร้อมใช้งาน', style: TS.h1),
        const Text('สร้างฟาร์มก่อน • เพิ่มแปลงและอุปกรณ์ภายหลังได้', style: TS.small),
        const Gap(16),
        NumberedRow(
          n: 1,
          title: 'สร้างฟาร์มแรก',
          subtitle: 'ตั้งชื่อและตำแหน่งฟาร์ม',
          trailing: const Pill('เริ่มสร้าง', tone: Tone.blue, small: true),
          onTap: () => go(context, const CreateFarmScreen()),
        ),
        const NumberedRow(n: 2, title: 'เพิ่มแปลง', subtitle: 'ชนิดพืชและขอบเขตบนแผนที่', trailing: Pill('ทำภายหลังได้', tone: Tone.grey, small: true)),
        const NumberedRow(n: 3, title: 'วางแผนจุดวัด', subtitle: 'ระยะห่างและจำนวนจุดวัด', trailing: Pill('ทำภายหลังได้', tone: Tone.grey, small: true)),
        const NumberedRow(n: 4, title: 'เชื่อมอุปกรณ์', subtitle: 'Bluetooth, Wi-Fi หรือ USB', trailing: Pill('ยังไม่เชื่อม', tone: Tone.grey, small: true)),
        const Gap(8),
        const DarkCard(
          title: 'เริ่มใช้งานได้ทันที',
          lines: ['หน้าแรกจะแสดงสิ่งที่ยังไม่ได้ตั้งค่า จนกว่าจะวัดดินครั้งแรกสำเร็จ'],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- STATE-06 Permissions

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key, this.onboarding = false});
  final bool onboarding;
  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final granted = <bool>[true, false, false];

  @override
  Widget build(BuildContext context) {
    Widget block(int i, IconData icon, Tone tone, String title, String body, String hint, String button) {
      return AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconCircle(icon, tone: tone),
            const Gap(12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TS.h3),
                Text(body, style: TS.small),
              ]),
            ),
          ]),
          const Gap(10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: AppColors.grey, borderRadius: BorderRadius.circular(8)),
            child: Text(hint, textAlign: TextAlign.center, style: TS.tiny),
          ),
          const Gap(10),
          granted[i]
              ? const Pill('อนุญาตแล้ว', icon: Icons.check)
              : FilledButton(
                  onPressed: () => setState(() => granted[i] = true),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  child: Text(button),
                ),
        ]),
      );
    }

    return ScreenScaffold(
      title: 'สิทธิ์การเข้าถึง',
      step: widget.onboarding ? 'ขั้นที่ 3/3' : null,
      bottom: widget.onboarding
          ? FilledButton(onPressed: () => openShell(context), child: const Text('เข้าสู่หน้าหลัก'))
          : null,
      children: [
        block(0, Icons.my_location, Tone.blue, 'อนุญาตตำแหน่งที่ตั้ง', 'ใช้บันทึกพิกัดจุดตรวจและวาดขอบเขตแปลง',
            'ควรเลือก "ตำแหน่งที่แม่นยำ" เพื่อลดความคลาดเคลื่อน GPS', 'อนุญาต'),
        block(1, Icons.bluetooth, Tone.green, 'อนุญาต Bluetooth', 'ใช้ค้นหาและเชื่อมต่อตัวอ่านค่าดินใกล้ตัว',
            'เปิดเฉพาะเวลาวัดดินก็ได้', 'เปิด Bluetooth'),
        block(2, Icons.notifications_none, Tone.amber, 'อนุญาตการแจ้งเตือน', 'รับแจ้งจุดเฝ้าดู การซิงก์ และรอบสอบเทียบ',
            'ช่วยไม่ให้พลาดการแจ้งเตือนสำคัญในภาคสนาม', 'เปิดการแจ้งเตือน'),
      ],
    );
  }
}
