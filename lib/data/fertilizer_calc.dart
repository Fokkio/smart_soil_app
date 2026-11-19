import 'fertilizer.dart';
import 'models.dart';

/// A straight fertilizer and the fraction of its weight that is the nutrient.
class StraightFertilizer {
  final String name;
  final Nutrient nutrient;
  final double fraction;

  const StraightFertilizer(this.name, this.nutrient, this.fraction);
}

const kStraightFertilizers = [
  StraightFertilizer('ยูเรีย 46-0-0', Nutrient.n, 0.46),
  StraightFertilizer('ทริปเปิลซูเปอร์ฟอสเฟต 0-46-0', Nutrient.p, 0.46),
  StraightFertilizer('โพแทสเซียมคลอไรด์ 0-0-60', Nutrient.k, 0.60),
];

enum FertilizerIssue { noRound, noRules }

class NutrientResult {
  final Nutrient nutrient;
  final double measured;
  final NutrientLevel level;
  final double ratePerRai;

  const NutrientResult({
    required this.nutrient,
    required this.measured,
    required this.level,
    required this.ratePerRai,
  });
}

class ProductResult {
  final StraightFertilizer product;
  final double kgPerRai;
  final double totalKg;
  final double? cost;

  const ProductResult({
    required this.product,
    required this.kgPerRai,
    required this.totalKg,
    required this.cost,
  });
}

class FertilizerResult {
  final FertilizerIssue? issue;
  final List<NutrientResult> nutrients;
  final List<ProductResult> products;
  final double? totalCost;
  final bool confirmed;
  final String source;

  const FertilizerResult({
    this.issue,
    this.nutrients = const [],
    this.products = const [],
    this.totalCost,
    this.confirmed = false,
    this.source = '',
  });
}

double _priceFor(Nutrient n, FertilizerPrices p) => switch (n) {
      Nutrient.n => p.urea,
      Nutrient.p => p.tsp,
      Nutrient.k => p.mop,
    };

double? _measuredFor(Nutrient n, MeasurementRound round) => switch (n) {
      Nutrient.n => round.avg((r) => r.n.toDouble()),
      Nutrient.p => round.avg((r) => r.p.toDouble()),
      Nutrient.k => round.avg((r) => r.k.toDouble()),
    };

FertilizerResult calculateFertilizer({
  required double rai,
  required MeasurementRound? round,
  required CropRuleSet? rules,
  required FertilizerPrices prices,
}) {
  if (round == null || round.points.isEmpty) {
    return FertilizerResult(
        issue: FertilizerIssue.noRound, source: rules?.source ?? '');
  }
  if (rules == null || rules.rules.isEmpty) {
    return FertilizerResult(
        issue: FertilizerIssue.noRules, source: rules?.source ?? '');
  }

  final nutrients = <NutrientResult>[];
  final products = <ProductResult>[];
  for (final n in Nutrient.values) {
    final rule = rules.ruleFor(n);
    final measured = _measuredFor(n, round);
    if (rule == null || measured == null) continue;
    final level = rule.levelFor(measured);
    final rate = rule.rateFor(level);
    nutrients.add(NutrientResult(
        nutrient: n, measured: measured, level: level, ratePerRai: rate));

    for (final f in kStraightFertilizers.where((f) => f.nutrient == n)) {
      final kgPerRai = rate / f.fraction;
      if (kgPerRai == 0) continue;
      final totalKg = kgPerRai * rai;
      final price = _priceFor(n, prices);
      products.add(ProductResult(
        product: f,
        kgPerRai: kgPerRai,
        totalKg: totalKg,
        cost: price > 0 ? totalKg * price : null,
      ));
    }
  }

  double? totalCost = 0;
  for (final p in products) {
    final c = p.cost;
    if (c == null) {
      totalCost = null;
      break;
    }
    totalCost = totalCost! + c;
  }

  return FertilizerResult(
    nutrients: nutrients,
    products: products,
    totalCost: totalCost,
    confirmed: rules.isConfirmed,
    source: rules.source,
  );
}
