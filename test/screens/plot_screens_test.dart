import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_soil_app/data/seed.dart';
import 'package:smart_soil_app/screens/farm_screens.dart';
import 'package:smart_soil_app/widgets/plot_map.dart';

import '../helpers.dart';

void tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('plot list shows plots of the farm and never-measured text', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const PlotListScreen(farmId: SeedIds.farmMsu)));
    expect(find.text('แปลงมันสำปะหลัง A'), findsOneWidget);
    expect(find.text('ยังไม่เคยวัด'), findsNWidgets(2));
  });

  testWidgets('plot list header has edit-farm button', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const PlotListScreen(farmId: SeedIds.farmMsu)));
    await tester.tap(find.byTooltip('แก้ไขฟาร์ม'));
    await tester.pumpAndSettle();
    expect(find.text('แก้ไขข้อมูลฟาร์มเดิม'), findsOneWidget);
  });

  testWidgets('plot list for unknown farm shows not-found', (tester) async {
    final repo = await seededRepo();
    await tester.pumpWidget(wrap(repo, const PlotListScreen(farmId: 'gone')));
    expect(find.text('ไม่พบฟาร์มนี้'), findsOneWidget);
  });

  testWidgets('plot detail shows stats from the latest round', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const PlotDetailScreen(plotId: SeedIds.plotA)));
    expect(find.text('14 จุด'), findsOneWidget);
    expect(find.text('2 จุด'), findsOneWidget);
    expect(find.text('! 2 จุดควรตรวจสอบเพิ่มเติม'), findsOneWidget);
  });

  testWidgets('plot detail with no rounds shows dashes', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const PlotDetailScreen(plotId: SeedIds.plotB)));
    expect(find.text('—'), findsNWidgets(4));
    expect(find.text('ยังไม่มีผลการวัด'), findsOneWidget);
  });

  testWidgets('create plot → draw 3 points → saved', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const CreatePlotScreen(farmId: SeedIds.farmLab)));
    await tester.enterText(find.byKey(const Key('plot-name')), 'แปลงใหม่ X');
    await tester.tap(find.text('ไปยังการวาดขอบเขต'));
    await tester.pumpAndSettle();
    // start from an empty boundary
    await tester.tap(find.text('ล้างจุด'));
    await tester.pump();
    final map = find.byType(PlotMap);
    for (final o in [const Offset(-60, -60), const Offset(60, -60), const Offset(0, 60)]) {
      await tester.tapAt(tester.getCenter(map) + o);
      await tester.pump();
    }
    await tester.tap(find.text('ใช้ขอบเขตนี้'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final plots = repo.plotsOf(SeedIds.farmLab);
    expect(plots.single.name, 'แปลงใหม่ X');
    expect(plots.single.boundary, hasLength(3));
  });

  testWidgets('blank plot name shows a message and does not navigate', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const CreatePlotScreen(farmId: SeedIds.farmLab)));
    await tester.tap(find.text('ไปยังการวาดขอบเขต'));
    await tester.pump();
    expect(find.text('กรุณาใส่ชื่อแปลง'), findsOneWidget);
    expect(find.text('วาดขอบเขตแปลง'), findsNothing);
  });

  testWidgets('create plot with no farms disables continue', (tester) async {
    final repo = await seededRepo();
    for (final f in List.of(repo.farms)) {
      await repo.deleteFarm(f.id);
    }
    tall(tester);
    await tester.pumpWidget(wrap(repo, const CreatePlotScreen()));
    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull);
    expect(find.text('ยังไม่มีฟาร์ม'), findsOneWidget);
  });

  testWidgets('edit plot saves name and crop', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const EditPlotScreen(plotId: SeedIds.plotB)));
    await tester.enterText(find.byKey(const Key('plot-name')), 'ชื่อแปลงใหม่');
    await tester.tap(find.text('บันทึกการแก้ไข'));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.plot(SeedIds.plotB)!.name, 'ชื่อแปลงใหม่');
  });

  testWidgets('archive via edit hides the plot from the list', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const EditPlotScreen(plotId: SeedIds.plotB)));
    await tester.tap(find.text('เก็บถาวร'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ยืนยัน'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.plotsOf(SeedIds.farmMsu), hasLength(2));
  });

  testWidgets('delete via edit removes the plot', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const EditPlotScreen(plotId: SeedIds.plotB)));
    await tester.tap(find.text('ลบถาวร…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบถาวร'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.plot(SeedIds.plotB), isNull);
  });

  testWidgets('unknown plot id shows not-found on detail and edit', (tester) async {
    final repo = await seededRepo();
    await tester.pumpWidget(wrap(repo, const PlotDetailScreen(plotId: 'gone')));
    expect(find.text('ไม่พบแปลงนี้'), findsOneWidget);
    await tester.pumpWidget(wrap(repo, const EditPlotScreen(plotId: 'gone')));
    expect(find.text('ไม่พบแปลงนี้'), findsOneWidget);
  });
}
