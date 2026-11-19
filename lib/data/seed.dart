import 'farm_store.dart';
import 'mock_data.dart';
import 'models.dart';

abstract final class SeedIds {
  static const farmMsu = 'farm-msu',
      farmLab = 'farm-lab',
      farm2 = 'farm-2',
      plotA = 'plot-a',
      plotB = 'plot-b',
      plotC = 'plot-c';
}

const _farmIds = [SeedIds.farmMsu, SeedIds.farmLab, SeedIds.farm2];
const _plotIds = [SeedIds.plotA, SeedIds.plotB, SeedIds.plotC];

/// Plain caretaker names matching CreateFarmScreen's picker options
/// (Mock.farms[i].caretaker is a pre-formatted display line, not a name).
const _caretakers = ['เจ้าหน้าที่ฟาร์ม (ผู้ดูแลหลัก)', 'ทีมโครงการ', 'เจ้าหน้าที่ฟาร์ม (ผู้ดูแลหลัก)'];

StoreSnapshot seedFromMock(DateTime now) {
  return StoreSnapshot(
    farms: [
      for (var i = 0; i < Mock.farms.length; i++)
        FarmRecord(
          id: _farmIds[i],
          name: Mock.farms[i].name,
          caretaker: _caretakers[i],
          location: 'อ.กันทรวิชัย จ.มหาสารคาม',
          note: '',
          notify: true,
          updatedAt: now,
        ),
    ],
    plots: [
      for (var i = 0; i < Mock.plots.length; i++)
        PlotRecord(
          id: _plotIds[i],
          farmId: SeedIds.farmMsu,
          name: Mock.plots[i].name,
          crop: Mock.plots[i].crop,
          note: '',
          boundary: Mock.polygon,
          archived: false,
          createdAt: now.add(Duration(microseconds: i)),
        ),
    ],
    rounds: [
      MeasurementRound(
        id: 'round-seed-a',
        plotId: SeedIds.plotA,
        takenAt: now,
        points: Mock.points,
      ),
    ],
  );
}
