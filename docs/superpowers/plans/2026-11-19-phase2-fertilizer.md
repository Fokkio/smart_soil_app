# Phase 2 — Expert-Confirmed Fertilizer Calculator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> **Execution (ตกลงกับผู้ใช้แล้ว):** implementer = subagent `model: "sonnet"` ทีละ task ตามลำดับ, reviewer = Opus 5.5 (controller) หลังจบแต่ละ task; Task 6 Opus ทำเองบน MuMu (`127.0.0.1:16416`)
> **Branch:** `claude/phase2-fertilizer` (แตกจาก Phase 1 `e61522c`) → PR แยกจาก PR #1

**Goal:** ผู้ใช้กดดู "ปุ๋ยที่ควรใส่" ของแปลงจากผลวัดรอบล่าสุด โดยตัวเลขอัตราปุ๋ยมาจากตารางที่ทีมกรอกและผู้เชี่ยวชาญยืนยันในแอปเท่านั้น

**Architecture:** โมเดลตาราง (`CropRuleSet`, `NutrientRule`, `FertilizerPrices`) เก็บเพิ่มใน `StoreSnapshot` (schema v2, อ่าน v1 ได้) → `FarmRepository` เพิ่มเมธอดจัดการตาราง/ราคา/การยืนยัน → ฟังก์ชันคำนวณ pure `calculateFertilizer` → หน้าจอใหม่ใน `lib/screens/fertilizer_screens.dart`

**Tech Stack:** Flutter 3.44 / Dart ≥ 3.4, `flutter_test` — ไม่มี package ใหม่

**Spec:** `docs/superpowers/specs/2026-11-19-smart-soil-feature-roadmap.md` (หัวข้อ "Requirements ของ Phase 2", F1–F10)

## Global Constraints

- **ห้ามมีตัวเลขอัตราปุ๋ย/เกณฑ์ดินจริงในโค้ดแอป** (F1) — ค่าคงที่ที่อนุญาตมีแค่เปอร์เซ็นต์ธาตุในปุ๋ยเดี่ยว: ยูเรีย N 46%, TSP P₂O₅ 46%, KCl K₂O 60% (F3). ตัวเลขใน test เป็นค่าทดสอบเท่านั้น
- ไม่เพิ่ม package; ไม่แก้ `lib/data/mock_data.dart`
- ข้อความ UI ภาษาไทย, ใช้ widget จาก `lib/widgets/common.dart` ตามแบบหน้าที่มีอยู่
- ทุก task จบด้วย `flutter analyze` → "No issues found!" และ `flutter test` → "All tests passed!" (เริ่มที่ 50 tests) ก่อน commit
- commit message ลงท้าย `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`; ห้าม commit `.superpowers/`

## Review Focus

1. ไฟล์ข้อมูลจาก Phase 1 (`schemaVersion: 1`) → ต้องโหลดได้ครบ ไม่ถูกมองว่าไฟล์เสีย ไม่งั้นข้อมูลผู้ใช้หาย (Task 1)
2. แก้ฟาร์ม/แปลง/ผลวัด (mutation เดิมของ Phase 1) → ตารางปุ๋ยและราคาต้องไม่หาย (Task 3)
3. แก้ตารางที่ยืนยันแล้ว → สถานะกลับเป็น "ยังไม่ผ่านการยืนยัน" เสมอ (Task 3)
4. กรอกตัวเลขผิด (ว่าง, ไม่ใช่ตัวเลข, ติดลบ, `lowBelow >= highFrom`) → ไม่บันทึกและบอกผู้ใช้ (Task 3 + Task 4)
5. ไม่ได้กรอกราคา (0) → ต้นทุนแสดง "—" ไม่ใช่ "0 บาท" (Task 2 + Task 5)

---

## File Structure

