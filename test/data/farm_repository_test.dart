import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_soil_app/data/farm_repository.dart';
import 'package:smart_soil_app/data/farm_store.dart';
import 'package:smart_soil_app/data/mock_data.dart';
import 'package:smart_soil_app/data/seed.dart';

class _FailingStore implements FarmStore {
  final StoreSnapshot snapshot;
  _FailingStore(this.snapshot);

  @override
  Future<StoreSnapshot?> load() async => snapshot;

  @override
  Future<void> save(StoreSnapshot s) async =>
      throw const FileSystemException('disk full');
}

void main() {
  late DateTime t;
  late MemoryFarmStore store;
  late FarmRepository repo;
  late int n;

  setUp(() async {
    t = DateTime(2026, 11, 19, 14, 32);
    n = 0;
    store = MemoryFarmStore();
    repo = await FarmRepository.open(
      store,
      seed: seedFromMock,
      clock: () => t,
      newId: () => 'id-${n++}',
    );
  });

  test('open seeds once when store is empty and persists it', () async {
    final store = MemoryFarmStore();
    final repo = await FarmRepository.open(store, seed: seedFromMock, clock: () => t);
    expect(repo.farms.map((f) => f.id),
        containsAll([SeedIds.farmMsu, SeedIds.farmLab, SeedIds.farm2]));
    expect(repo.plotsOf(SeedIds.farmMsu), hasLength(3));
    expect(repo.latestRound(SeedIds.plotA)!.points, hasLength(14));
    expect(repo.plotStatus(SeedIds.plotA), SoilStatus.watch);
    expect(repo.plotStatus(SeedIds.plotB), SoilStatus.normal);
    expect(store.saveCount, 1);
    expect(repo.farm(SeedIds.farmLab)!.caretaker, 'ทีมโครงการ');
    expect(repo.farms.every((f) => !f.caretaker.contains('ผู้ดูแล:')), isTrue);
    final again = await FarmRepository.open(store, seed: (_) => StoreSnapshot.empty());
    expect(again.farms, hasLength(3));
  });

  test('addFarm trims, persists, notifies, and sorts newest first', () async {
    var notified = 0;
    repo.addListener(() => notified++);
    t = t.add(const Duration(hours: 1));
    final f = await repo.addFarm(name: '  ใหม่  ');
    expect(f.name, 'ใหม่');
    expect(repo.farms.first.id, f.id);
    expect(notified, 1);
    expect(store.current!.farms.any((x) => x.id == f.id), isTrue);
  });

  test('blank farm name throws ArgumentError and changes nothing', () async {
    await expectLater(repo.addFarm(name: '   '), throwsArgumentError);
    expect(repo.farms, hasLength(3));
  });

  test('addPlot needs ≥3 boundary points and an existing farm', () async {
    await expectLater(
        repo.addPlot(
            farmId: SeedIds.farmMsu,
            name: 'D',
            crop: 'ข้าว',
            boundary: Mock.polygon.take(2).toList()),
        throwsArgumentError);
    await expectLater(
        repo.addPlot(farmId: 'nope', name: 'D', crop: 'ข้าว', boundary: Mock.polygon),
        throwsStateError);
  });

  test('archived plots are hidden unless includeArchived', () async {
    await repo.setPlotArchived(SeedIds.plotB, true);
    expect(repo.plotsOf(SeedIds.farmMsu), hasLength(2));
    expect(repo.plotsOf(SeedIds.farmMsu, includeArchived: true), hasLength(3));
  });

  test('deleteFarm cascades plots and rounds', () async {
    await repo.deleteFarm(SeedIds.farmMsu);
    expect(repo.plot(SeedIds.plotA), isNull);
    expect(repo.roundsOf(SeedIds.plotA), isEmpty);
  });

  test('addRound makes it the latest and bumps farm updatedAt', () async {
    t = t.add(const Duration(days: 1));
    await repo.addRound(plotId: SeedIds.plotC, points: [Mock.points[7]]);
    expect(repo.latestRound(SeedIds.plotC)!.status, SoilStatus.watch);
    expect(repo.farm(SeedIds.farmMsu)!.updatedAt, t);
  });

  test('failed save keeps previous state and rethrows', () async {
    final store = _FailingStore(seedFromMock(t));
    final repo = await FarmRepository.open(store);
    var notified = 0;
    repo.addListener(() => notified++);
    await expectLater(repo.addFarm(name: 'X'), throwsA(isA<FileSystemException>()));
    expect(repo.farms, hasLength(3));
    expect(notified, 0);
    // queue survives the failure
    await expectLater(repo.addFarm(name: 'Y'), throwsA(isA<FileSystemException>()));
  });

  test('concurrent mutations are serialized and both persist', () async {
    await Future.wait([repo.addFarm(name: 'A'), repo.addFarm(name: 'B')]);
    expect(store.current!.farms.map((f) => f.name), containsAll(['A', 'B']));
  });

  test('updateFarm sets updatedAt, validates name and existence', () async {
    t = t.add(const Duration(hours: 2));
    final f = repo.farm(SeedIds.farmLab)!;
    await repo.updateFarm(f.copyWith(name: ' เปลี่ยน '));
    expect(repo.farm(SeedIds.farmLab)!.name, 'เปลี่ยน');
    expect(repo.farm(SeedIds.farmLab)!.updatedAt, t);
    await expectLater(repo.updateFarm(f.copyWith(name: ' ')), throwsArgumentError);
    await expectLater(repo.updateFarm(f.copyWith(id: 'nope')), throwsStateError);
  });

  test('updatePlot validates and bumps owner farm; missing ids throw StateError', () async {
    t = t.add(const Duration(hours: 2));
    final p = repo.plot(SeedIds.plotA)!;
    await repo.updatePlot(p.copyWith(farmId: SeedIds.farmLab, name: ' Z '));
    expect(repo.plot(SeedIds.plotA)!.name, 'Z');
    expect(repo.farm(SeedIds.farmLab)!.updatedAt, t);
    await expectLater(repo.updatePlot(p.copyWith(farmId: 'nope')), throwsStateError);
    await expectLater(repo.updatePlot(p.copyWith(id: 'nope')), throwsStateError);
    await expectLater(repo.updatePlot(p.copyWith(name: '')), throwsArgumentError);
    await expectLater(
        repo.updatePlot(p.copyWith(boundary: Mock.polygon.take(2).toList())),
        throwsArgumentError);
    await expectLater(repo.setPlotArchived('nope', true), throwsStateError);
    await expectLater(repo.deletePlot('nope'), throwsStateError);
    await expectLater(repo.deleteFarm('nope'), throwsStateError);
  });

  test('deletePlot cascades rounds; farmStatus ignores archived plots', () async {
    expect(repo.farmStatus(SeedIds.farmMsu), SoilStatus.watch);
    await repo.setPlotArchived(SeedIds.plotA, true);
    expect(repo.farmStatus(SeedIds.farmMsu), SoilStatus.normal);
    await repo.deletePlot(SeedIds.plotA);
    expect(repo.roundsOf(SeedIds.plotA), isEmpty);
  });

  test('query lists are unmodifiable', () {
    expect(() => repo.farms.add(repo.farms.first), throwsUnsupportedError);
  });
}
