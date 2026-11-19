import 'package:flutter/material.dart';

import 'mock_data.dart';

class FarmRecord {
  final String id, name, caretaker, location, note;
  final bool notify;
  final DateTime updatedAt;

  const FarmRecord({
    required this.id,
    required this.name,
    required this.caretaker,
    required this.location,
    required this.note,
    required this.notify,
    required this.updatedAt,
  });

  FarmRecord copyWith({
    String? id,
    String? name,
    String? caretaker,
    String? location,
    String? note,
    bool? notify,
    DateTime? updatedAt,
  }) =>
      FarmRecord(
        id: id ?? this.id,
        name: name ?? this.name,
        caretaker: caretaker ?? this.caretaker,
        location: location ?? this.location,
        note: note ?? this.note,
        notify: notify ?? this.notify,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'caretaker': caretaker,
        'location': location,
        'note': note,
        'notify': notify,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FarmRecord.fromJson(Map<String, dynamic> j) => FarmRecord(
        id: j['id'] as String,
        name: j['name'] as String,
        caretaker: j['caretaker'] as String,
        location: j['location'] as String,
        note: j['note'] as String,
        notify: j['notify'] as bool,
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

class PlotRecord {
  final String id, farmId, name, crop, note;
  final List<Offset> boundary;
  final bool archived;
  final DateTime createdAt;

  const PlotRecord({
    required this.id,
    required this.farmId,
    required this.name,
    required this.crop,
    required this.note,
    required this.boundary,
    required this.archived,
    required this.createdAt,
  });

  double get rai => Mock.areaRai(boundary);

  PlotRecord copyWith({
    String? id,
    String? farmId,
    String? name,
    String? crop,
    String? note,
    List<Offset>? boundary,
    bool? archived,
    DateTime? createdAt,
  }) =>
      PlotRecord(
        id: id ?? this.id,
        farmId: farmId ?? this.farmId,
        name: name ?? this.name,
        crop: crop ?? this.crop,
        note: note ?? this.note,
        boundary: boundary ?? this.boundary,
        archived: archived ?? this.archived,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmId': farmId,
        'name': name,
        'crop': crop,
        'note': note,
        'boundary': [
          for (final o in boundary) [o.dx, o.dy]
        ],
        'archived': archived,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PlotRecord.fromJson(Map<String, dynamic> j) => PlotRecord(
        id: j['id'] as String,
        farmId: j['farmId'] as String,
        name: j['name'] as String,
        crop: j['crop'] as String,
        note: j['note'] as String,
        boundary: [
          for (final o in (j['boundary'] as List))
            Offset((o[0] as num).toDouble(), (o[1] as num).toDouble())
        ],
        archived: j['archived'] as bool,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class MeasurementRound {
  final String id, plotId;
  final DateTime takenAt;
  final List<SoilPoint> points;

  const MeasurementRound({
    required this.id,
    required this.plotId,
    required this.takenAt,
    required this.points,
  });

  SoilStatus get status => worstStatus(points.map((p) => p.status));

  int get watchCount => points.where((p) => p.status != SoilStatus.normal).length;

  double? avg(double Function(Reading r) f) {
    if (points.isEmpty) return null;
    return points.map((p) => f(p.r)).reduce((a, b) => a + b) / points.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plotId': plotId,
        'takenAt': takenAt.toIso8601String(),
        'points': [for (final p in points) soilPointToJson(p)],
      };

  factory MeasurementRound.fromJson(Map<String, dynamic> j) => MeasurementRound(
        id: j['id'] as String,
        plotId: j['plotId'] as String,
        takenAt: DateTime.parse(j['takenAt'] as String),
        points: [
          for (final p in (j['points'] as List)) soilPointFromJson(p as Map<String, dynamic>)
        ],
      );
}

Map<String, dynamic> readingToJson(Reading r) => {
      'moisture': r.moisture,
      'temp': r.temp,
      'ph': r.ph,
      'ec': r.ec,
      'n': r.n,
      'p': r.p,
      'k': r.k,
    };

Reading readingFromJson(Map<String, dynamic> j) => Reading(
      moisture: (j['moisture'] as num).toDouble(),
      temp: (j['temp'] as num).toDouble(),
      ph: (j['ph'] as num).toDouble(),
      ec: (j['ec'] as num).toDouble(),
      n: (j['n'] as num).toInt(),
      p: (j['p'] as num).toInt(),
      k: (j['k'] as num).toInt(),
    );

Map<String, dynamic> soilPointToJson(SoilPoint p) => {
      'id': p.id,
      'pos': [p.pos.dx, p.pos.dy],
      'status': p.status.name,
      'r': readingToJson(p.r),
      'zone': p.zone,
    };

SoilPoint soilPointFromJson(Map<String, dynamic> j) {
  final pos = j['pos'] as List;
  return SoilPoint(
    j['id'] as String,
    Offset((pos[0] as num).toDouble(), (pos[1] as num).toDouble()),
    SoilStatus.values.byName(j['status'] as String),
    readingFromJson(j['r'] as Map<String, dynamic>),
    j['zone'] as String,
  );
}

/// Severity order: normal < watch < check. Empty -> normal.
SoilStatus worstStatus(Iterable<SoilStatus> s) {
  var worst = SoilStatus.normal;
  for (final x in s) {
    if (x.index > worst.index) worst = x;
  }
  return worst;
}

const _thaiMonths = [
  'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];

String formatWhen(DateTime t, DateTime now) {
  String two(int v) => v.toString().padLeft(2, '0');
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(t.year, t.month, t.day))
      .inDays;
  // Same-day check via calendar fields avoids DST-length issues in inDays.
  final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
  if (sameDay) return 'วันนี้ ${two(t.hour)}:${two(t.minute)}';
  if (days == 1) return 'เมื่อวาน ${two(t.hour)}:${two(t.minute)}';
  if (days >= 2 && days <= 6) return '$days วันก่อน';
  return '${t.day} ${_thaiMonths[t.month - 1]} ${t.year + 543}';
}