| ไฟล์ | หน้าที่ |
|---|---|
| Create `lib/data/fertilizer.dart` | `Nutrient`, `NutrientLevel`, `NutrientRule`, `CropRuleSet`, `FertilizerPrices` + JSON + `validate` |
| Modify `lib/data/farm_store.dart` | `StoreSnapshot` v2: `ruleSets`, `prices`, `copyWith`; อ่าน v1 |
| Create `lib/data/fertilizer_calc.dart` | `calculateFertilizer`, `FertilizerResult`, `NutrientResult`, `ProductResult`, `kStraightFertilizers` |
| Modify `lib/data/farm_repository.dart` | mutation เดิมใช้ `copyWith`; เมธอดตาราง/ราคา/ยืนยัน |
| Create `lib/screens/fertilizer_screens.dart` | `FertilizerRulesScreen`, `RuleSetEditScreen`, `FertilizerScreen` |
| Modify `lib/screens/main_tabs.dart`, `lib/screens/farm_screens.dart`, `lib/screens/catalog.dart` | ทางเข้า + แคตตาล็อก |
| Modify `README.md` | หลักการข้อ F9 + หัวข้อปุ๋ย |

---

### Task 1: Fertilizer models + StoreSnapshot v2

**Files:**
- Create: `lib/data/fertilizer.dart`
- Modify: `lib/data/farm_store.dart`
- Test: `test/data/fertilizer_test.dart`, `test/data/farm_store_test.dart` (เพิ่ม)

**Interfaces:**
- Produces:
  - `enum Nutrient { n, p, k }` + `String nutrientLabel(Nutrient)` → `'N'`, `'P₂O₅'`, `'K₂O'`
  - `enum NutrientLevel { low, medium, high }` + `String levelLabel(NutrientLevel)` → `'ต่ำ'`, `'ปานกลาง'`, `'สูง'`
  - `class NutrientRule { final Nutrient nutrient; final double lowBelow, highFrom, rateLow, rateMedium, rateHigh; const ...(named required); NutrientLevel levelFor(double measured); double rateFor(NutrientLevel); String? validate(); toJson/fromJson }` — `levelFor`: `< lowBelow` → low, `>= highFrom` → high, อื่นๆ medium. `validate()` คืนข้อความไทยของปัญหาแรก หรือ null: ค่าใดติดลบ/NaN → `'ค่าต้องไม่ติดลบ'`; `lowBelow >= highFrom` → `'เกณฑ์ "ต่ำกว่า" ต้องน้อยกว่าเกณฑ์ "สูงตั้งแต่"'`
  - `class CropRuleSet { final String crop, source, confirmedBy; final List<NutrientRule> rules; final DateTime? confirmedAt; bool get isConfirmed; NutrientRule? ruleFor(Nutrient); copyWith; toJson/fromJson }` — `isConfirmed` = `confirmedBy.trim().isNotEmpty && confirmedAt != null`; `rules` มีธาตุละไม่เกิน 1
  - `class FertilizerPrices { final double urea, tsp, mop; const FertilizerPrices({this.urea = 0, this.tsp = 0, this.mop = 0}); static const zero = FertilizerPrices(); toJson/fromJson }` (บาท/กก.)
  - `StoreSnapshot` เพิ่ม named params `List<CropRuleSet> ruleSets = const []`, `FertilizerPrices prices = FertilizerPrices.zero` (ห่อ `ruleSets` ด้วย `List.unmodifiable` เหมือน list อื่น), `StoreSnapshot copyWith({farms, plots, rounds, ruleSets, prices})`; `schemaVersion = 2`; `toJson` เขียน `"ruleSets"`, `"prices"`; `fromJson` รับ 1 หรือ 2 (v1 → ruleSets ว่าง, prices zero), อื่นๆ `FormatException`

- [ ] **Step 1: Write failing tests**

