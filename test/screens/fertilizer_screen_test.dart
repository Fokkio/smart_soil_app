import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_soil_app/data/fertilizer.dart';
import 'package:smart_soil_app/data/seed.dart';
import 'package:smart_soil_app/screens/farm_screens.dart';
import 'package:smart_soil_app/screens/fertilizer_screens.dart';

import '../helpers.dart';

void tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

final rules = CropRuleSet(
  crop: 'มันสำปะหลัง',
  source: 'ค่าทดสอบ',
  confirmedBy: '',
  confirmedAt: null,
  rules: const [
    NutrientRule(nutrient: Nutrient.n, lowBelow: 20, highFrom: 40, rateLow: 10, rateMedium: 6, rateHigh: 3),
    NutrientRule(nutrient: Nutrient.p, lowBelow: 10, highFrom: 25, rateLow: 8, rateMedium: 4, rateHigh: 2),
    NutrientRule(nutrient: Nutrient.k, lowBelow: 60, highFrom: 120, rateLow: 8, rateMedium: 5, rateHigh: 2),
  ],
);

void main() {
  testWidgets('plot A with confirmed rules shows amounts and costs', (tester) async {
    final repo = await seededRepo();
    await repo.saveRuleSet(rules);
    await repo.confirmRuleSet('มันสำปะหลัง', 'ดร.ทดสอบ');
    await repo.setPrices(const FertilizerPrices(urea: 20, tsp: 25, mop: 18));
    tall(tester);
    await tester.pumpWidget(wrap(repo, const FertilizerScreen(plotId: SeedIds.plotA)));
    expect(find.text('N-P-K เป็นค่าประมาณ ยังไม่สอบเทียบ'), findsOneWidget);
    expect(find.text('ยืนยันโดย ดร.ทดสอบ'), findsOneWidget);
    expect(find.text('สูง'), findsOneWidget);
    expect(find.textContaining('6.5 กก./ไร่'), findsOneWidget);
    expect(find.textContaining('3.0 กก./ไร่'), findsOneWidget);
    expect(find.textContaining('ต้นทุนรวม'), findsOneWidget);
    expect(find.text('ต้นทุนรวม —'), findsNothing);
  });

  testWidgets('unconfirmed rules show the red warning', (tester) async {
    final repo = await seededRepo();
    await repo.saveRuleSet(rules);
    tall(tester);
    await tester.pumpWidget(wrap(repo, const FertilizerScreen(plotId: SeedIds.plotA)));
    expect(find.text('ตารางอัตราปุ๋ยยังไม่ผ่านการยืนยันจากผู้เชี่ยวชาญ'), findsOneWidget);
  });

  testWidgets('no price shows dash for total', (tester) async {
    final repo = await seededRepo();
    await repo.saveRuleSet(rules);
    tall(tester);
    await tester.pumpWidget(wrap(repo, const FertilizerScreen(plotId: SeedIds.plotA)));
    expect(find.text('ต้นทุนรวม —'), findsOneWidget);
  });

  testWidgets('plot without round explains and shows no amounts', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const FertilizerScreen(plotId: SeedIds.plotB)));
    expect(find.text('ยังไม่มีผลการวัด'), findsOneWidget);
    expect(find.textContaining('กก./ไร่'), findsNothing);
  });

  testWidgets('unknown plot shows not-found', (tester) async {
    final repo = await seededRepo();
    await tester.pumpWidget(wrap(repo, const FertilizerScreen(plotId: 'nope')));
    expect(find.text('ไม่พบแปลงนี้'), findsOneWidget);
  });

  testWidgets('crop without table links to rules screen', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const FertilizerScreen(plotId: SeedIds.plotA)));
    expect(find.textContaining('ยังไม่มีตารางอัตราปุ๋ยของ'), findsOneWidget);
    expect(find.textContaining('กก./ไร่'), findsNothing);
    await tester.tap(find.text('ไปที่ตารางอัตราปุ๋ย'));
    await tester.pumpAndSettle();
    expect(find.text('ตารางอัตราปุ๋ย'), findsOneWidget);
  });

  testWidgets('plot detail opens fertilizer screen', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const PlotDetailScreen(plotId: SeedIds.plotA)));
    await tester.tap(find.text('คำนวณปุ๋ย'));
    await tester.pumpAndSettle();
    expect(find.text('ปุ๋ยที่ควรใส่'), findsOneWidget);
  });
}
