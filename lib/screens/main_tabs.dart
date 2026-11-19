import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/plot_map.dart';
import 'catalog.dart';
import 'data_screens.dart';
import 'device_screens.dart';
import 'farm_screens.dart';
import 'measure_screens.dart';
import 'onboarding_screens.dart';
import 'plan_screens.dart';

/// Root shell: 4 tabs + centre "วัดดิน" button (matches mockup bottom bar).
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [HomeTab(), SoilMapScreen(), AiChatScreen(), MoreTab()],
      ),
      bottomNavigationBar: AppBottomBar(
        index: index,
        onTap: (i) => setState(() => index = i),
        onMeasure: () => go(context, const MeasureConnectScreen()),
      ),
    );
  }
}

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({super.key, required this.index, required this.onTap, required this.onMeasure});
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onMeasure;

  Widget _item(int i, IconData icon, IconData activeIcon, String label) {
    final active = i == index;
    final c = active ? AppColors.green : AppColors.muted;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, color: c),
            const Gap(4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _item(0, Icons.home_outlined, Icons.home_rounded, 'หน้าหลัก'),
              _item(1, Icons.map_outlined, Icons.map_rounded, 'แผนที่'),
              Expanded(
                child: GestureDetector(
                  onTap: onMeasure,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Color(0x402F7D4A), blurRadius: 12, offset: Offset(0, 4))],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                      const Gap(2),
                      const Text('วัดดิน', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green)),
                    ],
                  ),
                ),
              ),
              _item(2, Icons.auto_awesome_outlined, Icons.auto_awesome, 'AI'),
              _item(3, Icons.more_horiz, Icons.more_horiz, 'เพิ่มเติม'),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- MAIN-01 Home

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final m = Mock.avg((p) => p.r.moisture);
    final ph = Mock.avg((p) => p.r.ph);
    final ec = Mock.avg((p) => p.r.ec);
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Soil'), actions: const [BellButton()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          ListRowCard(
            icon: Icons.eco_outlined,
            title: Mock.plotName,
            subtitle: 'ฟาร์ม มมส. • แปลงนำร่อง',
            onTap: () => go(context, const FarmListScreen()),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => go(context, const SyncScreen()),
                child: const Pill('ออนไลน์ • ซิงก์แล้ว', icon: Icons.check),
              ),
              const Spacer(),
              const Text('วัดล่าสุด ${Mock.lastMeasured}', style: TS.small),
            ],
          ),
          const Gap(14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.dark, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('สิ่งที่ต้องทำวันนี้', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      const Gap(8),
                      const Text('! 2 จุดควรตรวจ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      const Gap(4),
                      const Text('แปลง A • โซนด้านล่างความชื้นต่ำ', style: TextStyle(color: AppColors.darkText, fontSize: 12)),
                      const Gap(12),
                      SizedBox(
                        height: 34,
                        child: FilledButton(
                          onPressed: () => go(context, const SoilMapScreen()),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.dark,
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          child: const Text('ดูจุดบนแผนที่ →'),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: Color(0xFF1F5A43), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome, color: AppColors.darkText),
                ),
              ],
            ),
          ),
          const Gap(14),
          AppCard(
            color: AppColors.mapBg,
            borderColor: Colors.transparent,
            padding: const EdgeInsets.all(12),
            onTap: () => go(context, const SoilMapScreen()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Expanded(child: Text('แผนที่แปลง', style: TS.h3)),
                  Pill('ภาพรวม', tone: Tone.grey, small: true),
                ]),
                const Gap(10),
                PlotMap(markers: soilMarkers(), zones: true, height: 150, radius: 12),
                const Gap(8),
                const Text('โซนประมาณจาก 14 จุดวัดจริง • แตะเพื่อดูค่าดินและข้อสังเกต', style: TS.tiny),
              ],
            ),
          ),
          SectionHeader('ข้อมูลล่าสุด (เฉลี่ย 14 จุด)', action: 'ดูทั้งหมด', onAction: () => go(context, const HistoryScreen())),
          TwoCol(children: [
            ValueTile(label: 'ความชื้น', value: '${m.toStringAsFixed(0)}%', icon: Icons.water_drop_outlined),
            ValueTile(label: 'pH', value: ph.toStringAsFixed(1), icon: Icons.science_outlined),
            ValueTile(label: 'EC', value: ec.toStringAsFixed(1), note: 'mS/cm', icon: Icons.bolt_outlined),
            const ValueTile(label: 'อุณหภูมิ', value: '27.4°C', icon: Icons.thermostat_outlined),
          ]),
          GestureDetector(
            onTap: () => go(context, const CalibrationScreen()),
            child: const InfoBox(
              tone: Tone.blue,
              icon: Icons.info_outline,
              title: 'N-P-K แสดงเป็นค่าประมาณ',
              body: 'จนกว่าหัววัดจะผ่านการสอบเทียบและผู้เชี่ยวชาญรับรอง • แตะเพื่อดูผลสอบเทียบ',
              margin: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- MAIN-04 Soil map

class SoilMapScreen extends StatefulWidget {
  const SoilMapScreen({super.key});
  @override
  State<SoilMapScreen> createState() => _SoilMapScreenState();
}

class _SoilMapScreenState extends State<SoilMapScreen> {
  int layer = 0;
  bool zones = true;
  static const layers = ['ภาพรวม', 'ความชื้น', 'pH', 'EC', 'N-P-K'];

  @override
  Widget build(BuildContext context) {
    final watch = Mock.points.where((p) => Mock.layerStatus(p, layer) != SoilStatus.normal).length;
    return Scaffold(
      appBar: AppBar(title: const Text('แผนที่ดิน'), actions: [
        IconButton(
          tooltip: 'แผนจุดวัด',
          onPressed: () => go(context, const SamplingPlanScreen()),
          icon: const Icon(Icons.grid_on_rounded),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          ChipBar(
            options: layers,
            selected: layer,
            onChanged: (i) {
              if (i == 4) {
                toast(context, 'N-P-K ยังไม่ผ่านการสอบเทียบ จึงยังไม่แสดงเป็นชั้นแผนที่');
                return;
              }
              setState(() => layer = i);
            },
          ),
          const Gap(12),
          PlotMap(
            markers: soilMarkers(layer: layer),
            zones: zones && layer <= 1,
            height: 340,
            onTapMarker: (i) => go(context, PointDetailScreen(point: Mock.points[i])),
          ),
          const Gap(10),
          Row(children: [
            _legend(AppColors.green, 'ปกติ'),
            _legend(AppColors.amber, 'ควรเฝ้าดู'),
            _legend(AppColors.red, 'ควรตรวจก่อน'),
          ]),
          const Gap(12),
          ToggleCard(
            title: 'แสดงโซนประมาณ',
            subtitle: 'โซนสีประมาณจาก 14 จุดวัดจริง ไม่ใช่ค่าวัดทุกตำแหน่ง',
            value: zones,
            onChanged: (v) => setState(() => zones = v),
          ),
          const Gap(12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ภาพรวมพื้นที่', style: TS.h3),
                const Gap(2),
                const Text('${Mock.plotName} • 12.4 ไร่', style: TS.small),
                const Gap(10),
                Row(children: [
                  Pill(watch == 0 ? 'ปกติทั้งแปลง' : 'ควรเฝ้าดู $watch จุด', tone: watch == 0 ? Tone.green : Tone.amber),
                  const Gap(8),
                  Pill('ชั้นข้อมูล: ${layers[layer]}', tone: Tone.grey),
                ]),
                const Gap(12),
                InfoBox(
                  tone: Tone.green,
                  margin: EdgeInsets.zero,
                  title: 'AI: โซนด้านล่างความชื้นต่ำกว่าบริเวณอื่น',
                  body: 'แตะจุดบนแผนที่เพื่อดูค่าและข้อสังเกต',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String t) => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const Gap(6),
          Text(t, style: TS.small.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
        ]),
      );
}

// ---------------------------------------------------------------- MAIN-05 AI chat

class ChatMsg {
  final bool fromAi;
  final String text;
  final String? note;
  const ChatMsg(this.fromAi, this.text, {this.note});
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMsg> _msgs = [
    const ChatMsg(true, 'สวัสดีครับ ผมช่วยอธิบายว่าค่าดินในแปลงต่างกันตรงไหน และจุดไหนควรวัดซ้ำ'),
  ];
  bool _typing = false;

  static const suggestions = ['จุดไหนต่างจากค่าเฉลี่ยมากที่สุด?', 'เทียบกับรอบก่อน', 'จุดไหนควรวัดซ้ำ?', 'ค่าไหนยังไม่ผ่านการสอบเทียบ?'];

  String _answer(String q) {
    if (q.contains('ปุ๋ย') || q.contains('N-P-K') || q.contains('ธาตุอาหาร')) {
      return 'ตอนนี้ระบบยังไม่ให้คำแนะนำปุ๋ย เพราะค่า N-P-K จากหัววัดยังไม่ผ่านการสอบเทียบ '
          'ควรใช้ผลแล็บและปรึกษาผู้เชี่ยวชาญก่อนตัดสินใจ';
    }
    if (q.contains('รอบก่อน') || q.contains('เทียบ')) {
      return 'เทียบกับรอบ 30 ก.ย. ความชื้นเฉลี่ยเพิ่มจาก 24% เป็น 28% และจุดเฝ้าดูลดจาก 5 เหลือ 2 จุด '
          'ส่วน pH และ EC แทบไม่เปลี่ยน';
    }
    if (q.contains('วัดซ้ำ')) {
      return 'ควรวัดซ้ำที่จุด #08 และ #09 (โซนด้านล่าง) หลังให้น้ำรอบถัดไป เพื่อดูว่าความชื้นต่ำเป็นทั้งโซนหรือเฉพาะจุด';
    }
    if (q.contains('สอบเทียบ')) {
      return 'ผ่านเกณฑ์แล้ว: pH, EC, อุณหภูมิ • ความชื้นยังต้องปรับค่าชดเชย • N-P-K ยังไม่ได้ประเมินเพราะรอผลแล็บ';
    }
    return 'จุด #08 ความชื้น 22% ต่ำกว่าค่าเฉลี่ยของแปลง (28%) ชัดที่สุด และจุด #09 ที่อยู่ติดกันก็ต่ำเช่นกัน';
  }

  void _send([String? preset]) {
    final q = (preset ?? _ctrl.text).trim();
    if (q.isEmpty) return;
    setState(() {
      _msgs.add(ChatMsg(false, q));
      _typing = true;
    });
    _ctrl.clear();
    _toBottom();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _msgs.add(ChatMsg(true, _answer(q), note: 'อ้างอิง: 14 จุด • ${Mock.lastMeasured}'));
      });
      _toBottom();
    });
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ผู้ช่วย AI'), actions: [
        IconButton(
          tooltip: 'ข้อสังเกตจากข้อมูล',
          onPressed: () => go(context, const AiObservationScreen()),
          icon: const Icon(Icons.fact_check_outlined),
        ),
      ]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: AppCard(
              radius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: const Row(children: [
                Icon(Icons.dataset_outlined, color: AppColors.green, size: 20),
                Gap(10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('กำลังใช้ข้อมูล:', style: TS.tiny),
                    Text('แปลง A • 14 จุด • ค่าเฉลี่ยวัดซ้ำ 3 ครั้ง', style: TS.title),
                  ]),
                ),
              ]),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppColors.chatBg, borderRadius: BorderRadius.circular(16)),
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                children: [
                  for (final m in _msgs) _bubble(m),
                  if (_typing)
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text('AI กำลังอ่านข้อมูล…', style: TS.tiny),
                    ),
                  const InfoBox(
                    tone: Tone.amber,
                    margin: EdgeInsets.only(top: 4, bottom: 12),
                    title: 'ใช้เพื่อคัดกรองจุดที่ควรตรวจ',
                    body: 'ไม่ใช่คำแนะนำปุ๋ยหรือผลวิเคราะห์ทางแล็บ',
                  ),
                  const Text('คำถามแนะนำ', style: TS.label),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in suggestions)
                        ActionChip(
                          label: Text(s),
                          onPressed: () => _send(s),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.line),
                          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(hintText: 'พิมพ์คำถามเกี่ยวกับแปลงนี้'),
                    ),
                  ),
                  const Gap(8),
                  IconButton.filled(
                    onPressed: _send,
                    style: IconButton.styleFrom(backgroundColor: AppColors.green, fixedSize: const Size(48, 48)),
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMsg m) {
    final ai = m.fromAi;
    return Align(
      alignment: ai ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 290),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ai ? Colors.white : AppColors.light,
            borderRadius: BorderRadius.circular(16),
            border: ai ? Border.all(color: AppColors.line) : null,
          ),
          child: Column(
            crossAxisAlignment: ai ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text(m.text, style: TS.body.copyWith(color: ai ? AppColors.ink : AppColors.dark, fontWeight: ai ? FontWeight.w400 : FontWeight.w600)),
              const Gap(6),
              Text(ai ? (m.note ?? 'AI ผู้ช่วยอ่านข้อมูลดิน') : 'คุณ', style: TS.tiny),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- More tab (menu)

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData i, String t, String s, Widget page, {Tone tone = Tone.green}) =>
        ListRowCard(icon: i, title: t, subtitle: s, tone: tone, onTap: () => go(context, page));
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มเติม')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const SectionHeader('ข้อมูลแปลง', top: 4),
          item(Icons.agriculture_outlined, 'ฟาร์มของฉัน', 'ฟาร์มและแปลงทั้งหมด', const FarmListScreen()),
          item(Icons.history, 'ประวัติการวัด', '4 รอบล่าสุด', const HistoryScreen()),
          item(Icons.compare_arrows, 'เปรียบเทียบผล', 'เทียบรอบล่าสุดกับรอบก่อน', const CompareScreen()),
          item(Icons.cloud_sync_outlined, 'การซิงก์ข้อมูล', '8 รายการรอส่ง', const SyncScreen()),
          const SectionHeader('เก็บข้อมูลตามแผน'),
          item(Icons.grid_on_rounded, 'แผนจุดวัด', 'กริด 20 จุด • วัดซ้ำ 3 ครั้ง', const SamplingPlanScreen()),
          item(Icons.near_me_outlined, 'เดินวัดตามแผน', 'วัดแล้ว 7 / 20 จุด', const FieldNavScreen(), tone: Tone.blue),
          item(Icons.science_outlined, 'กรอกค่าอ้างอิง', 'ผลแล็บ / เครื่องมือมาตรฐาน', const ReferenceEntryScreen(), tone: Tone.blue),
          const SectionHeader('คุณภาพข้อมูลและอุปกรณ์'),
          item(Icons.tune, 'ผลสอบเทียบหัววัด', 'ผ่าน 3 / 4 พารามิเตอร์', const CalibrationScreen()),
          item(Icons.build_outlined, 'บำรุงรักษาอุปกรณ์', 'สอบเทียบครั้งถัดไปอีก 30 วัน', const MaintenanceScreen()),
          item(Icons.sensors, 'อุปกรณ์ของฉัน', 'ตัวอ่านค่าดิน #1 • เชื่อมต่ออยู่', const DeviceScreen()),
          const SectionHeader('รายงาน'),
          item(Icons.verified_outlined, 'ทบทวนข้อสังเกต', 'รอผู้เชี่ยวชาญ 2 รายการ', const ExpertReviewScreen(), tone: Tone.amber),
          item(Icons.file_download_outlined, 'ส่งออกรายงาน', 'PDF / CSV ตรวจสอบย้อนกลับได้', const ExportScreen()),
          const SectionHeader('ระบบ'),
          item(Icons.settings_outlined, 'การตั้งค่า', 'บัญชี ภาษา หน่วยวัด การซิงก์', const SettingsScreen(), tone: Tone.grey),
          item(Icons.lock_outline, 'สิทธิ์การเข้าถึง', 'ตำแหน่ง Bluetooth การแจ้งเตือน', const PermissionsScreen(), tone: Tone.grey),
          item(Icons.view_carousel_outlined, 'แคตตาล็อกหน้าจอ (Demo)', 'เปิดทุกหน้าจอเพื่อนำเสนอ', const CatalogScreen(), tone: Tone.grey),
        ],
      ),
    );
  }
}