```dart
// test/data/fertilizer_test.dart
const n = NutrientRule(nutrient: Nutrient.n, lowBelow: 20, highFrom: 40, rateLow: 10, rateMedium: 6, rateHigh: 3);
test('levelFor uses < lowBelow and >= highFrom', () {
  expect(n.levelFor(19.9), NutrientLevel.low);
  expect(n.levelFor(20), NutrientLevel.medium);
  expect(n.levelFor(40), NutrientLevel.high);
  expect(n.rateFor(NutrientLevel.medium), 6);
});
test('validate rejects negatives and inverted thresholds', () {
  expect(n.validate(), isNull);
  expect(const NutrientRule(nutrient: Nutrient.n, lowBelow: 40, highFrom: 40, rateLow: 1, rateMedium: 1, rateHigh: 1).validate(), isNotNull);
  expect(const NutrientRule(nutrient: Nutrient.n, lowBelow: 1, highFrom: 2, rateLow: -1, rateMedium: 1, rateHigh: 1).validate(), 'ค่าต้องไม่ติดลบ');
});
test('CropRuleSet round-trips and reports confirmation', () {
  final s = CropRuleSet(crop: 'ข้าว', source: 'ทดสอบ', rules: const [n], confirmedBy: 'ดร.ทดสอบ', confirmedAt: DateTime(2026, 11, 19));
  final back = CropRuleSet.fromJson(jsonDecode(jsonEncode(s.toJson())));
  expect(back.toJson(), s.toJson());
  expect(back.isConfirmed, isTrue);
  expect(back.copyWith(confirmedBy: '').isConfirmed, isFalse);
  expect(back.ruleFor(Nutrient.k), isNull);
});
// test/data/farm_store_test.dart — เพิ่ม
test('schemaVersion 1 file from Phase 1 loads without quarantine', () async {
  final f = File('${dir.path}/s.json')..writeAsStringSync(jsonEncode({...StoreSnapshot(farms: [farm('f1')], plots: const [], rounds: const []).toJson(), 'schemaVersion': 1}..remove('ruleSets')..remove('prices')));
  final snap = (await FileFarmStore(f).load())!;
  expect(snap.farms.single.id, 'f1');
  expect(snap.ruleSets, isEmpty);
  expect(snap.prices.urea, 0);
  expect(dir.listSync().where((e) => e.path.contains('.corrupt-')), isEmpty);
});
test('v2 snapshot round-trips rule sets and prices', () async { /* save StoreSnapshot with 1 CropRuleSet + FertilizerPrices(urea: 20) → load → toJson equal, schemaVersion 2 in file */ });
```

- [ ] **Step 2: Run** `flutter test test/data/` — Expected: FAIL (compile)
- [ ] **Step 3: Implement** ตาม Interfaces. JSON enum ใช้ `.name`; `confirmedAt` null → ไม่ใส่ key หรือ `null`
- [ ] **Step 4: Run** `flutter analyze` + `flutter test` — Expected: ผ่านทั้งหมด
- [ ] **Step 5: Commit** `feat(data): add fertilizer rule models and store schema v2 with v1 migration`

---

### Task 2: Calculator

**Files:**
- Create: `lib/data/fertilizer_calc.dart`
- Test: `test/data/fertilizer_calc_test.dart`

**Interfaces:**
- Consumes: Task 1; `MeasurementRound.avg` จาก `lib/data/models.dart` (`Reading.n/p/k` เป็น int mg/kg)
- Produces:
  - `class StraightFertilizer { final String name; final Nutrient nutrient; final double fraction; }` + `const kStraightFertilizers = [ ('ยูเรีย 46-0-0', n, 0.46), ('ทริปเปิลซูเปอร์ฟอสเฟต 0-46-0', p, 0.46), ('โพแทสเซียมคลอไรด์ 0-0-60', k, 0.60) ]` (เขียนเป็น `StraightFertilizer` const)
  - `enum FertilizerIssue { noRound, noRules }`
  - `class NutrientResult { final Nutrient nutrient; final double measured; final NutrientLevel level; final double ratePerRai; }`
  - `class ProductResult { final StraightFertilizer product; final double kgPerRai, totalKg; final double? cost; }`
  - `class FertilizerResult { final FertilizerIssue? issue; final List<NutrientResult> nutrients; final List<ProductResult> products; final double? totalCost; final bool confirmed; final String source; }`
  - `FertilizerResult calculateFertilizer({required double rai, required MeasurementRound? round, required CropRuleSet? rules, required FertilizerPrices prices})`
