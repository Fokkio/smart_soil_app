# Phase 1 — Data Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> **Execution (ตกลงกับผู้ใช้แล้ว):** implementer = subagent `model: "sonnet"` ทีละ task ตามลำดับ (ทุก task ต้องรอ task ก่อนหน้า), reviewer = Opus 5.5 หลังจบแต่ละ task และรีวิวรวมท้าย phase

**Goal:** ฟาร์ม แปลง และผลวัด เก็บจริงในเครื่อง (JSON) และหน้าฟาร์ม/แปลงอ่าน-เขียนข้อมูลจริงแทน `Mock`

**Architecture:** โมเดลที่มี id + JSON codec (`models.dart`) → `FarmStore` (อ่าน/เขียน snapshot ทั้งก้อน, มีแบบ memory สำหรับ test และแบบไฟล์) → `FarmRepository extends ChangeNotifier` (query + mutation + validation) → `AppScope` (`InheritedNotifier`) ครอบ `MaterialApp` ให้ทุกหน้าเรียก `AppScope.of(context)`

**Tech Stack:** Flutter 3.44 / Dart ≥ 3.4, `flutter_test`, `path_provider`

**Spec:** `docs/superpowers/specs/2026-11-19-smart-soil-feature-roadmap.md` (หัวข้อ "Requirements ของ Phase 1", R1–R9)

## Global Constraints

- package ใหม่ได้แค่ `path_provider: ^2.1.5` (R8); ห้ามเพิ่ม provider/riverpod/bloc (R7)
- ห้ามแก้หรือลบ class เดิมใน `lib/data/mock_data.dart` (`Farm`, `Plot`, `SoilPoint`, `Reading`, `HistoryRound`, `Mock`) — หน้าอื่นยังใช้อยู่ (R6); เพิ่มของใหม่ในไฟล์ใหม่
- ข้อความ UI ภาษาไทย ใช้ widget เดิมจาก `lib/widgets/common.dart` (`AppCard`, `Pill`, `InfoBox`, `toast`, `confirm`, `go`, `ScreenScaffold`…) และสไตล์จาก `lib/theme.dart`
- ทุก task จบด้วย `flutter analyze` (No issues found) และ `flutter test` (All tests passed) ก่อน commit (R9)
- commit message ลงท้ายด้วย `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`

## Review Focus

1. ไฟล์ JSON เสีย (แอปดับกลางการเขียน / แก้มือ) → แอปต้องเปิดได้ ไม่ crash, สำรองไฟล์เสียไว้ ไม่เขียนทับ (Task 2)
2. เขียนไฟล์ล้มเหลว (ดิสก์เต็ม/permission) → ข้อมูลในหน้าจอต้องไม่เปลี่ยน และผู้ใช้เห็นข้อความผิดพลาด (Task 3 rollback, Task 5/6 แสดง toast)
3. ชื่อว่าง / มีแต่ช่องว่าง → ไม่บันทึก และบอกผู้ใช้ (Task 3 validation, Task 5/6 UI)
4. เปิดหน้าด้วย id ที่ถูกลบไปแล้ว (เช่นจากแคตตาล็อก Demo หลังลบแปลงตัวอย่าง) → แสดง "ไม่พบ…" ไม่ crash (Task 5/6)
5. กดบันทึกรัวๆ สองครั้ง → การเขียนไฟล์ต้องเรียงกัน ไม่ทับกันจนข้อมูลหาย (Task 3 serialize writes)

---

## File Structure

| ไฟล์ | หน้าที่ |
|---|---|
| Create `lib/data/models.dart` | `FarmRecord`, `PlotRecord`, `MeasurementRound`, codec ของ `Reading`/`SoilPoint`, `worstStatus`, `formatWhen` |
| Create `lib/data/farm_store.dart` | `StoreSnapshot`, `FarmStore`, `MemoryFarmStore`, `FileFarmStore` |
| Create `lib/data/seed.dart` | `SeedIds`, `seedFromMock()` |
| Create `lib/data/farm_repository.dart` | `FarmRepository` |
| Create `lib/data/app_scope.dart` | `AppScope` |
| Modify `lib/main.dart` | เปิด repository จากไฟล์ แล้ว `runApp` |
| Modify `lib/screens/farm_screens.dart` | ต่อ 7 หน้ากับ repository |
| Modify `lib/screens/catalog.dart` | constructor ใหม่ของหน้าแปลง |
| Create `test/helpers.dart`, `test/data/*_test.dart`, `test/screens/farm_screens_test.dart` | tests |
| Modify `test/widget_test.dart` | ครอบด้วย `AppScope` |

---

### Task 1: Models, JSON codec, formatting

**Files:**
- Create: `lib/data/models.dart`
- Test: `test/data/models_test.dart`

