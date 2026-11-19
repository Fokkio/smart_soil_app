enum Nutrient { n, p, k }

String nutrientLabel(Nutrient n) => switch (n) {
      Nutrient.n => 'N',
      Nutrient.p => 'P₂O₅',
      Nutrient.k => 'K₂O',
    };

enum NutrientLevel { low, medium, high }

String levelLabel(NutrientLevel l) => switch (l) {
      NutrientLevel.low => 'ต่ำ',
      NutrientLevel.medium => 'ปานกลาง',
      NutrientLevel.high => 'สูง',
    };

/// Expert-supplied thresholds and rates for one nutrient. No defaults.
class NutrientRule {
  final Nutrient nutrient;
  final double lowBelow;
  final double highFrom;
  final double rateLow;
  final double rateMedium;
  final double rateHigh;

  const NutrientRule({
    required this.nutrient,
    required this.lowBelow,
    required this.highFrom,
    required this.rateLow,
    required this.rateMedium,
    required this.rateHigh,
  });

  NutrientLevel levelFor(double measured) {
    if (measured < lowBelow) return NutrientLevel.low;
    if (measured >= highFrom) return NutrientLevel.high;
    return NutrientLevel.medium;
  }

  double rateFor(NutrientLevel level) => switch (level) {
        NutrientLevel.low => rateLow,
        NutrientLevel.medium => rateMedium,
        NutrientLevel.high => rateHigh,
      };

  /// Thai message for the first problem, or null when valid.
  String? validate() {
    for (final x in [lowBelow, highFrom, rateLow, rateMedium, rateHigh]) {
      // isFinite also rejects NaN and "Infinity" (double.tryParse accepts it).
      if (!x.isFinite || x < 0) return 'ค่าต้องไม่ติดลบ';
    }
    if (lowBelow >= highFrom) {
      return 'เกณฑ์ "ต่ำกว่า" ต้องน้อยกว่าเกณฑ์ "สูงตั้งแต่"';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'nutrient': nutrient.name,
        'lowBelow': lowBelow,
        'highFrom': highFrom,
        'rateLow': rateLow,
        'rateMedium': rateMedium,
        'rateHigh': rateHigh,
      };

  factory NutrientRule.fromJson(Map<String, dynamic> j) => NutrientRule(
        nutrient: Nutrient.values.byName(j['nutrient'] as String),
        lowBelow: (j['lowBelow'] as num).toDouble(),
        highFrom: (j['highFrom'] as num).toDouble(),
        rateLow: (j['rateLow'] as num).toDouble(),
        rateMedium: (j['rateMedium'] as num).toDouble(),
        rateHigh: (j['rateHigh'] as num).toDouble(),
      );
}

class CropRuleSet {
  final String crop;
  final String source;
  final List<NutrientRule> rules;
  final String confirmedBy;
  final DateTime? confirmedAt;

  const CropRuleSet({
    required this.crop,
    required this.source,
    required this.rules,
    required this.confirmedBy,
    this.confirmedAt,
  });

  bool get isConfirmed => confirmedBy.trim().isNotEmpty && confirmedAt != null;

  NutrientRule? ruleFor(Nutrient n) {
    for (final r in rules) {
      if (r.nutrient == n) return r;
    }
    return null;
  }

  CropRuleSet copyWith({
    String? crop,
    String? source,
    List<NutrientRule>? rules,
    String? confirmedBy,
    DateTime? confirmedAt,
    bool clearConfirmedAt = false,
  }) =>
      CropRuleSet(
        crop: crop ?? this.crop,
        source: source ?? this.source,
        rules: rules ?? this.rules,
        confirmedBy: confirmedBy ?? this.confirmedBy,
        confirmedAt: clearConfirmedAt ? null : (confirmedAt ?? this.confirmedAt),
      );

  Map<String, dynamic> toJson() => {
        'crop': crop,
        'source': source,
        'rules': [for (final r in rules) r.toJson()],
        'confirmedBy': confirmedBy,
        'confirmedAt': confirmedAt?.toIso8601String(),
      };

  factory CropRuleSet.fromJson(Map<String, dynamic> j) => CropRuleSet(
        crop: j['crop'] as String,
        source: j['source'] as String,
        rules: [
          for (final r in (j['rules'] as List)) NutrientRule.fromJson(r as Map<String, dynamic>)
        ],
        confirmedBy: j['confirmedBy'] as String,
        confirmedAt:
            j['confirmedAt'] == null ? null : DateTime.parse(j['confirmedAt'] as String),
      );
}

/// Fertilizer prices in baht per kg.
class FertilizerPrices {
  final double urea;
  final double tsp;
  final double mop;

  const FertilizerPrices({this.urea = 0, this.tsp = 0, this.mop = 0});

  static const zero = FertilizerPrices();

  Map<String, dynamic> toJson() => {'urea': urea, 'tsp': tsp, 'mop': mop};

  factory FertilizerPrices.fromJson(Map<String, dynamic> j) => FertilizerPrices(
        urea: (j['urea'] as num).toDouble(),
        tsp: (j['tsp'] as num).toDouble(),
        mop: (j['mop'] as num).toDouble(),
      );
}