- กฎ: round null หรือไม่มีจุด → `issue: noRound`; rules null หรือ `rules.rules` ว่าง → `issue: noRules` (เช็ค noRound ก่อน); ธาตุที่ไม่มีกฎ → ไม่อยู่ใน `nutrients`/`products`; product ที่ `kgPerRai == 0` ไม่ใส่; `cost` = `totalKg * price` ถ้า price > 0 ไม่งั้น null; `totalCost` = ผลรวมเมื่อทุก product มี cost ไม่งั้น null (ไม่มี product เลย → 0)

- [ ] **Step 1: Write failing tests** (round = `MeasurementRound(id:'r', plotId:'p', takenAt: DateTime(2026), points: Mock.points)` → เฉลี่ย N 42, P 18, K 56)

```dart
final rules = CropRuleSet(crop: 'มันสำปะหลัง', source: 'ค่าทดสอบ', confirmedBy: '', confirmedAt: null, rules: const [
  NutrientRule(nutrient: Nutrient.n, lowBelow: 20, highFrom: 40, rateLow: 10, rateMedium: 6, rateHigh: 3),
  NutrientRule(nutrient: Nutrient.p, lowBelow: 10, highFrom: 25, rateLow: 8, rateMedium: 4, rateHigh: 2),
  NutrientRule(nutrient: Nutrient.k, lowBelow: 60, highFrom: 120, rateLow: 8, rateMedium: 5, rateHigh: 2),
]);
test('levels, straight-fertilizer amounts and costs', () {
  final r = calculateFertilizer(rai: 10, round: round, rules: rules, prices: const FertilizerPrices(urea: 20, tsp: 25, mop: 18));
  expect(r.issue, isNull);
  expect(r.nutrients.map((x) => x.level), [NutrientLevel.high, NutrientLevel.medium, NutrientLevel.low]);
  expect(r.products[0].kgPerRai, closeTo(6.5217, 1e-3));
  expect(r.products[1].totalKg, closeTo(86.9565, 1e-3));
  expect(r.products[2].totalKg, closeTo(133.3333, 1e-3));
  expect(r.totalCost, closeTo(5878.26, 0.01));
  expect(r.confirmed, isFalse);
});
test('missing price gives null cost and null total', () { /* prices FertilizerPrices(urea: 20) → products[0].cost≈1304.35, products[1].cost isNull, totalCost isNull */ });
test('no round → noRound; no rules → noRules', () { /* round null → noRound (even if rules null); round ok + rules null → noRules; CropRuleSet with rules [] → noRules */ });
test('nutrient without a rule and zero rate are skipped', () { /* rules with only N rule rateHigh 0 → nutrients length 1, products empty, totalCost 0 */ });
```

- [ ] **Step 2: Run** `flutter test test/data/fertilizer_calc_test.dart` — FAIL
- [ ] **Step 3: Implement** ตาม Interfaces
- [ ] **Step 4: Run** `flutter analyze` + `flutter test` — ผ่าน
- [ ] **Step 5: Commit** `feat(data): add fertilizer calculator`

---

### Task 3: Repository — ตาราง ราคา การยืนยัน

**Files:**
- Modify: `lib/data/farm_repository.dart`
- Test: `test/data/farm_repository_test.dart` (เพิ่ม)

