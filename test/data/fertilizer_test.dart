import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_soil_app/data/fertilizer.dart';

void main() {
  const n = NutrientRule(
      nutrient: Nutrient.n, lowBelow: 20, highFrom: 40, rateLow: 10, rateMedium: 6, rateHigh: 3);

  test('labels', () {
    expect(nutrientLabel(Nutrient.p), 'P₂O₅');
    expect(nutrientLabel(Nutrient.k), 'K₂O');
    expect(levelLabel(NutrientLevel.medium), 'ปานกลาง');
  });

  test('levelFor uses < lowBelow and >= highFrom', () {
    expect(n.levelFor(19.9), NutrientLevel.low);
    expect(n.levelFor(20), NutrientLevel.medium);
    expect(n.levelFor(40), NutrientLevel.high);
    expect(n.rateFor(NutrientLevel.medium), 6);
  });

  test('validate rejects infinity (double.tryParse accepts "Infinity")', () {
    expect(
        NutrientRule(
                nutrient: Nutrient.n,
                lowBelow: 1,
                highFrom: double.tryParse('Infinity')!,
                rateLow: 1,
                rateMedium: 1,
                rateHigh: 1)
            .validate(),
        'ค่าต้องไม่ติดลบ');
  });

  test('validate rejects negatives and inverted thresholds', () {
    expect(n.validate(), isNull);
    expect(
        const NutrientRule(
                nutrient: Nutrient.n,
                lowBelow: 40,
                highFrom: 40,
                rateLow: 1,
                rateMedium: 1,
                rateHigh: 1)
            .validate(),
        isNotNull);
    expect(
        const NutrientRule(
                nutrient: Nutrient.n,
                lowBelow: 1,
                highFrom: 2,
                rateLow: -1,
                rateMedium: 1,
                rateHigh: 1)
            .validate(),
        'ค่าต้องไม่ติดลบ');
    expect(
        NutrientRule(
                nutrient: Nutrient.n,
                lowBelow: double.nan,
                highFrom: 2,
                rateLow: 1,
                rateMedium: 1,
                rateHigh: 1)
            .validate(),
        'ค่าต้องไม่ติดลบ');
  });

  test('CropRuleSet round-trips and reports confirmation', () {
    final s = CropRuleSet(
        crop: 'ข้าว',
        source: 'ทดสอบ',
        rules: const [n],
        confirmedBy: 'ดร.ทดสอบ',
        confirmedAt: DateTime(2026, 11, 19));
    final back = CropRuleSet.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
    expect(back.toJson(), s.toJson());
    expect(back.isConfirmed, isTrue);
    expect(back.copyWith(confirmedBy: '').isConfirmed, isFalse);
    expect(back.copyWith(clearConfirmedAt: true).isConfirmed, isFalse);
    expect(back.ruleFor(Nutrient.k), isNull);
    expect(back.ruleFor(Nutrient.n), isNotNull);
  });

  test('unconfirmed CropRuleSet round-trips', () {
    const s = CropRuleSet(crop: 'x', source: '', rules: [], confirmedBy: '');
    final back = CropRuleSet.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
    expect(back.confirmedAt, isNull);
    expect(back.isConfirmed, isFalse);
  });

  test('FertilizerPrices round-trips', () {
    const p = FertilizerPrices(urea: 20, tsp: 30, mop: 40);
    final back = FertilizerPrices.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
    expect(back.toJson(), p.toJson());
    expect(FertilizerPrices.zero.urea, 0);
  });
}
