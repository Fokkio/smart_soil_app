import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Sample data for the UI prototype. Every number here is illustrative only —
/// production thresholds must come from calibration and expert review.

enum SoilStatus { normal, watch, check }

String statusLabel(SoilStatus s) => switch (s) {
      SoilStatus.normal => 'ปกติ',
      SoilStatus.watch => 'ควรเฝ้าดู',
      SoilStatus.check => 'ควรตรวจก่อน',
    };

Color statusColor(SoilStatus s) => switch (s) {
      SoilStatus.normal => const Color(0xFF2F7D4A),
      SoilStatus.watch => const Color(0xFFD49717),
      SoilStatus.check => const Color(0xFFC84A43),
    };

class Reading {
  final double moisture; // %
  final double temp; // °C
  final double ph;
  final double ec; // mS/cm
  final int n, p, k; // mg/kg — estimate only, not calibrated
  const Reading({
    required this.moisture,
    required this.temp,
    required this.ph,
    required this.ec,
    required this.n,
    required this.p,
    required this.k,
  });
}

class SoilPoint {
  final String id;
  final Offset pos; // normalised 0..1 on the plot map
  final SoilStatus status;
  final Reading r;
  final String zone;
  const SoilPoint(this.id, this.pos, this.status, this.r, this.zone);
}

class Farm {
  final String name;
  final String caretaker;
  final String updated;
  final SoilStatus status;
  final int plots;
  const Farm(this.name, this.caretaker, this.updated, this.status, this.plots);
}

class Plot {
  final String name;
  final String crop;
  final double rai;
  final SoilStatus status;
  final String lastChecked;
  const Plot(this.name, this.crop, this.rai, this.status, this.lastChecked);
}

class HistoryRound {
  final String date;
  final String time;
  final int points;
  final String summary;
  final String tag;
  final int watch;
  final double avgMoisture;
  const HistoryRound(this.date, this.time, this.points, this.summary, this.tag, this.watch, this.avgMoisture);
}

class Mock {
  static const farmName = 'ฟาร์ม มมส.';
  static const plotName = 'แปลงมันสำปะหลัง A';
  static const lastMeasured = 'วันนี้ 14:32';

  static const farms = <Farm>[
    Farm('ฟาร์ม มมส. (นำร่อง)', 'ผู้ดูแล: เจ้าหน้าที่ฟาร์ม • วันนี้', 'วันนี้', SoilStatus.normal, 3),
    Farm('จุดสอบเทียบ (แล็บ)', 'ผู้ดูแล: ทีมโครงการ • เมื่อวาน', 'เมื่อวาน', SoilStatus.watch, 2),
    Farm('แปลงที่ 2 (ระยะกลาง)', 'ผู้ดูแล: เจ้าหน้าที่ฟาร์ม • 2 วันก่อน', '2 วันก่อน', SoilStatus.normal, 4),
  ];

  static const plots = <Plot>[
    Plot('แปลงมันสำปะหลัง A', 'มันสำปะหลัง', 12.4, SoilStatus.normal, 'ตรวจล่าสุด 2 ชม. ที่แล้ว'),
    Plot('แปลงมันสำปะหลัง B', 'มันสำปะหลัง', 8.1, SoilStatus.watch, 'ตรวจล่าสุด วันนี้ 10:05'),
    Plot('แปลงข้าว C', 'ข้าว', 15.0, SoilStatus.normal, 'ตรวจล่าสุด เมื่อวาน'),
  ];

  /// Plot boundary (normalised) used on every map.
  static const polygon = <Offset>[
    Offset(0.06, 0.10),
    Offset(0.64, 0.04),
    Offset(0.95, 0.22),
    Offset(0.93, 0.88),
    Offset(0.42, 0.96),
    Offset(0.04, 0.78),
  ];