**Interfaces:**
- Consumes: Task 1 (`StoreSnapshot.copyWith`, `CropRuleSet`, `NutrientRule.validate`, `FertilizerPrices`)
- Produces (บน `FarmRepository`):
  - `List<CropRuleSet> get ruleSets` (เรียงตาม crop), `CropRuleSet? ruleSetFor(String crop)`, `FertilizerPrices get prices`
  - `Future<void> saveRuleSet(CropRuleSet set)` — upsert ตาม `crop`; crop trim ว่าง → `ArgumentError`; กฎไหน `validate() != null` → `ArgumentError(message)` (message = ข้อความไทยจาก validate); ธาตุซ้ำ → `ArgumentError`; **บันทึกด้วย `confirmedBy: ''`, `confirmedAt: null` เสมอ**
  - `Future<void> confirmRuleSet(String crop, String expertName)` — ไม่มี crop → `StateError`; ชื่อ trim ว่าง → `ArgumentError`; ตั้ง `confirmedBy` = ชื่อ trim, `confirmedAt` = `clock()`
  - `Future<void> deleteRuleSet(String crop)` — ไม่มี → `StateError`
  - `Future<void> setPrices(FertilizerPrices p)` — ค่าใดติดลบหรือ NaN → `ArgumentError`
  - mutation ของ Phase 1 ทุกตัวสร้าง snapshot ด้วย `_state.copyWith(...)` แทน `StoreSnapshot(...)` เพื่อไม่ทิ้ง `ruleSets`/`prices`
  - ทุกเมธอดใหม่ใช้ `_enqueue` + `_commit` เดิม (rollback/notify/queue เหมือน Phase 1)

- [ ] **Step 1: Write failing tests**

```dart
test('saving a confirmed rule set clears confirmation', () async {
  await repo.saveRuleSet(rules);            // rules จาก Task 2 test (copy มาใส่ไฟล์นี้)
  await repo.confirmRuleSet('มันสำปะหลัง', '  ดร.ทดสอบ ');
  expect(repo.ruleSetFor('มันสำปะหลัง')!.confirmedBy, 'ดร.ทดสอบ');
  expect(repo.ruleSetFor('มันสำปะหลัง')!.confirmedAt, t);
  await repo.saveRuleSet(repo.ruleSetFor('มันสำปะหลัง')!);
  expect(repo.ruleSetFor('มันสำปะหลัง')!.isConfirmed, isFalse);
});
test('invalid rule is rejected with its Thai message and nothing changes', () async {
  final bad = rules.copyWith(rules: const [NutrientRule(nutrient: Nutrient.n, lowBelow: 50, highFrom: 40, rateLow: 1, rateMedium: 1, rateHigh: 1)]);
  await expectLater(repo.saveRuleSet(bad), throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('น้อยกว่า'))));
  expect(repo.ruleSets, isEmpty);
});
test('Phase 1 mutations keep rule sets and prices', () async {
  await repo.saveRuleSet(rules);
  await repo.setPrices(const FertilizerPrices(urea: 20));
  await repo.addFarm(name: 'X');
  await repo.addRound(plotId: SeedIds.plotC, points: [Mock.points.first]);
  await repo.deletePlot(SeedIds.plotB);
  expect(repo.ruleSets, hasLength(1));
  expect(repo.prices.urea, 20);
  expect(store.current!.ruleSets, hasLength(1));
});
test('confirm/delete unknown crop throw StateError; blank expert name ArgumentError; negative price ArgumentError', () async { /* ... ตามชื่อ */ });
```

- [ ] **Step 2: Run** `flutter test test/data/farm_repository_test.dart` — FAIL
- [ ] **Step 3: Implement** ตาม Interfaces
- [ ] **Step 4: Run** `flutter analyze` + `flutter test` — ผ่าน
- [ ] **Step 5: Commit** `feat(data): manage fertilizer rule sets, prices and expert confirmation`

---

### Task 4: หน้าตารางอัตราปุ๋ย + ราคา

**Files:**
- Create: `lib/screens/fertilizer_screens.dart` (`FertilizerRulesScreen`, `RuleSetEditScreen`)
- Modify: `lib/screens/main_tabs.dart` (MoreTab), `lib/screens/catalog.dart`
- Test: `test/screens/fertilizer_rules_test.dart`

