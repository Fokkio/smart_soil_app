import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_soil_app/data/mock_data.dart';
import 'package:smart_soil_app/data/models.dart';

void main() {
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
}