**Interfaces:**
- Consumes: `SoilStatus`, `Reading`, `SoilPoint` จาก `lib/data/mock_data.dart`
- Produces:
  - `class FarmRecord { final String id, name, caretaker, location, note; final bool notify; final DateTime updatedAt; }` — ctor named+required ทุกตัว, `copyWith({...})`, `Map<String, dynamic> toJson()`, `factory FarmRecord.fromJson(Map<String, dynamic>)`
  - `class PlotRecord { final String id, farmId, name, crop, note; final List<Offset> boundary; final bool archived; final DateTime createdAt; double get rai; }` — `rai` = `Mock.areaRai(boundary)`; `copyWith`, `toJson`, `fromJson`
  - `class MeasurementRound { final String id, plotId; final DateTime takenAt; final List<SoilPoint> points; SoilStatus get status; int get watchCount; double? avg(double Function(Reading r) f); }` — `status` = `worstStatus(points.map((p) => p.status))`; `watchCount` = จำนวนจุดที่ไม่ใช่ normal; `avg` คืน null ถ้าไม่มีจุด; `toJson`, `fromJson`
  - `Map<String, dynamic> readingToJson(Reading)`, `Reading readingFromJson(Map<String, dynamic>)`, `Map<String, dynamic> soilPointToJson(SoilPoint)`, `SoilPoint soilPointFromJson(Map<String, dynamic>)`
  - `SoilStatus worstStatus(Iterable<SoilStatus> s)` — ลำดับ normal < watch < check; ว่าง → normal
  - `String formatWhen(DateTime t, DateTime now)`

JSON: `DateTime` เป็น ISO-8601 string, `Offset` เป็น `[dx, dy]`, `SoilStatus` เป็น `name` (`"normal"`)

- [ ] **Step 1: Write the failing tests** ใน `test/data/models_test.dart`

```dart
test('FarmRecord round-trips through JSON', () {
  final f = FarmRecord(id: 'f1', name: 'ฟาร์ม ก', caretaker: 'ทีม', location: 'มหาสารคาม',
      note: '', notify: true, updatedAt: DateTime(2026, 11, 19, 14, 32));
  final back = FarmRecord.fromJson(jsonDecode(jsonEncode(f.toJson())));
  expect(back.toJson(), f.toJson());
});
test('PlotRecord round-trips and computes rai from boundary', () {
  final p = PlotRecord(id: 'p1', farmId: 'f1', name: 'A', crop: 'ข้าว', note: '',
      boundary: Mock.polygon, archived: false, createdAt: DateTime(2026, 1, 1));
  final back = PlotRecord.fromJson(jsonDecode(jsonEncode(p.toJson())));
  expect(back.boundary, Mock.polygon);
  expect(back.rai, closeTo(Mock.areaRai(Mock.polygon), 1e-9));
});
test('MeasurementRound round-trips with all reading fields', () {
  final r = MeasurementRound(id: 'r1', plotId: 'p1', takenAt: DateTime(2026, 11, 19), points: Mock.points);
  final back = MeasurementRound.fromJson(jsonDecode(jsonEncode(r.toJson())));
  expect(back.points.length, 14);
  expect(back.points[7].id, '#08');
  expect(back.points[7].status, SoilStatus.watch);
  expect(back.points[7].r.moisture, 22);
  expect(back.points[7].r.k, 56);
  expect(back.points[7].pos, const Offset(0.42, 0.78));
});
test('round status is the worst point status; watchCount counts non-normal', () {
  final r = MeasurementRound(id: 'r', plotId: 'p', takenAt: DateTime(2026), points: Mock.points);
  expect(r.status, SoilStatus.watch);
  expect(r.watchCount, 2);
  expect(worstStatus([]), SoilStatus.normal);
  expect(worstStatus([SoilStatus.watch, SoilStatus.check, SoilStatus.normal]), SoilStatus.check);
});
test('avg is null for an empty round', () {
  final r = MeasurementRound(id: 'r', plotId: 'p', takenAt: DateTime(2026), points: const []);
  expect(r.avg((x) => x.moisture), isNull);
});
test('formatWhen', () {
  final now = DateTime(2026, 11, 19, 18, 0);
  expect(formatWhen(DateTime(2026, 11, 19, 14, 32), now), 'วันนี้ 14:32');
  expect(formatWhen(DateTime(2026, 11, 18, 9, 5), now), 'เมื่อวาน 09:05');
  expect(formatWhen(DateTime(2026, 11, 15, 9, 5), now), '4 วันก่อน');
  expect(formatWhen(DateTime(2026, 9, 30, 9, 10), now), '30 ก.ย. 2569');
});
```

- [ ] **Step 2: Run** `flutter test test/data/models_test.dart` — Expected: FAIL (compile error, `models.dart` ไม่มี)
- [ ] **Step 3: Implement `lib/data/models.dart`** ตาม Interfaces. `formatWhen`: เทียบ "วันที่" (ตัดเวลาออก) — 0 วัน → `วันนี้ HH:mm`, 1 → `เมื่อวาน HH:mm`, 2–6 → `N วันก่อน`, อื่น ๆ → `d <เดือนย่อไทย> <ปี พ.ศ.>` ใช้ลิสต์ `ม.ค. ก.พ. มี.ค. เม.ย. พ.ค. มิ.ย. ก.ค. ส.ค. ก.ย. ต.ค. พ.ย. ธ.ค.`, ปี = ค.ศ. + 543
- [ ] **Step 4: Run** `flutter test test/data/models_test.dart` — Expected: PASS
- [ ] **Step 5: Commit** `feat(data): add persistent models and JSON codec`