**Interfaces:**
- Consumes: Task 3 repository API, `AppScope`, `formatWhen`
- Produces:
  - `FertilizerRulesScreen()` — title `'ตารางอัตราปุ๋ย'`; `InfoBox(tone: Tone.amber)` หัวข้อ `'ตัวเลขทุกค่าต้องมาจากแหล่งอ้างอิงและผู้เชี่ยวชาญ'`; รายการพืชที่มีตาราง (`ListRowCard`: title = crop, subtitle = `'ยืนยันโดย <ชื่อ> • <formatWhen>'` หรือ `'ยังไม่ผ่านการยืนยัน'`, tone green/amber) → แตะ = `RuleSetEditScreen(crop:)`; ว่าง → `InfoBox` `'ยังไม่มีตารางอัตราปุ๋ย'`; ปุ่ม `'เพิ่มตารางพืช'` → `RuleSetEditScreen()`; ส่วน `'ราคาปุ๋ย (บาท/กก.)'` มี 3 ช่องตัวเลข (key `price-urea`/`price-tsp`/`price-mop`, ว่าง = 0) + ปุ่ม `'บันทึกราคา'`
  - `RuleSetEditScreen({super.key, this.crop})` — crop null = เพิ่มใหม่ (picker พืช `['มันสำปะหลัง','ข้าว','อ้อย','ข้าวโพด','อื่น ๆ']` เลือกเฉพาะที่ยังไม่มีตาราง), มี crop = แก้ (แสดงชื่อพืช ไม่ให้เปลี่ยน); ช่อง `'แหล่งอ้างอิง'` (key `rule-source`); แต่ละธาตุ N/P₂O₅/K₂O มีสวิตช์ "ใช้ธาตุนี้" + 5 ช่องตัวเลข key `'<n|p|k>-<lowBelow|highFrom|rateLow|rateMedium|rateHigh>'` (เช่น `n-lowBelow`) ป้าย `'ต่ำกว่า (mg/kg)'`, `'สูงตั้งแต่ (mg/kg)'`, `'อัตรา ระดับต่ำ (กก./ไร่)'`, `'…ปานกลาง…'`, `'…สูง…'`
  - บันทึก: ช่องที่เปิดใช้ว่างหรือ parse ไม่ได้ → toast `'กรอกตัวเลขให้ครบทุกช่อง'`; repo โยน `ArgumentError` → toast ข้อความนั้น; สำเร็จ → pop + toast `'บันทึกตารางแล้ว (รอผู้เชี่ยวชาญยืนยัน)'`
  - โหมดแก้: แสดงสถานะยืนยัน; ปุ่ม `'ยืนยันตาราง (ผู้เชี่ยวชาญ)'` → dialog ช่องชื่อ (key `expert-name`) ปุ่ม `'ยืนยัน'` → `confirmRuleSet` → toast `'ยืนยันตารางแล้ว'`; ปุ่มลบ (`confirm(... ok: 'ลบ', danger: true)`) → `deleteRuleSet` → pop
  - ใช้ `TextInputType.numberWithOptions(decimal: true)` สำหรับช่องตัวเลข
  - MoreTab: ใต้ `SectionHeader('รายงาน')` เพิ่ม `item(Icons.science_outlined, 'ตารางอัตราปุ๋ย', 'ผู้เชี่ยวชาญกรอกและยืนยัน', const FertilizerRulesScreen(), tone: Tone.amber)`
  - catalog: เพิ่ม `_Entry('NEW-09', 'Fertilizer Rules', () => const FertilizerRulesScreen())`, `_Entry('NEW-10', 'Rule Set Editor', () => const RuleSetEditScreen())`

- [ ] **Step 1: Write failing widget tests** (ใช้ `seededRepo()`, `wrap()`; จอสูงถ้า list lazy)

```dart
testWidgets('add a rule set for rice, then it is listed as unconfirmed', (tester) async { /* RuleSetEditScreen() → เลือก 'ข้าว' → source 'ทดสอบ' → เปิดเฉพาะ N กรอก 20/40/10/6/3 → บันทึก → repo.ruleSetFor('ข้าว')!.ruleFor(Nutrient.n)!.rateHigh == 3, isConfirmed false */ });
testWidgets('empty field shows a message and saves nothing', (tester) async { /* เปิด N แต่เว้น n-rateHigh → บันทึก → find.text('กรอกตัวเลขให้ครบทุกช่อง'), repo.ruleSets isEmpty */ });
testWidgets('inverted thresholds show the repository message', (tester) async { /* n-lowBelow 50, n-highFrom 40 → toast contains 'น้อยกว่า' */ });
testWidgets('expert confirms a rule set', (tester) async { /* repo.saveRuleSet(rules) ก่อน → RuleSetEditScreen(crop:'มันสำปะหลัง') → ยืนยัน → พิมพ์ชื่อ → 'ยืนยัน' → repo...isConfirmed true */ });
testWidgets('prices: blank saves as 0', (tester) async { /* FertilizerRulesScreen → price-urea '20' (อีก 2 ช่องว่าง) → บันทึกราคา → repo.prices.urea 20, tsp 0 */ });
```

