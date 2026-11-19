import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_soil_app/main.dart';
import 'package:smart_soil_app/screens/catalog.dart';

import 'helpers.dart';

void main() {
  testWidgets('Welcome screen renders and opens login', (tester) async {
    await tester.pumpWidget(SmartSoilApp(repository: await seededRepo()));
    expect(find.text('Smart Soil'), findsOneWidget);
    await tester.tap(find.text('เริ่มต้นใช้งาน'));
    await tester.pumpAndSettle();
    expect(find.text('ยินดีต้อนรับกลับ'), findsOneWidget);
  });

  testWidgets('Every catalog screen builds without exceptions', (tester) async {
    final repo = await seededRepo();
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    for (final entries in CatalogScreen.sections.values) {
      for (final e in entries) {
        await tester.pumpWidget(wrap(repo, e.build()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: e.id);
      }
    }
    // let periodic timers (receiving screen) finish
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