  static final points = <SoilPoint>[
    _p(1, 0.20, 0.22, SoilStatus.normal, 29, 6.3, 1.0, 'ด้านบน'),
    _p(2, 0.38, 0.18, SoilStatus.normal, 30, 6.2, 1.1, 'ด้านบน'),
    _p(3, 0.56, 0.16, SoilStatus.normal, 31, 6.1, 1.0, 'ด้านบน'),
    _p(4, 0.76, 0.26, SoilStatus.normal, 30, 6.4, 1.2, 'ด้านบน'),
    _p(5, 0.18, 0.44, SoilStatus.normal, 28, 6.2, 1.1, 'กลางแปลง'),
    _p(6, 0.40, 0.40, SoilStatus.normal, 29, 6.3, 1.0, 'กลางแปลง'),
    _p(7, 0.60, 0.42, SoilStatus.normal, 27, 6.2, 1.1, 'กลางแปลง'),
    _p(8, 0.42, 0.78, SoilStatus.watch, 22, 6.2, 1.1, 'ด้านล่าง'),
    _p(9, 0.62, 0.74, SoilStatus.watch, 23, 6.1, 1.2, 'ด้านล่าง'),
    _p(10, 0.80, 0.48, SoilStatus.normal, 29, 6.3, 1.1, 'กลางแปลง'),
    _p(11, 0.22, 0.66, SoilStatus.normal, 27, 6.0, 1.0, 'ด้านล่าง'),
    _p(12, 0.80, 0.70, SoilStatus.normal, 28, 6.2, 1.5, 'ด้านล่าง'),
    _p(13, 0.30, 0.86, SoilStatus.normal, 26, 6.1, 1.0, 'ด้านล่าง'),
    _p(14, 0.62, 0.58, SoilStatus.normal, 28, 6.3, 1.1, 'กลางแปลง'),
  ];

  static SoilPoint _p(int i, double x, double y, SoilStatus s, double m, double ph, double ec, String zone) {
    return SoilPoint(
      '#${i.toString().padLeft(2, '0')}',
      Offset(x, y),
      s,
      Reading(moisture: m, temp: 27.4, ph: ph, ec: ec, n: 42, p: 18, k: 56),
      zone,
    );
  }

  static SoilPoint get focusPoint => points[7];

  static const history = <HistoryRound>[
    HistoryRound('วันนี้', '14:32', 14, 'ตรวจครบ 14 จุด • ค่าส่วนใหญ่ปกติ', '2 จุดเฝ้าดู', 2, 28),
    HistoryRound('30 ก.ย.', '09:10', 12, 'ตรวจครบ 12 จุด • ความชื้นเฉลี่ย 24%', 'ดูผลเปรียบเทียบ', 5, 24),
    HistoryRound('21 ก.ย.', '15:24', 11, 'ตรวจครบ 11 จุด • pH 6.1 • EC 1.0', 'ปกติ', 1, 26),
    HistoryRound('8 ก.ย.', '10:02', 10, 'ตรวจครบ 10 จุด • ก่อนรอบเพาะปลูก', 'ประวัติเริ่มต้น', 0, 23),
  ];

  static double avg(double Function(SoilPoint p) f) =>
      points.map(f).reduce((a, b) => a + b) / points.length;

  /// Status of a point for a given map layer (0 overview, 1 moisture, 2 pH, 3 EC).
  static SoilStatus layerStatus(SoilPoint p, int layer) {
    switch (layer) {
      case 1:
        return p.r.moisture < 24 ? SoilStatus.watch : SoilStatus.normal;
      case 2:
        return (p.r.ph < 5.8 || p.r.ph > 6.8) ? SoilStatus.watch : SoilStatus.normal;
      case 3:
        return p.r.ec > 1.4 ? SoilStatus.watch : SoilStatus.normal;
      default:
        return p.status;
    }
  }

  /// Shoelace area of a normalised polygon, scaled so the full map ≈ 30 rai.
  static double areaRai(List<Offset> poly) {
    if (poly.length < 3) return 0;
    double a = 0;
    for (var i = 0; i < poly.length; i++) {
      final p1 = poly[i];
      final p2 = poly[(i + 1) % poly.length];
      a += p1.dx * p2.dy - p2.dx * p1.dy;
    }
    return (a.abs() / 2) * 30;
  }

  static double distance(Offset a, Offset b) => math.sqrt(math.pow(a.dx - b.dx, 2) + math.pow(a.dy - b.dy, 2));
}