- [ ] **Step 2: Run** `flutter test test/screens/fertilizer_rules_test.dart` — FAIL
- [ ] **Step 3: Implement** ตาม Interfaces
- [ ] **Step 4: Run** `flutter analyze` + `flutter test` — ผ่าน (รวม catalog test)
- [ ] **Step 5: Commit** `feat(fertilizer): add rule table editor, expert confirmation and prices`

---

### Task 5: หน้าคำนวณปุ๋ยของแปลง

**Files:**
- Modify: `lib/screens/fertilizer_screens.dart` (`FertilizerScreen`), `lib/screens/farm_screens.dart` (ทางเข้าใน PlotDetail), `lib/screens/catalog.dart`
- Test: `test/screens/fertilizer_screen_test.dart`

**Interfaces:**
- Consumes: Task 2 `calculateFertilizer`/`kStraightFertilizers`, Task 3 repository, `PlotRecord.rai`, `repo.latestRound`
- Produces:
  - `FertilizerScreen({super.key, this.plotId})` — null → `SeedIds.plotA`; ไม่พบแปลง → `InfoBox` `'ไม่พบแปลงนี้'`; title `'ปุ๋ยที่ควรใส่'`
  - บนสุดเสมอ: `InfoBox(tone: Tone.amber, title: 'N-P-K เป็นค่าประมาณ ยังไม่สอบเทียบ', body: 'ใช้ประกอบการตัดสินใจเท่านั้น')`
  - หัวการ์ด: ชื่อแปลง, `'<crop> • <rai 1 ตำแหน่ง> ไร่ (พื้นที่โดยประมาณ)'`, `'ผลวัด <formatWhen(takenAt)>'`
  - `issue == noRound` → `InfoBox` `'ยังไม่มีผลการวัด'`; `noRules` → `InfoBox` `'ยังไม่มีตารางอัตราปุ๋ยของ<crop>'` + ปุ่ม `'ไปที่ตารางอัตราปุ๋ย'` → `FertilizerRulesScreen()`; ไม่แสดงตัวเลขปุ๋ย
  - ปกติ: สถานะตาราง — ยืนยันแล้ว `Pill('ยืนยันโดย <ชื่อ>', tone: green)` / ยังไม่ยืนยัน `InfoBox(tone: Tone.red, title: 'ตารางอัตราปุ๋ยยังไม่ผ่านการยืนยันจากผู้เชี่ยวชาญ')`; `'แหล่งอ้างอิง: <source>'`
  - ส่วนธาตุ: ต่อธาตุ `'<label> <measured 0 ตำแหน่ง> mg/kg'` + `Pill(levelLabel)` + `'<ratePerRai 1 ตำแหน่ง> กก./ไร่'`
  - ส่วนปุ๋ย: ต่อ product `name`, `'<kgPerRai 1 ตำแหน่ง> กก./ไร่ • รวม <totalKg 1 ตำแหน่ง> กก.'`, ต้นทุน `'<cost 0 ตำแหน่ง> บาท'` หรือ `'—'`; รวม `'ต้นทุนรวม <totalCost 0 ตำแหน่ง> บาท'` หรือ `'ต้นทุนรวม —'`; ไม่มี product → `'ไม่ต้องใส่ปุ๋ยเดี่ยวตามตารางนี้'`
  - PlotDetailScreen แท็บภาพรวม: ต่อท้าย `OutlinedButton.icon(icon: Icon(Icons.science_outlined), label: Text('คำนวณปุ๋ย'), onPressed: → FertilizerScreen(plotId: p.id))` (ต้องส่ง plotId เข้า `_overview`)
  - catalog: `_Entry('NEW-11', 'Fertilizer Plan', () => const FertilizerScreen())`

