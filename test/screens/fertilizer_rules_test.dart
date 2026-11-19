import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_soil_app/data/fertilizer.dart';
import 'package:smart_soil_app/screens/fertilizer_screens.dart';
import 'package:smart_soil_app/widgets/common.dart';

import '../helpers.dart';

void tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> toggleOff(WidgetTester tester, Nutrient n) async {
  await tester.tap(find.descendant(
    of: find.widgetWithText(ToggleCard, 'ใช้ธาตุ ${nutrientLabel(n)}'),
    matching: find.byType(Switch),
  ));
  await tester.pump();
}

Future<void> fill(WidgetTester tester, String key, String v) async {
  await tester.enterText(find.byKey(Key(key)), v);
}

const _rule = NutrientRule(
  nutrient: Nutrient.n,
  lowBelow: 20,
  highFrom: 40,
  rateLow: 10,
  rateMedium: 6,
  rateHigh: 3,
);

void main() {
  testWidgets('add a rule set for rice, then it is listed as unconfirmed', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const RuleSetEditScreen()));
    await tester.tap(find.text('มันสำปะหลัง'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ข้าว'));
    await tester.pumpAndSettle();
    await fill(tester, 'rule-source', 'ทดสอบ');
    await toggleOff(tester, Nutrient.p);
    await toggleOff(tester, Nutrient.k);
    await fill(tester, 'n-lowBelow', '20');
    await fill(tester, 'n-highFrom', '40');
    await fill(tester, 'n-rateLow', '10');
    await fill(tester, 'n-rateMedium', '6');
    await fill(tester, 'n-rateHigh', '3');
    await tester.tap(find.text('บันทึกตาราง'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final set = repo.ruleSetFor('ข้าว')!;
    expect(set.rules, hasLength(1));
    expect(set.ruleFor(Nutrient.n)!.rateHigh, 3);
    expect(set.isConfirmed, isFalse);
  });

  testWidgets('empty field shows a message and saves nothing', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const RuleSetEditScreen()));
    await toggleOff(tester, Nutrient.p);
    await toggleOff(tester, Nutrient.k);
    await fill(tester, 'n-lowBelow', '20');
    await fill(tester, 'n-highFrom', '40');
    await fill(tester, 'n-rateLow', '10');
    await fill(tester, 'n-rateMedium', '6');
    await tester.tap(find.text('บันทึกตาราง'));
    await tester.pump();
    expect(find.text('กรอกตัวเลขให้ครบทุกช่อง'), findsOneWidget);
    expect(repo.ruleSets, isEmpty);
  });

  testWidgets('inverted thresholds show the repository message', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const RuleSetEditScreen()));
    await toggleOff(tester, Nutrient.p);
    await toggleOff(tester, Nutrient.k);
    await fill(tester, 'n-lowBelow', '50');
    await fill(tester, 'n-highFrom', '40');
    await fill(tester, 'n-rateLow', '10');
    await fill(tester, 'n-rateMedium', '6');
    await fill(tester, 'n-rateHigh', '3');
    await tester.tap(find.text('บันทึกตาราง'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('น้อยกว่า'), findsOneWidget);
    expect(repo.ruleSets, isEmpty);
  });

  testWidgets('expert confirms a rule set', (tester) async {
    final repo = await seededRepo();
    await repo.saveRuleSet(const CropRuleSet(
        crop: 'มันสำปะหลัง', source: 'ทดสอบ', rules: [_rule], confirmedBy: ''));
    tall(tester);
    await tester.pumpWidget(wrap(repo, const RuleSetEditScreen(crop: 'มันสำปะหลัง')));
    expect(find.text('ยังไม่ผ่านการยืนยัน'), findsOneWidget);
    await tester.tap(find.text('ยืนยันตาราง (ผู้เชี่ยวชาญ)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expert-name')), 'ดร.สมชาย');
    await tester.tap(find.text('ยืนยัน'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final set = repo.ruleSetFor('มันสำปะหลัง')!;
    expect(set.isConfirmed, isTrue);
    expect(set.confirmedBy, 'ดร.สมชาย');
  });

  testWidgets('edit mode pre-fills fields from the stored set', (tester) async {
    final repo = await seededRepo();
    await repo.saveRuleSet(const CropRuleSet(
        crop: 'ข้าว', source: 'ทดสอบ', rules: [_rule], confirmedBy: ''));
    tall(tester);
    await tester.pumpWidget(wrap(repo, const RuleSetEditScreen(crop: 'ข้าว')));
    expect(tester.widget<TextField>(find.byKey(const Key('n-lowBelow'))).controller!.text, '20');
    expect(find.byKey(const Key('p-lowBelow')), findsNothing);
  });

  testWidgets('delete removes the rule set', (tester) async {
    final repo = await seededRepo();
    await repo.saveRuleSet(const CropRuleSet(
        crop: 'ข้าว', source: 'ทดสอบ', rules: [_rule], confirmedBy: ''));
    tall(tester);
    await tester.pumpWidget(wrap(repo, const RuleSetEditScreen(crop: 'ข้าว')));
    await tester.tap(find.text('ลบตาราง'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.ruleSetFor('ข้าว'), isNull);
  });

  testWidgets('prices: blank saves as 0', (tester) async {
    final repo = await seededRepo();
    tall(tester);
    await tester.pumpWidget(wrap(repo, const FertilizerRulesScreen()));
    expect(find.text('ยังไม่มีตารางอัตราปุ๋ย'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('price-urea')), '20');
    await tester.tap(find.text('บันทึกราคา'));
    await tester.pump();
    await tester.pump();
    expect(repo.prices.urea, 20);
    expect(repo.prices.tsp, 0);
    expect(repo.prices.mop, 0);
  });
}