---

### Task 2: Stores (memory + file)

**Files:**
- Create: `lib/data/farm_store.dart`
- Test: `test/data/farm_store_test.dart`

**Interfaces:**
- Consumes: Task 1 models
- Produces:
  - `class StoreSnapshot { static const schemaVersion = 1; final List<FarmRecord> farms; final List<PlotRecord> plots; final List<MeasurementRound> rounds; const StoreSnapshot({...required}); factory StoreSnapshot.empty(); Map<String, dynamic> toJson(); factory StoreSnapshot.fromJson(Map<String, dynamic>); }` — JSON มี key `"schemaVersion": 1`; `fromJson` โยน `FormatException` ถ้า schemaVersion ไม่ใช่ 1
  - `abstract class FarmStore { Future<StoreSnapshot?> load(); Future<void> save(StoreSnapshot s); }` — `load` คืน `null` = ยังไม่เคยมีข้อมูล (ครั้งแรก)
  - `class MemoryFarmStore implements FarmStore { MemoryFarmStore([StoreSnapshot? initial]); StoreSnapshot? get current; int saveCount; }`
  - `class FileFarmStore implements FarmStore { FileFarmStore(File file); }`

พฤติกรรม `FileFarmStore`:
- `load`: ไฟล์ไม่มี → `null`. อ่านแล้ว decode/parse ไม่ได้ (`FormatException` หรือ `TypeError`) → rename ไฟล์เป็น `<path>.corrupt-<millisecondsSinceEpoch>` แล้วคืน `StoreSnapshot.empty()`
- `save`: เขียน `<path>.tmp` ด้วย `flush: true` แล้ว `rename` ทับไฟล์จริง (atomic) สร้าง parent directory ถ้ายังไม่มี

- [ ] **Step 1: Write the failing tests** (ใช้ `Directory.systemTemp.createTemp('soil')` + `addTearDown(() => dir.delete(recursive: true))`)

```dart
test('missing file loads as null', () async {
  expect(await FileFarmStore(File('${dir.path}/s.json')).load(), isNull);
});
test('save then load returns the same snapshot', () async {
  final store = FileFarmStore(File('${dir.path}/s.json'));
  final snap = StoreSnapshot(farms: [farm('f1')], plots: [plot('p1', 'f1')], rounds: [round('r1', 'p1')]);
  await store.save(snap);
  expect((await store.load())!.toJson(), snap.toJson());
  expect(File('${dir.path}/s.json.tmp').existsSync(), isFalse);
});
test('corrupt file is backed up and loads as empty, not null', () async {
  final f = File('${dir.path}/s.json')..writeAsStringSync('{"schemaVersion":1,"farms":[{');
  final snap = await FileFarmStore(f).load();
  expect(snap, isNotNull);
  expect(snap!.farms, isEmpty);
  expect(f.existsSync(), isFalse);
  expect(dir.listSync().whereType<File>().where((e) => e.path.contains('.corrupt-')), hasLength(1));
});
test('unknown schemaVersion is treated as corrupt', () async {
  final f = File('${dir.path}/s.json')..writeAsStringSync('{"schemaVersion":99,"farms":[],"plots":[],"rounds":[]}');
  expect((await FileFarmStore(f).load())!.farms, isEmpty);
});
test('MemoryFarmStore keeps the last saved snapshot', () async {
  final m = MemoryFarmStore();
  expect(await m.load(), isNull);
  await m.save(StoreSnapshot.empty());
  expect(m.saveCount, 1);
  expect(await m.load(), isNotNull);
});
```

ให้ implementer เขียน helper `farm(id)`, `plot(id, farmId)`, `round(id, plotId)` ไว้ในไฟล์ test เดียวกัน (ค่าคงที่ใดก็ได้)

- [ ] **Step 2: Run** `flutter test test/data/farm_store_test.dart` — Expected: FAIL (compile error)
- [ ] **Step 3: Implement `lib/data/farm_store.dart`** ตาม Interfaces/พฤติกรรมด้านบน
- [ ] **Step 4: Run** `flutter test test/data/farm_store_test.dart` — Expected: PASS
- [ ] **Step 5: Commit** `feat(data): add JSON file store with atomic writes and corrupt-file recovery`

---

### Task 3: Seed data + FarmRepository

**Files:**
- Create: `lib/data/seed.dart`, `lib/data/farm_repository.dart`
- Test: `test/data/farm_repository_test.dart`