- [ ] **Step 1: Write failing widget tests**

```dart
testWidgets('plot A with confirmed rules shows amounts and costs', (tester) async {
  final repo = await seededRepo();
  await repo.saveRuleSet(rules);                       // rules จาก Task 2 (copy)
  await repo.confirmRuleSet('มันสำปะหลัง', 'ดร.ทดสอบ');
  await repo.setPrices(const FertilizerPrices(urea: 20, tsp: 25, mop: 18));
  await tester.pumpWidget(wrap(repo, const FertilizerScreen(plotId: SeedIds.plotA)));
  expect(find.text('N-P-K เป็นค่าประมาณ ยังไม่สอบเทียบ'), findsOneWidget);
  expect(find.text('ยืนยันโดย ดร.ทดสอบ'), findsOneWidget);
  expect(find.text('สูง'), findsOneWidget);
  expect(find.textContaining('6.5 กก./ไร่'), findsOneWidget);
});
testWidgets('unconfirmed rules show the red warning', (tester) async { /* ไม่ confirm → find.text('ตารางอัตราปุ๋ยยังไม่ผ่านการยืนยันจากผู้เชี่ยวชาญ') */ });
testWidgets('no price shows dash for total', (tester) async { /* ไม่ setPrices → find.text('ต้นทุนรวม —') */ });
testWidgets('plot without round explains and shows no amounts', (tester) async { /* plotB → 'ยังไม่มีผลการวัด', find.textContaining('กก./ไร่') findsNothing */ });
testWidgets('crop without table links to rules screen', (tester) async { /* plotA ไม่มีตาราง → tap 'ไปที่ตารางอัตราปุ๋ย' → find.text('ตารางอัตราปุ๋ย') */ });
testWidgets('plot detail opens fertilizer screen', (tester) async { /* PlotDetailScreen(plotId: plotA) → tap 'คำนวณปุ๋ย' → find.text('ปุ๋ยที่ควรใส่') */ });
```

- [ ] **Step 2: Run** `flutter test test/screens/fertilizer_screen_test.dart` — FAIL
- [ ] **Step 3: Implement** ตาม Interfaces
- [ ] **Step 4: Run** `flutter analyze` + `flutter test` — ผ่าน
- [ ] **Step 5: Commit** `feat(fertilizer): add per-plot fertilizer plan screen`

---

### Task 6: README + ตรวจบน MuMu (Opus ทำเอง)

- [ ] README: แทนบรรทัด `- ไม่ให้คำแนะนำปุ๋ย / ชนิดพืช — AI ให้เฉพาะ "ข้อสังเกต" เพื่อคัดกรอง` ด้วย `- คำแนะนำปุ๋ยคำนวณจากตารางที่ผู้เชี่ยวชาญยืนยันเท่านั้น และแสดงคำเตือนเสมอ — แอปไม่มีตัวเลขอัตราปุ๋ยในตัว; AI ยังให้เฉพาะ "ข้อสังเกต"`; เพิ่มหัวข้อ "คำนวณปุ๋ย" สั้น ๆ (ที่อยู่หน้า, หน่วย, การยืนยัน)
- [ ] `flutter analyze` / `flutter test` ผ่าน
- [ ] MuMu: ติดตั้งทับ build Phase 1 (ข้อมูล v1 เดิม) → ฟาร์ม/แปลงยังอยู่ (F8); กรอกตาราง มันสำปะหลัง → หน้า "คำนวณปุ๋ย" แปลง A แสดงคำเตือนแดง → ยืนยัน → เขียว → แก้ตาราง → แดงอีกครั้ง → ปิด/เปิดแอป ตารางและราคายังอยู่
- [ ] Commit `docs: update fertilizer principle and usage`
