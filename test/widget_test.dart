import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_soil_app/main.dart';
import 'package:smart_soil_app/screens/catalog.dart';

void main() {
  testWidgets('Welcome screen renders and opens login', (tester) async {
    await tester.pumpWidget(const SmartSoilApp());
    expect(find.text('Smart Soil'), findsOneWidget);
    await tester.tap(find.text('เริ่มต้นใช้งาน'));
    await tester.pumpAndSettle();
    expect(find.text('ยินดีต้อนรับกลับ'), findsOneWidget);
  });

  testWidgets('Every catalog screen builds without exceptions', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    for (final entries in CatalogScreen.sections.values) {
      for (final e in entries) {
        await tester.pumpWidget(MaterialApp(home: e.build()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: e.id);
      }
    }
    // let periodic timers (receiving screen) finish
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
