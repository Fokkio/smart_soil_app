import 'package:flutter_test/flutter_test.dart';
import 'package:smart_soil_app/data/fertilizer.dart';
import 'package:smart_soil_app/data/fertilizer_calc.dart';
import 'package:smart_soil_app/data/mock_data.dart';
import 'package:smart_soil_app/data/models.dart';

void main() {
  final round = MeasurementRound(
      id: 'r', plotId: 'p', takenAt: DateTime(2026), points: Mock.points);
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

  test('levels, straight-fertilizer amounts and costs', () {
    final r = calculateFertilizer(
        rai: 10,
        round: round,
        rules: rules,
        prices: const FertilizerPrices(urea: 20, tsp: 25, mop: 18));
    expect(r.issue, isNull);
    expect(r.nutrients.map((x) => x.level),
        [NutrientLevel.high, NutrientLevel.medium, NutrientLevel.low]);
    expect(r.products[0].kgPerRai, closeTo(6.5217, 1e-3));
    expect(r.products[1].totalKg, closeTo(86.9565, 1e-3));
    expect(r.products[2].totalKg, closeTo(133.3333, 1e-3));
    expect(r.totalCost, closeTo(5878.26, 0.01));
    expect(r.confirmed, isFalse);
    expect(r.source, 'ค่าทดสอบ');
  });

  test('missing price gives null cost and null total', () {
    final r = calculateFertilizer(
        rai: 10,
        round: round,
        rules: rules,
        prices: const FertilizerPrices(urea: 20));
    expect(r.products[0].cost, closeTo(1304.35, 0.01));
    expect(r.products[1].cost, isNull);
    expect(r.totalCost, isNull);
  });

  test('no round → noRound; no rules → noRules', () {
    const prices = FertilizerPrices.zero;
    expect(
        calculateFertilizer(rai: 1, round: null, rules: null, prices: prices).issue,
        FertilizerIssue.noRound);
    expect(
        calculateFertilizer(rai: 1, round: null, rules: rules, prices: prices).issue,
        FertilizerIssue.noRound);
    final empty = MeasurementRound(id: 'e', plotId: 'p', takenAt: DateTime(2026), points: const []);
    expect(
        calculateFertilizer(rai: 1, round: empty, rules: rules, prices: prices).issue,
        FertilizerIssue.noRound);
    expect(
        calculateFertilizer(rai: 1, round: round, rules: null, prices: prices).issue,
        FertilizerIssue.noRules);
    final r = calculateFertilizer(
        rai: 1,
        round: round,
        rules: const CropRuleSet(crop: 'x', source: 's', rules: [], confirmedBy: ''),
        prices: prices);
    expect(r.issue, FertilizerIssue.noRules);
    expect(r.nutrients, isEmpty);
    expect(r.products, isEmpty);
    expect(r.totalCost, isNull);
  });

  test('nutrient without a rule and zero rate are skipped', () {
    final r = calculateFertilizer(
        rai: 10,
        round: round,
        rules: rules.copyWith(rules: const [
          NutrientRule(nutrient: Nutrient.n, lowBelow: 20, highFrom: 40, rateLow: 10, rateMedium: 6, rateHigh: 0),
        ]),
        prices: const FertilizerPrices(urea: 20, tsp: 25, mop: 18));
    expect(r.issue, isNull);
    expect(r.nutrients.length, 1);
    expect(r.products, isEmpty);
    expect(r.totalCost, 0);
  });
}
