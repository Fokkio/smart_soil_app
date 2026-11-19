import 'dart:async';

import 'package:flutter/material.dart';

import 'farm_store.dart';
import 'fertilizer.dart';
import 'mock_data.dart';
import 'models.dart';

class FarmRepository extends ChangeNotifier {
  final FarmStore _store;
  final DateTime Function() _clock;
  final String Function()? _newId;
  StoreSnapshot _state;
  Future<void> _queue = Future<void>.value();
  int _counter = 0;

  FarmRepository(
    FarmStore store,
    StoreSnapshot initial, {
    DateTime Function()? clock,
    String Function()? newId,
  })  : _store = store,
        _state = initial,
        _clock = clock ?? DateTime.now,
        _newId = newId;

  static Future<FarmRepository> open(
    FarmStore store, {
    StoreSnapshot Function(DateTime now)? seed,
    DateTime Function()? clock,
    String Function()? newId,
  }) async {
    final now = clock ?? DateTime.now;
    var snapshot = await store.load();
    if (snapshot == null) {
      if (seed != null) {
        snapshot = seed(now());
        await store.save(snapshot);
      } else {
        snapshot = StoreSnapshot.empty();
      }
    }
    return FarmRepository(store, snapshot, clock: clock, newId: newId);
  }

  DateTime Function() get clock => _clock;

  // ---- queries ----

