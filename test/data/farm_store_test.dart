import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_soil_app/data/farm_store.dart';
import 'package:smart_soil_app/data/mock_data.dart';
import 'package:smart_soil_app/data/models.dart';

FarmRecord farm(String id) => FarmRecord(
      id: id,
      name: 'Farm $id',
      caretaker: 'Somchai',
      location: 'Chiang Mai',
      note: 'note',
      notify: true,
      updatedAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
    );

PlotRecord plot(String id, String farmId) => PlotRecord(
      id: id,
      farmId: farmId,
      name: 'Plot $id',
      crop: 'Rice',
      note: '',
      boundary: Mock.polygon,
      archived: false,
      createdAt: DateTime.utc(2026, 1, 1),
    );

MeasurementRound round(String id, String plotId) => MeasurementRound(
      id: id,
      plotId: plotId,
      takenAt: DateTime.utc(2026, 1, 3),
      points: Mock.points,
    );

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('soil');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('missing file loads as null', () async {
    expect(await FileFarmStore(File('${dir.path}/s.json')).load(), isNull);
  });

  test('save then load returns the same snapshot', () async {
    final store = FileFarmStore(File('${dir.path}/s.json'));
    final snap = StoreSnapshot(
        farms: [farm('f1')], plots: [plot('p1', 'f1')], rounds: [round('r1', 'p1')]);
    await store.save(snap);
    expect((await store.load())!.toJson(), snap.toJson());
    expect(File('${dir.path}/s.json.tmp').existsSync(), isFalse);
  });

  test('save overwrites an existing file and creates parent directories', () async {
    final store = FileFarmStore(File('${dir.path}/a/b/s.json'));
    await store.save(StoreSnapshot.empty());
    await store.save(StoreSnapshot(farms: [farm('f2')], plots: const [], rounds: const []));
    expect((await store.load())!.farms.single.id, 'f2');
  });

  test('corrupt file is backed up and loads as empty, not null', () async {
    final f = File('${dir.path}/s.json')..writeAsStringSync('{"schemaVersion":1,"farms":[{');
    final snap = await FileFarmStore(f).load();
    expect(snap, isNotNull);
    expect(snap!.farms, isEmpty);
    expect(f.existsSync(), isFalse);
    expect(dir.listSync().whereType<File>().where((e) => e.path.contains('.corrupt-')),
        hasLength(1));
  });

  test('wrong-shaped JSON is treated as corrupt', () async {
    final f = File('${dir.path}/s.json')
      ..writeAsStringSync('{"schemaVersion":1,"farms":[{"id":5}],"plots":[],"rounds":[]}');
    expect((await FileFarmStore(f).load())!.farms, isEmpty);
    expect(f.existsSync(), isFalse);
  });

  test('unknown soil status name is treated as corrupt', () async {
    final store = FileFarmStore(File('${dir.path}/s.json'));
    await store.save(StoreSnapshot(farms: const [], plots: const [], rounds: [
      MeasurementRound(id: 'r', plotId: 'p', takenAt: DateTime(2026), points: [Mock.points.first]),
    ]));
    final f = File('${dir.path}/s.json');
    f.writeAsStringSync(f.readAsStringSync().replaceFirst('"normal"', '"bogus"'));
    expect((await store.load())!.rounds, isEmpty);
    expect(f.existsSync(), isFalse);
  });

  test('unknown schemaVersion is treated as corrupt', () async {
    final f = File('${dir.path}/s.json')
      ..writeAsStringSync('{"schemaVersion":99,"farms":[],"plots":[],"rounds":[]}');
    expect((await FileFarmStore(f).load())!.farms, isEmpty);
  });

  test('StoreSnapshot.fromJson throws FormatException on bad schemaVersion', () {
    expect(() => StoreSnapshot.fromJson({'farms': [], 'plots': [], 'rounds': []}),
        throwsFormatException);
    expect(
        () => StoreSnapshot.fromJson(
            {'schemaVersion': 2, 'farms': [], 'plots': [], 'rounds': []}),
        throwsFormatException);
  });

  test('MemoryFarmStore keeps the last saved snapshot', () async {
    final m = MemoryFarmStore();
    expect(await m.load(), isNull);
    await m.save(StoreSnapshot.empty());
    expect(m.saveCount, 1);
    expect(await m.load(), isNotNull);
    expect(m.current, isNotNull);
  });
}