**Interfaces:**
- Consumes: Task 1 models, Task 2 `StoreSnapshot`/`FarmStore`/`MemoryFarmStore`
- Produces:
  - `abstract final class SeedIds { static const farmMsu = 'farm-msu', farmLab = 'farm-lab', farm2 = 'farm-2', plotA = 'plot-a', plotB = 'plot-b', plotC = 'plot-c'; }`
  - `StoreSnapshot seedFromMock(DateTime now)` — 3 ฟาร์มจาก `Mock.farms` (ชื่อเดิม, caretaker เดิม, location `'อ.กันทรวิชัย จ.มหาสารคาม'`, note `''`, notify `true`); 3 แปลงจาก `Mock.plots` อยู่ใน `farmMsu` ทั้งหมด, boundary `Mock.polygon`; 1 รอบวัดของ `plotA` เวลา `now` จุด = `Mock.points`
  - `class FarmRepository extends ChangeNotifier`
    - `FarmRepository(FarmStore store, StoreSnapshot initial, {DateTime Function()? clock, String Function()? newId})`
    - `static Future<FarmRepository> open(FarmStore store, {StoreSnapshot Function(DateTime now)? seed, DateTime Function()? clock, String Function()? newId})` — `load()` เป็น null และมี `seed` → ใช้ seed แล้ว `save` ทันที; null และไม่มี seed → empty
    - queries: `List<FarmRecord> get farms` (เรียง `updatedAt` ใหม่→เก่า), `FarmRecord? farm(String id)`, `List<PlotRecord> plotsOf(String farmId, {bool includeArchived = false})` (เรียงตาม `createdAt` เก่า→ใหม่), `PlotRecord? plot(String id)`, `List<MeasurementRound> roundsOf(String plotId)` (ใหม่→เก่า), `MeasurementRound? latestRound(String plotId)`, `SoilStatus plotStatus(String plotId)` (latest round's status; ไม่มีรอบ → normal), `SoilStatus farmStatus(String farmId)` (`worstStatus` ของแปลงที่ไม่ archived), `DateTime Function() get clock`
    - mutations (ทั้งหมด `Future`, persist แล้ว `notifyListeners()`):
      `Future<FarmRecord> addFarm({required String name, String caretaker = '', String location = '', String note = '', bool notify = true})`,
      `Future<void> updateFarm(FarmRecord farm)` (ตั้ง `updatedAt` = clock()),
      `Future<void> deleteFarm(String id)` (ลบแปลงและรอบของฟาร์มนั้นด้วย),
      `Future<PlotRecord> addPlot({required String farmId, required String name, required String crop, required List<Offset> boundary, String note = ''})`,
      `Future<void> updatePlot(PlotRecord plot)`,
      `Future<void> setPlotArchived(String id, bool archived)`,
      `Future<void> deletePlot(String id)` (ลบรอบของแปลงด้วย),
      `Future<MeasurementRound> addRound({required String plotId, required List<SoilPoint> points, DateTime? takenAt})` ← API ที่ทีมเครื่องวัดจะเรียก
    - กฎ: ชื่อถูก `trim()`; ชื่อว่าง → `ArgumentError`; `boundary.length < 3` → `ArgumentError`; `farmId`/`plotId` ไม่มีจริง → `StateError`; `addPlot`/`updatePlot`/`addRound`/`setPlotArchived` ทำให้ `updatedAt` ของฟาร์มเจ้าของเป็น `clock()`
    - ความทนทาน: mutation สร้าง snapshot ใหม่ → `await store.save(next)` → สำเร็จจึงแทนที่ state และ notify; save โยน exception → state เดิมคงอยู่, ไม่ notify, rethrow. mutation เรียงคิวกัน (เก็บ `Future<void> _queue` แล้ว chain ทุกงานต่อท้าย) — งานที่ 2 เริ่มหลังงานที่ 1 save เสร็จ
    - id เริ่มต้น: `'${prefix}-${clock().microsecondsSinceEpoch.toRadixString(36)}-${_counter++}'` (prefix `farm`/`plot`/`round`)

- [ ] **Step 1: Write the failing tests** — ใช้ `MemoryFarmStore`, `clock: () => t` (ตัวแปร `t` ปรับได้), `newId` เป็น counter

```dart
test('open seeds once when store is empty and persists it', () async {
  final store = MemoryFarmStore();
  final repo = await FarmRepository.open(store, seed: seedFromMock, clock: () => t);
  expect(repo.farms.map((f) => f.id), containsAll([SeedIds.farmMsu, SeedIds.farmLab, SeedIds.farm2]));
  expect(repo.plotsOf(SeedIds.farmMsu), hasLength(3));
  expect(repo.latestRound(SeedIds.plotA)!.points, hasLength(14));
  expect(repo.plotStatus(SeedIds.plotA), SoilStatus.watch);
  expect(repo.plotStatus(SeedIds.plotB), SoilStatus.normal);
  expect(store.saveCount, 1);
  final again = await FarmRepository.open(store, seed: (_) => StoreSnapshot.empty());
  expect(again.farms, hasLength(3));
});
test('addFarm trims, persists, notifies, and sorts newest first', () async { /* name '  ใหม่  ' → 'ใหม่'; farms.first.id == new id; listener called once; store.current has it */ });
test('blank farm name throws ArgumentError and changes nothing', () async {
  await expectLater(repo.addFarm(name: '   '), throwsArgumentError);
  expect(repo.farms, hasLength(3));
});
test('addPlot needs ≥3 boundary points and an existing farm', () async {
  await expectLater(repo.addPlot(farmId: SeedIds.farmMsu, name: 'D', crop: 'ข้าว', boundary: Mock.polygon.take(2).toList()), throwsArgumentError);
  await expectLater(repo.addPlot(farmId: 'nope', name: 'D', crop: 'ข้าว', boundary: Mock.polygon), throwsStateError);
});
test('archived plots are hidden unless includeArchived', () async { /* setPlotArchived(plotB,true) → plotsOf length 2, includeArchived length 3 */ });
test('deleteFarm cascades plots and rounds', () async {
  await repo.deleteFarm(SeedIds.farmMsu);
  expect(repo.plot(SeedIds.plotA), isNull);
  expect(repo.roundsOf(SeedIds.plotA), isEmpty);
});
test('addRound makes it the latest and bumps farm updatedAt', () async { /* t = later; addRound(plotC, points: [Mock.points[7]]) → latestRound(plotC).status watch; farm(farmMsu).updatedAt == t */ });
test('failed save keeps previous state and rethrows', () async {
  final store = _FailingStore(seedFromMock(t)); // load ok, save throws
  final repo = await FarmRepository.open(store);
  var notified = 0; repo.addListener(() => notified++);
  await expectLater(repo.addFarm(name: 'X'), throwsA(isA<FileSystemException>()));
  expect(repo.farms, hasLength(3));
  expect(notified, 0);
});
test('concurrent mutations are serialized and both persist', () async {
  await Future.wait([repo.addFarm(name: 'A'), repo.addFarm(name: 'B')]);
  expect(store.current!.farms.map((f) => f.name), containsAll(['A', 'B']));
});
```

`_FailingStore implements FarmStore`: `load` คืน snapshot ที่ให้มา, `save` โยน `const FileSystemException('disk full')`. test ที่เป็นคอมเมนต์ `/* */` ให้ implementer เขียนให้ assert ตามที่ระบุไว้

- [ ] **Step 2: Run** `flutter test test/data/farm_repository_test.dart` — Expected: FAIL (compile error)
- [ ] **Step 3: Implement `lib/data/seed.dart` และ `lib/data/farm_repository.dart`** ตาม Interfaces
- [ ] **Step 4: Run** `flutter test test/data/` — Expected: PASS ทั้งหมด
- [ ] **Step 5: Commit** `feat(data): add FarmRepository with seed, validation, cascade delete and rollback`

---

### Task 4: AppScope, app startup, test harness

**Files:**
- Create: `lib/data/app_scope.dart`, `test/helpers.dart`
- Modify: `lib/main.dart`, `pubspec.yaml`, `test/widget_test.dart`

**Interfaces:**
- Consumes: Task 3 `FarmRepository`, `seedFromMock`; Task 2 `FileFarmStore`, `MemoryFarmStore`
- Produces:
  - `class AppScope extends InheritedNotifier<FarmRepository> { const AppScope({super.key, required FarmRepository repository, required super.child}); static FarmRepository of(BuildContext c); static FarmRepository read(BuildContext c); }` — `of` = subscribe (rebuild เมื่อ notify), `read` = ไม่ subscribe (ใช้ใน callback). หาไม่เจอ → `FlutterError('AppScope not found')`
  - `class SmartSoilApp extends StatelessWidget { const SmartSoilApp({super.key, required this.repository}); }` — `AppScope` อยู่**เหนือ** `MaterialApp` (ทุก route เห็น)
  - `main()` เป็น async: `WidgetsFlutterBinding.ensureInitialized()`, `getApplicationDocumentsDirectory()`, ไฟล์ `smart_soil.json`, `FarmRepository.open(FileFarmStore(file), seed: seedFromMock)`
  - TextField ชื่อมี key คงที่สำหรับ test: `const Key('farm-name')` (CreateFarmScreen), `const Key('plot-name')` (CreatePlotScreen, EditPlotScreen) — ใส่ใน Task 5/6
  - ถ้า `pumpAndSettle` หลัง `backToShell` timeout เพราะ animation ใน `AppShell` ให้ใช้ `pump(const Duration(seconds: 1))` แทน — ห้ามแก้ `AppShell`
  - `test/helpers.dart`: `Future<FarmRepository> seededRepo({DateTime? now})` (MemoryFarmStore + seedFromMock, ค่าเริ่ม now = `DateTime(2026, 11, 19, 14, 32)`), `Widget wrap(FarmRepository repo, Widget home)` = `AppScope(repository: repo, child: MaterialApp(theme: buildTheme(), home: home))`

- [ ] **Step 1: Update tests** — `test/widget_test.dart`: test แรกใช้ `SmartSoilApp(repository: await seededRepo())` (ใน `testWidgets` ต้องเรียกผ่าน `tester.runAsync` ถ้าค้าง — ปกติ MemoryFarmStore ไม่ต้อง); test แคตตาล็อกใช้ `wrap(repo, e.build())` แทน `MaterialApp(home: e.build())`. เพิ่ม test ใน `test/data/app_scope_test.dart`:

```dart
testWidgets('AppScope.of rebuilds dependents on change', (tester) async {
  final repo = await seededRepo();
  var builds = 0;
  await tester.pumpWidget(AppScope(repository: repo, child: Builder(builder: (c) { AppScope.of(c); builds++; return const SizedBox(); })));
  await repo.addFarm(name: 'ใหม่');
  await tester.pump();
  expect(builds, 2);
});
```

- [ ] **Step 2: Run** `flutter test` — Expected: FAIL (compile errors)
- [ ] **Step 3: Implement** — `flutter pub add path_provider` (ต้องได้ `^2.1.5` หรือใหม่กว่าใน 2.x), เขียน `app_scope.dart`, `main.dart`, `helpers.dart`
- [ ] **Step 4: Run** `flutter analyze` และ `flutter test` — Expected: No issues / All tests passed
- [ ] **Step 5: Commit** `feat: load FarmRepository at startup and expose via AppScope`

---

### Task 5: Farm screens อ่าน/เขียนข้อมูลจริง

**Files:**
- Modify: `lib/screens/farm_screens.dart` (`FarmListScreen`, `CreateFarmScreen`, + ปุ่มแก้ไขฟาร์มในหัวการ์ดของ `PlotListScreen`)
- Test: `test/screens/farm_screens_test.dart`

**Interfaces:**
- Consumes: `AppScope`, `FarmRepository`, `formatWhen`, `SeedIds`, `wrap`/`seededRepo`
- Produces:
  - `FarmListScreen` (ctor เดิม) — แสดง `repo.farms`, ค้นหาเหมือนเดิม, Pill `ทั้งหมด N ฟาร์ม`, จำนวนแปลง = `plotsOf(id).length`, สถานะ = `farmStatus(id)`, บรรทัดรอง = `'ผู้ดูแล: ${caretaker} • ${formatWhen(updatedAt, repo.clock())}'`; แตะ → `PlotListScreen(farmId: f.id)`; ไม่มีฟาร์มเลย → `InfoBox` "ยังไม่มีฟาร์ม" + ปุ่ม "เพิ่มฟาร์ม"
  - `CreateFarmScreen({super.key, this.farmId})` — แทน `editing`; `farmId == null` → สร้างใหม่ (ช่องว่าง ไม่มีปุ่มลบ, title `'สร้างฟาร์ม'`); มี id → เติมค่าเดิม, title `'แก้ไขฟาร์ม'`, มีปุ่มลบ; id ไม่พบ → แสดง `InfoBox(tone: Tone.grey, title: 'ไม่พบฟาร์มนี้')` อย่างเดียว. ทุกช่อง (ชื่อ ผู้ดูแล ตำแหน่ง คำอธิบาย แจ้งเตือน) บันทึกจริง
  - บันทึก: ชื่อว่าง → `toast(context, 'กรุณาใส่ชื่อฟาร์ม')` ไม่ pop; สำเร็จ → `backToShell(context, 'บันทึกฟาร์ม "<ชื่อ>" แล้ว')`; exception อื่น → `toast(context, 'บันทึกไม่สำเร็จ ลองอีกครั้ง')`. ปุ่มบันทึก disabled ระหว่างรอ (กันกดซ้ำ)
  - ลบ: confirm เดิม → `deleteFarm` → `backToShell(context, 'ลบฟาร์มแล้ว')`
  - call sites ที่ใช้ `CreateFarmScreen()` (onboarding, state_screens, catalog) ไม่ต้องแก้ (ยังเป็น "สร้างใหม่")

- [ ] **Step 1: Write the failing widget tests**

```dart
testWidgets('farm list shows repository farms with plot counts', (tester) async {
  final repo = await seededRepo();
  await tester.pumpWidget(wrap(repo, const FarmListScreen()));
  expect(find.text('ทั้งหมด 3 ฟาร์ม'), findsOneWidget);
  expect(find.text('3 แปลง'), findsOneWidget);
  expect(find.text('0 แปลง'), findsNWidgets(2));
});
testWidgets('creating a farm persists it', (tester) async {
  final repo = await seededRepo();
  await tester.pumpWidget(wrap(repo, const CreateFarmScreen()));
  await tester.enterText(find.byKey(const Key('farm-name')), 'ฟาร์มทดสอบ');
  await tester.tap(find.text('บันทึกฟาร์ม'));
  await tester.pumpAndSettle();
  expect(repo.farms.first.name, 'ฟาร์มทดสอบ');
});
testWidgets('blank farm name shows a message and saves nothing', (tester) async {
  /* enterText '   ' → tap บันทึกฟาร์ม → pump → find.text('กรุณาใส่ชื่อฟาร์ม') findsOneWidget; repo.farms length 3 */
});
testWidgets('editing pre-fills and delete removes the farm', (tester) async {
  /* CreateFarmScreen(farmId: SeedIds.farmLab) → find.text('จุดสอบเทียบ (แล็บ)') ใน TextField; tap 'ลบฟาร์ม…' → tap 'ลบถาวร' → pumpAndSettle → repo.farm(SeedIds.farmLab) isNull */
});
testWidgets('unknown farm id shows not-found', (tester) async {
  /* CreateFarmScreen(farmId: 'gone') → find.text('ไม่พบฟาร์มนี้') findsOneWidget */
});
```

- [ ] **Step 2: Run** `flutter test test/screens/farm_screens_test.dart` — Expected: FAIL
- [ ] **Step 3: Implement** ตาม Interfaces (TextEditingController ของคำอธิบายต้อง dispose)
- [ ] **Step 4: Run** `flutter analyze` และ `flutter test` — Expected: ผ่านทั้งหมด (รวม catalog test)
- [ ] **Step 5: Commit** `feat(farms): wire farm list and create/edit/delete farm to repository`

---

### Task 6: Plot screens อ่าน/เขียนข้อมูลจริง

**Files:**
- Modify: `lib/screens/farm_screens.dart` (`PlotListScreen`, `PlotDetailScreen`, `CreatePlotScreen`, `DrawBoundaryScreen`, `EditPlotScreen`), `lib/screens/catalog.dart`
- Test: `test/screens/plot_screens_test.dart`

**Interfaces:**
- Consumes: เหมือน Task 5
- Produces:
  - `PlotListScreen({super.key, this.farmId})` — null → ฟาร์มแรกของ `repo.farms`; ไม่มีฟาร์ม/ไม่พบ → `InfoBox` "ไม่พบฟาร์มนี้". หัวการ์ด: ชื่อฟาร์ม, `'N แปลง • อัปเดตล่าสุด ${formatWhen(...)}'`, ปุ่ม edit → `CreateFarmScreen(farmId:)`. รายการ = `plotsOf(farmId)`; บรรทัดตรวจล่าสุด = `'ตรวจล่าสุด ${formatWhen(latestRound.takenAt, now)}'` หรือ `'ยังไม่เคยวัด'`; แตะ → `PlotDetailScreen(plotId:)`; ปุ่มเพิ่มแปลง → `CreatePlotScreen(farmId:)`
  - `PlotDetailScreen({super.key, this.plotId})` — null → `SeedIds.plotA`; ไม่พบ → InfoBox "ไม่พบแปลงนี้". ใช้ข้อมูลจริง: ชื่อ, `'<ชื่อฟาร์ม> • <rai 1 ตำแหน่ง> ไร่ • <crop>'`, สถานะ, เวลา latestRound; ValueTile 4 ช่องจาก latestRound (`'N จุด'`, `'<avg moisture 0 ตำแหน่ง>%'`, `'<avg pH 1 ตำแหน่ง>'`, `'<watchCount> จุด'`) — ไม่มีรอบ → `'—'` ทุกช่อง + `InfoBox` "ยังไม่มีผลการวัด". แท็บประวัติ = `roundsOf(plotId)` (`title: formatWhen(takenAt)`, `subtitle: 'ตรวจครบ N จุด • เฝ้าดู M จุด'`). แท็บแผนที่และ AI ยังใช้ Mock (R6). ปุ่ม edit → `EditPlotScreen(plotId:)`
  - `CreatePlotScreen({super.key, this.farmId})` — ตัวเลือกฟาร์มจาก `repo.farms` (เก็บเป็น id, แสดงชื่อ; `PickerField` รับ String — map ชื่อ↔id ภายในหน้า), ชื่อเริ่มว่าง, เก็บหมายเหตุ; ชื่อว่าง → toast `'กรุณาใส่ชื่อแปลง'`; ไม่มีฟาร์ม → ปุ่ม disabled + InfoBox ให้สร้างฟาร์มก่อน. ไปต่อ → `DrawBoundaryScreen(plotName:, initial: const [], onSave: (pts) => repo.addPlot(...))`
  - `DrawBoundaryScreen({super.key, this.plotName = 'แปลงใหม่', this.initial, this.onSave, this.successMessage})` — `initial == null` → `Mock.polygon` (ค่าเดิมของแคตตาล็อก); `Future<void> Function(List<Offset> points)? onSave`; กด "ใช้ขอบเขตนี้": `onSave == null` → พฤติกรรมเดิม; มี → await onSave, สำเร็จ → `backToShell(context, successMessage ?? 'บันทึก <ชื่อ> (<rai> ไร่) แล้ว')`, error → toast `'บันทึกไม่สำเร็จ ลองอีกครั้ง'`; ปุ่ม disabled ระหว่างรอ
  - `EditPlotScreen({super.key, required this.plotId})` — ไม่พบ → InfoBox "ไม่พบแปลงนี้". ชื่อ/ฟาร์ม (เลือกได้จาก `repo.farms`)/พืช บันทึกด้วย `updatePlot` แล้ว pop + toast เดิม; สวิตช์ "แสดงแปลงนี้ในหน้าหลัก" = `!archived`; ข้อความ `'<rai> ไร่ • <จำนวนจุด> จุดขอบเขต'`; "แก้ไขขอบเขต" → `DrawBoundaryScreen(initial: plot.boundary, onSave: (pts) => repo.updatePlot(plot.copyWith(boundary: pts)), successMessage: 'บันทึกขอบเขตแล้ว')`; เก็บถาวร → `setPlotArchived(id, true)`; ลบถาวร → `deletePlot`
  - `catalog.dart`: `FLOW-11` → `const EditPlotScreen(plotId: SeedIds.plotA)`; `FLOW-06` ไม่ต้องแก้ (`const PlotDetailScreen()`)

- [ ] **Step 1: Write the failing widget tests**

```dart
testWidgets('plot list shows plots of the farm and never-measured text', (tester) async {
  final repo = await seededRepo();
  await tester.pumpWidget(wrap(repo, const PlotListScreen(farmId: SeedIds.farmMsu)));
  expect(find.text('แปลงมันสำปะหลัง A'), findsOneWidget);
  expect(find.text('ยังไม่เคยวัด'), findsNWidgets(2));
});
testWidgets('plot detail shows stats from the latest round', (tester) async {
  final repo = await seededRepo();
  await tester.pumpWidget(wrap(repo, const PlotDetailScreen(plotId: SeedIds.plotA)));
  expect(find.text('14 จุด'), findsOneWidget);
  expect(find.text('2 จุด'), findsOneWidget);
});
testWidgets('plot detail with no rounds shows dashes', (tester) async {
  /* plotId: SeedIds.plotB → find.text('—') findsNWidgets(4); find.text('ยังไม่มีผลการวัด') findsOneWidget */
});
testWidgets('create plot → draw 3 points → saved', (tester) async {
  final repo = await seededRepo();
  await tester.pumpWidget(wrap(repo, const CreatePlotScreen(farmId: SeedIds.farmLab)));
  await tester.enterText(find.byKey(const Key('plot-name')), 'แปลงใหม่ X');
  await tester.tap(find.text('ไปยังการวาดขอบเขต'));
  await tester.pumpAndSettle();
  final map = find.byType(PlotMap);
  for (final o in [const Offset(-60, -60), const Offset(60, -60), const Offset(0, 60)]) {
    await tester.tapAt(tester.getCenter(map) + o);
    await tester.pump();
  }
  await tester.tap(find.text('ใช้ขอบเขตนี้'));
  await tester.pumpAndSettle();
  final plots = repo.plotsOf(SeedIds.farmLab);
  expect(plots.single.name, 'แปลงใหม่ X');
  expect(plots.single.boundary, hasLength(3));
});
testWidgets('archive via edit hides the plot from the list', (tester) async {
  /* EditPlotScreen(plotId: plotB) → tap 'เก็บถาวร' → tap confirm 'ยืนยัน' → pumpAndSettle → repo.plotsOf(farmMsu) length 2 */
});
testWidgets('unknown plot id shows not-found on detail and edit', (tester) async {
  /* PlotDetailScreen(plotId:'gone') และ EditPlotScreen(plotId:'gone') → find.text('ไม่พบแปลงนี้') */
});
```

ถ้า tap บน `PlotMap` ไม่ทำให้เกิดจุด (onTapMap คำนวณจาก local position) ให้ปรับ offset ให้อยู่ในกรอบแผนที่ — ห้ามแก้ `PlotMap`

- [ ] **Step 2: Run** `flutter test test/screens/plot_screens_test.dart` — Expected: FAIL
- [ ] **Step 3: Implement** ตาม Interfaces
- [ ] **Step 4: Run** `flutter analyze` และ `flutter test` — Expected: ผ่านทั้งหมด
- [ ] **Step 5: Commit** `feat(plots): wire plot list, detail, create, boundary and edit to repository`

---

### Task 7: ตรวจรวมบนเครื่องจริง (Opus ทำเอง ไม่ใช่ subagent)

- [ ] `flutter analyze` → No issues found; `flutter test` → All tests passed
- [ ] `flutter run` บน emulator: สร้างฟาร์ม "ทดสอบ" → สร้างแปลง วาด 4 จุด → ปิดแอป (stop) → เปิดใหม่ → ฟาร์มและแปลงยังอยู่
- [ ] เก็บถาวรแปลง → หายจากรายการ; ลบฟาร์ม → แปลงหาย
- [ ] เขียนขยะลงไฟล์ด้วย `adb shell run-as th.ac.msu.precisionfarming sh -c 'echo "{" > app_flutter/smart_soil.json'` → เปิดแอป → ไม่ crash, ฟาร์มว่าง, มีไฟล์ `.corrupt-*`
- [ ] อัปเดต `README.md`: หัวข้อ "ข้อมูล" บอกว่าเก็บที่ `smart_soil.json` และ API `FarmRepository.addRound` สำหรับทีมเครื่องวัด
- [ ] Commit `docs: describe local data storage`