  List<FarmRecord> get farms => List.unmodifiable(
      [..._state.farms]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));

  FarmRecord? farm(String id) => _findFarm(_state, id);

  List<PlotRecord> plotsOf(String farmId, {bool includeArchived = false}) =>
      List.unmodifiable([
        for (final p in _state.plots)
          if (p.farmId == farmId && (includeArchived || !p.archived)) p
      ]..sort((a, b) => a.createdAt.compareTo(b.createdAt)));

  PlotRecord? plot(String id) => _findPlot(_state, id);

  List<MeasurementRound> roundsOf(String plotId) => List.unmodifiable([
        for (final r in _state.rounds)
          if (r.plotId == plotId) r
      ]..sort((a, b) => b.takenAt.compareTo(a.takenAt)));

  MeasurementRound? latestRound(String plotId) {
    final rs = roundsOf(plotId);
    return rs.isEmpty ? null : rs.first;
  }

  SoilStatus plotStatus(String plotId) =>
      latestRound(plotId)?.status ?? SoilStatus.normal;

  SoilStatus farmStatus(String farmId) =>
      worstStatus(plotsOf(farmId).map((p) => plotStatus(p.id)));

  List<CropRuleSet> get ruleSets => List.unmodifiable(
      [..._state.ruleSets]..sort((a, b) => a.crop.compareTo(b.crop)));

  CropRuleSet? ruleSetFor(String crop) => _findRuleSet(_state, crop);

  FertilizerPrices get prices => _state.prices;

  // ---- mutations ----

  Future<FarmRecord> addFarm({
    required String name,
    String caretaker = '',
    String location = '',
    String note = '',
    bool notify = true,
  }) =>
      _enqueue(() async {
        final n = _requireName(name);
        final farm = FarmRecord(
          id: _id('farm'),
          name: n,
          caretaker: caretaker,
          location: location,
          note: note,
          notify: notify,
          updatedAt: _clock(),
        );
        await _commit(_state.copyWith(
          farms: [..._state.farms, farm],
          plots: _state.plots,
          rounds: _state.rounds,
        ));
        return farm;
      });

  Future<void> updateFarm(FarmRecord farm) => _enqueue(() async {
        if (_findFarm(_state, farm.id) == null) {
          throw StateError('Farm not found: ${farm.id}');
        }
        final updated =
            farm.copyWith(name: _requireName(farm.name), updatedAt: _clock());
        await _commit(_state.copyWith(
          farms: [for (final f in _state.farms) f.id == farm.id ? updated : f],
          plots: _state.plots,
          rounds: _state.rounds,
        ));
      });

  Future<void> deleteFarm(String id) => _enqueue(() async {
        if (_findFarm(_state, id) == null) throw StateError('Farm not found: $id');
        final plotIds = {
          for (final p in _state.plots)
            if (p.farmId == id) p.id
        };
        await _commit(_state.copyWith(
          farms: [for (final f in _state.farms) if (f.id != id) f],
          plots: [for (final p in _state.plots) if (p.farmId != id) p],
          rounds: [
            for (final r in _state.rounds) if (!plotIds.contains(r.plotId)) r
          ],
        ));
      });

  Future<PlotRecord> addPlot({
    required String farmId,
    required String name,
    required String crop,
    required List<Offset> boundary,
    String note = '',
  }) =>
      _enqueue(() async {
        final n = _requireName(name);
        _requireBoundary(boundary);
        if (_findFarm(_state, farmId) == null) {
          throw StateError('Farm not found: $farmId');
        }
        final now = _clock();
        final plot = PlotRecord(
          id: _id('plot'),
          farmId: farmId,
          name: n,
          crop: crop,
          note: note,
          boundary: List.unmodifiable(boundary),
          archived: false,
          createdAt: now,
        );
        await _commit(_state.copyWith(
          farms: _touch(_state.farms, farmId, now),
          plots: [..._state.plots, plot],
          rounds: _state.rounds,
        ));
        return plot;
      });

  Future<void> updatePlot(PlotRecord plot) => _enqueue(() async {
        if (_findPlot(_state, plot.id) == null) {
          throw StateError('Plot not found: ${plot.id}');
        }
        if (_findFarm(_state, plot.farmId) == null) {
          throw StateError('Farm not found: ${plot.farmId}');
        }
        final n = _requireName(plot.name);
        _requireBoundary(plot.boundary);
        final updated = plot.copyWith(name: n);
        await _commit(_state.copyWith(
          farms: _touch(_state.farms, plot.farmId, _clock()),
          plots: [for (final p in _state.plots) p.id == plot.id ? updated : p],
          rounds: _state.rounds,
        ));
      });

  Future<void> setPlotArchived(String id, bool archived) => _enqueue(() async {
        final existing = _findPlot(_state, id);
        if (existing == null) throw StateError('Plot not found: $id');
        await _commit(_state.copyWith(
          farms: _touch(_state.farms, existing.farmId, _clock()),
          plots: [
            for (final p in _state.plots)
              p.id == id ? p.copyWith(archived: archived) : p
          ],
          rounds: _state.rounds,
        ));
      });

  Future<void> deletePlot(String id) => _enqueue(() async {
        if (_findPlot(_state, id) == null) throw StateError('Plot not found: $id');
        await _commit(_state.copyWith(
          farms: _state.farms,
          plots: [for (final p in _state.plots) if (p.id != id) p],
          rounds: [for (final r in _state.rounds) if (r.plotId != id) r],
        ));
      });

  /// API for the measuring-device team.
  Future<MeasurementRound> addRound({
    required String plotId,
    required List<SoilPoint> points,
    DateTime? takenAt,
  }) =>
      _enqueue(() async {
        final plot = _findPlot(_state, plotId);
        if (plot == null) throw StateError('Plot not found: $plotId');
        final now = _clock();
        final round = MeasurementRound(
          id: _id('round'),
          plotId: plotId,
          takenAt: takenAt ?? now,
          points: List.unmodifiable(points),
        );
        await _commit(_state.copyWith(
          farms: _touch(_state.farms, plot.farmId, now),
          plots: _state.plots,
          rounds: [..._state.rounds, round],
        ));
        return round;
      });

  /// Upsert by crop. Always stored unconfirmed: any edit needs re-confirmation.
  Future<void> saveRuleSet(CropRuleSet set) => _enqueue(() async {
        final crop = set.crop.trim();
        if (crop.isEmpty) throw ArgumentError('กรุณาเลือกชนิดพืช');
        final seen = <Nutrient>{};
        for (final r in set.rules) {
          final msg = r.validate();
          if (msg != null) throw ArgumentError(msg);
          if (!seen.add(r.nutrient)) throw ArgumentError('ธาตุซ้ำในตาราง');
        }
        final saved = set.copyWith(
          crop: crop,
          source: set.source.trim(),
          confirmedBy: '',
          clearConfirmedAt: true,
        );
        final exists = _findRuleSet(_state, crop) != null;
        await _commit(_state.copyWith(
          ruleSets: exists
              ? [for (final r in _state.ruleSets) r.crop == crop ? saved : r]
              : [..._state.ruleSets, saved],
        ));
      });

  Future<void> confirmRuleSet(String crop, String expertName) =>
      _enqueue(() async {
        final existing = _findRuleSet(_state, crop);
        if (existing == null) throw StateError('Rule set not found: $crop');
        final name = expertName.trim();
        if (name.isEmpty) throw ArgumentError('กรุณาใส่ชื่อผู้เชี่ยวชาญ');
        final confirmed = existing.copyWith(
          confirmedBy: name,
          confirmedAt: _clock(),
        );
        await _commit(_state.copyWith(ruleSets: [
          for (final r in _state.ruleSets) r.crop == crop ? confirmed : r
        ]));
      });

  Future<void> deleteRuleSet(String crop) => _enqueue(() async {
        if (_findRuleSet(_state, crop) == null) {
          throw StateError('Rule set not found: $crop');
        }
        await _commit(_state.copyWith(
          ruleSets: [for (final r in _state.ruleSets) if (r.crop != crop) r],
        ));
      });

  Future<void> setPrices(FertilizerPrices p) => _enqueue(() async {
        for (final v in [p.urea, p.tsp, p.mop]) {
          if (!v.isFinite || v < 0) throw ArgumentError('ราคาต้องไม่ติดลบ');
        }
        await _commit(_state.copyWith(prices: p));
      });

  // ---- internals ----

  /// Runs [job] after all previously queued jobs finish; a failing job does
  /// not break the chain for later ones.
  Future<T> _enqueue<T>(Future<T> Function() job) {
    final result = _queue.then((_) => job());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Persist first; only a successful save replaces state and notifies.
  Future<void> _commit(StoreSnapshot next) async {
    await _store.save(next);
    _state = next;
    notifyListeners();
  }

  String _id(String prefix) =>
      _newId?.call() ??
      '$prefix-${_clock().microsecondsSinceEpoch.toRadixString(36)}-${_counter++}';

  static String _requireName(String name) {
    final n = name.trim();
    if (n.isEmpty) throw ArgumentError.value(name, 'name', 'must not be blank');
    return n;
  }

  static void _requireBoundary(List<Offset> b) {
    if (b.length < 3) {
      throw ArgumentError.value(b, 'boundary', 'needs at least 3 points');
    }
  }

  static CropRuleSet? _findRuleSet(StoreSnapshot s, String crop) {
    for (final r in s.ruleSets) {
      if (r.crop == crop) return r;
    }
    return null;
  }

  static FarmRecord? _findFarm(StoreSnapshot s, String id) {
    for (final f in s.farms) {
      if (f.id == id) return f;
    }
    return null;
  }

  static PlotRecord? _findPlot(StoreSnapshot s, String id) {
    for (final p in s.plots) {
      if (p.id == id) return p;
    }
    return null;
  }

  static List<FarmRecord> _touch(List<FarmRecord> farms, String id, DateTime at) =>
      [for (final f in farms) f.id == id ? f.copyWith(updatedAt: at) : f];
}
