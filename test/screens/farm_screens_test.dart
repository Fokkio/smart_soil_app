import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_soil_app/data/seed.dart';
import 'package:smart_soil_app/screens/farm_screens.dart';

import '../helpers.dart';

void main() {
  testWidgets('farm list shows repository farms with plot counts', (tester) async {
    final repo = await seededRepo();
    await tester.pumpWidget(wrap(repo, const FarmListScreen()));
    expect(find.text('ทั้งหมด 3 ฟาร์ม'), findsOneWidget);
    expect(find.text('3 แปลง'), findsOneWidget);
    expect(find.text('0 แปลง'), findsNWidgets(2));
  });

  testWidgets('creating a farm persists it', (tester) async {
    final repo = await seededRepo();
    await tester.pumpWidget(wrap(repo, const CreateFarmScreen()));
    await tester.enterText(find.byKey(const Key('farm-name')), 'ฟาร์มทดสอบ');
    await tester.tap(find.text('บันทึกฟาร์ม'));
    await tester.pumpAndSettle();
    // The fixed test clock ties with the seed timestamps, so assert membership.
    expect(repo.farms.length, 4);
    expect(repo.farms.any((f) => f.name == 'ฟาร์มทดสอบ'), isTrue);
  });

  testWidgets('blank farm name shows a message and saves nothing', (tester) async {
    final repo = await seededRepo();
    await tester.pumpWidget(wrap(repo, const CreateFarmScreen()));
    await tester.enterText(find.byKey(const Key('farm-name')), '   ');
    await tester.tap(find.text('บันทึกฟาร์ม'));
    await tester.pump();
    expect(find.text('กรุณาใส่ชื่อฟาร์ม'), findsOneWidget);
    expect(repo.farms.length, 3);
  });

  testWidgets('editing pre-fills and delete removes the farm', (tester) async {
    final repo = await seededRepo();
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(repo, const CreateFarmScreen(farmId: SeedIds.farmLab)));
    expect(find.widgetWithText(TextField, 'จุดสอบเทียบ (แล็บ)'), findsOneWidget);
    await tester.tap(find.text('ลบฟาร์ม…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบถาวร'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.farm(SeedIds.farmLab), isNull);
  });

  testWidgets('editing saves changes to the existing farm', (tester) async {
    final repo = await seededRepo();
    await tester.pumpWidget(wrap(repo, const CreateFarmScreen(farmId: SeedIds.farmLab)));
    await tester.enterText(find.byKey(const Key('farm-name')), 'ชื่อใหม่');
    await tester.tap(find.text('บันทึกฟาร์ม'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.farm(SeedIds.farmLab)!.name, 'ชื่อใหม่');
    expect(repo.farms.length, 3);
  });

  testWidgets('unknown farm id shows not-found', (tester) async {
    final repo = await seededRepo();
    await tester.pumpWidget(wrap(repo, const CreateFarmScreen(farmId: 'gone')));
    expect(find.text('ไม่พบฟาร์มนี้'), findsOneWidget);
  });
}
