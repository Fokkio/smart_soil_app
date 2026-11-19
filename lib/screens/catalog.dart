import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/seed.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'data_screens.dart';
import 'device_screens.dart';
import 'farm_screens.dart';
import 'fertilizer_screens.dart';
import 'main_tabs.dart';
import 'measure_screens.dart';
import 'onboarding_screens.dart';
import 'plan_screens.dart';
import 'state_screens.dart';

class _Entry {
  const _Entry(this.id, this.name, this.build);
  final String id;
  final String name;
  final Widget Function() build;
}

/// Demo index: opens every screen from the revised UI mockup by its ID.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  static final sections = <String, List<_Entry>>{
    'หน้าหลัก (MAIN)': [
      _Entry('MAIN-01', 'Home / Dashboard', () => const AppShell()),
      _Entry('MAIN-02', 'Farm List', () => const FarmListScreen()),
      _Entry('MAIN-03', 'Plot List', () => const PlotListScreen()),
      _Entry('MAIN-04', 'Soil Map', () => const AppShell(initialIndex: 1)),
      _Entry('MAIN-05', 'ผู้ช่วย AI', () => const AppShell(initialIndex: 2)),
      _Entry('MAIN-06', 'History', () => const HistoryScreen()),
      _Entry('MAIN-07', 'Notifications', () => const NotificationsScreen()),
      _Entry('MAIN-08', 'การซิงก์ข้อมูล', () => const SyncScreen()),
      _Entry('MAIN-09', 'Device Management', () => const DeviceScreen()),
      _Entry('MAIN-10', 'Settings', () => const SettingsScreen()),
    ],
    'หน้ารอง / Task Flow (FLOW)': [
      _Entry('FLOW-01', 'Measure — Connection', () => const MeasureConnectScreen()),
      _Entry('FLOW-02', 'Measure — Ready', () => const MeasureReadyScreen()),
      _Entry('FLOW-03', 'Measure — Result', () => const MeasureResultScreen()),
      _Entry('FLOW-04', 'Create Plot', () => const CreatePlotScreen()),
      _Entry('FLOW-05', 'Draw Boundary', () => const DrawBoundaryScreen()),
      _Entry('FLOW-06', 'Plot Detail', () => const PlotDetailScreen()),
      _Entry('FLOW-07', 'Measurement Point Detail', () => PointDetailScreen(point: Mock.focusPoint)),
      _Entry('FLOW-08', 'AI ข้อสังเกต', () => const AiObservationScreen()),
      _Entry('FLOW-09', 'Compare', () => const CompareScreen()),
      _Entry('FLOW-10', 'Create / Edit Farm', () => const CreateFarmScreen()),
      _Entry('FLOW-11', 'Edit Plot', () => const EditPlotScreen(plotId: SeedIds.plotA)),
      _Entry('FLOW-12', 'Onboarding / Welcome', () => const WelcomeScreen()),
      _Entry('FLOW-13', 'Login', () => const LoginScreen()),
      _Entry('FLOW-14', 'Choose Role', () => const ChooseRoleScreen()),
      _Entry('FLOW-15', 'First Setup', () => const FirstSetupScreen()),
    ],
    'System / UX State (STATE)': [
      _Entry('STATE-01', 'Measure — Receiving', () => const MeasureReceivingScreen()),
      _Entry('STATE-02', 'Measure — Offline Saved', () => const OfflineSavedScreen()),
      _Entry('STATE-03', 'Connection Error', () => const ConnectionErrorScreen()),
      _Entry('STATE-04', 'Empty States', () => const EmptyStatesScreen()),
      _Entry('STATE-05', 'Loading States', () => const LoadingStatesScreen()),
      _Entry('STATE-06', 'Permission States', () => const PermissionsScreen()),
    ],
    'ฟีเจอร์ตามข้อเสนอโครงการ (NEW)': [
      _Entry('NEW-01', 'Sampling Plan', () => const SamplingPlanScreen()),
      _Entry('NEW-02', 'Field Navigation', () => const FieldNavScreen()),
      _Entry('NEW-03', 'Repeat Measure', () => const RepeatSummaryScreen()),
      _Entry('NEW-04', 'Reference Entry', () => const ReferenceEntryScreen()),
      _Entry('NEW-05', 'Calibration Report', () => const CalibrationScreen()),
      _Entry('NEW-06', 'Device Maintenance', () => const MaintenanceScreen()),
      _Entry('NEW-07', 'Export Report', () => const ExportScreen()),
      _Entry('NEW-08', 'Expert Review', () => const ExpertReviewScreen()),
      _Entry('NEW-09', 'Fertilizer Rules', () => const FertilizerRulesScreen()),
      _Entry('NEW-10', 'Rule Set Editor', () => const RuleSetEditScreen()),
      _Entry('NEW-11', 'Fertilizer Plan', () => const FertilizerScreen()),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'แคตตาล็อกหน้าจอ',
      children: [
        const Text('39 หน้าตาม smart_soil_ui_final_revised.svg • ข้อมูลทั้งหมดเป็นตัวอย่าง', style: TS.small),
        for (final e in sections.entries) ...[
          SectionHeader('${e.key} • ${e.value.length} หน้า'),
          for (final s in e.value)
            AppCard(
              margin: const EdgeInsets.only(bottom: 8),
              radius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => go(context, s.build()),
              child: Row(children: [
                SizedBox(width: 78, child: Pill(s.id, small: true)),
                const Gap(8),
                Expanded(child: Text(s.name, style: TS.title)),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ]),
            ),
        ],
      ],
    );
  }
}
