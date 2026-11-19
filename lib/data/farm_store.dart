import 'dart:convert';
import 'dart:io';

import 'fertilizer.dart';
import 'models.dart';

class StoreSnapshot {
  static const schemaVersion = 2;

  final List<FarmRecord> farms;
  final List<PlotRecord> plots;
  final List<MeasurementRound> rounds;
  final List<CropRuleSet> ruleSets;
  final FertilizerPrices prices;

  StoreSnapshot({
    required List<FarmRecord> farms,
    required List<PlotRecord> plots,
    required List<MeasurementRound> rounds,
    List<CropRuleSet> ruleSets = const [],
    this.prices = FertilizerPrices.zero,
  })  : farms = List.unmodifiable(farms),
        plots = List.unmodifiable(plots),
        rounds = List.unmodifiable(rounds),
        ruleSets = List.unmodifiable(ruleSets);

  const StoreSnapshot._empty()
      : farms = const [],
        plots = const [],
        rounds = const [],
        ruleSets = const [],
        prices = FertilizerPrices.zero;

  factory StoreSnapshot.empty() => const StoreSnapshot._empty();

  StoreSnapshot copyWith({
    List<FarmRecord>? farms,
    List<PlotRecord>? plots,
    List<MeasurementRound>? rounds,
    List<CropRuleSet>? ruleSets,
    FertilizerPrices? prices,
  }) =>
      StoreSnapshot(
        farms: farms ?? this.farms,
        plots: plots ?? this.plots,
        rounds: rounds ?? this.rounds,
        ruleSets: ruleSets ?? this.ruleSets,
        prices: prices ?? this.prices,
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'farms': [for (final f in farms) f.toJson()],
        'plots': [for (final p in plots) p.toJson()],
        'rounds': [for (final r in rounds) r.toJson()],
        'ruleSets': [for (final s in ruleSets) s.toJson()],
        'prices': prices.toJson(),
      };

  factory StoreSnapshot.fromJson(Map<String, dynamic> j) {
    final v = j['schemaVersion'];
    if (v != 1 && v != 2) {
      throw FormatException('Unsupported schemaVersion: $v');
    }
    return StoreSnapshot(
      farms: [
        for (final f in (j['farms'] as List)) FarmRecord.fromJson(f as Map<String, dynamic>)
      ],
      plots: [
        for (final p in (j['plots'] as List)) PlotRecord.fromJson(p as Map<String, dynamic>)
      ],
      rounds: [
        for (final r in (j['rounds'] as List))
          MeasurementRound.fromJson(r as Map<String, dynamic>)
      ],
      // v1 files (Phase 1) predate fertilizer data.
      ruleSets: v == 1
          ? const []
          : [
              for (final s in (j['ruleSets'] as List))
                CropRuleSet.fromJson(s as Map<String, dynamic>)
            ],
      prices: v == 1
          ? FertilizerPrices.zero
          : FertilizerPrices.fromJson(j['prices'] as Map<String, dynamic>),
    );
  }
}

abstract class FarmStore {
  /// Returns null when nothing has ever been saved (first run).
  Future<StoreSnapshot?> load();
  Future<void> save(StoreSnapshot s);
}

class MemoryFarmStore implements FarmStore {
  StoreSnapshot? _current;
  int _saveCount = 0;

  MemoryFarmStore([StoreSnapshot? initial]) : _current = initial;

  StoreSnapshot? get current => _current;
  int get saveCount => _saveCount;

  @override
  Future<StoreSnapshot?> load() async => _current;

  @override
  Future<void> save(StoreSnapshot s) async {
    _current = s;
    _saveCount++;
  }
}

class FileFarmStore implements FarmStore {
  final File file;

  FileFarmStore(this.file);

  @override
  Future<StoreSnapshot?> load() async {
    if (!await file.exists()) return null;
    try {
      final text = await file.readAsString();
      return StoreSnapshot.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } on FormatException {
      return _quarantine();
    } on TypeError {
      return _quarantine();
    } on ArgumentError {
      // e.g. SoilStatus.values.byName with an unknown status name
      return _quarantine();
    }
  }

  Future<StoreSnapshot> _quarantine() async {
    await file.rename('${file.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}');
    // Persist the empty state so the next launch doesn't look like a first run
    // and re-seed demo data over the user's (recovered-empty) store.
    final empty = StoreSnapshot.empty();
    await save(empty);
    return empty;
  }

  @override
  Future<void> save(StoreSnapshot s) async {
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(s.toJson()), flush: true);
    await tmp.rename(file.path);
  }
}
