import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme.dart';

enum MarkerKind { normal, watch, check, done, next, todo, plan, vertex }

class PlotMarker {
  final Offset pos; // normalised 0..1
  final MarkerKind kind;
  final String? label;
  const PlotMarker(this.pos, this.kind, {this.label});
}

MarkerKind kindForStatus(SoilStatus s) => switch (s) {
      SoilStatus.normal => MarkerKind.normal,
      SoilStatus.watch => MarkerKind.watch,
      SoilStatus.check => MarkerKind.check,
    };

/// Builds markers for the sample measurement points, coloured by layer.
List<PlotMarker> soilMarkers({int layer = 0, bool labels = false}) => [
      for (final p in Mock.points)
        PlotMarker(p.pos, kindForStatus(Mock.layerStatus(p, layer)), label: labels ? p.id : null),
    ];

/// Lightweight map of a plot drawn with CustomPaint (no tiles / API key needed
/// for the UI prototype). Replace with flutter_map later.
class PlotMap extends StatelessWidget {
  const PlotMap({
    super.key,
    this.markers = const [],
    this.polygon = Mock.polygon,
    this.closed = true,
    this.zones = false,
    this.grid = false,
    this.user,
    this.routeTo,
    this.height = 260,
    this.radius = 16,
    this.onTapMarker,
    this.onTapMap,
  });

  final List<PlotMarker> markers;
  final List<Offset> polygon;
  final bool closed;
  final bool zones;
  final bool grid;
  final Offset? user;
  final Offset? routeTo;
  final double height;
  final double radius;
  final ValueChanged<int>? onTapMarker;
  final ValueChanged<Offset>? onTapMap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, c) {
            final size = Size(c.maxWidth, height);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                final local = d.localPosition;
                if (onTapMarker != null) {
                  var best = -1;
                  var bestDist = 28.0;
                  for (var i = 0; i < markers.length; i++) {
                    final m = markers[i].pos;
                    final dist = (Offset(m.dx * size.width, m.dy * size.height) - local).distance;
                    if (dist < bestDist) {
                      best = i;
                      bestDist = dist;
                    }
                  }
                  if (best >= 0) {
                    onTapMarker!(best);
                    return;
                  }
                }
                onTapMap?.call(Offset(local.dx / size.width, local.dy / size.height));
              },
              child: CustomPaint(
                size: size,
                painter: _PlotPainter(
                  markers: markers,
                  polygon: polygon,
                  closed: closed,
                  zones: zones,
                  grid: grid,
                  user: user,
                  routeTo: routeTo,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlotPainter extends CustomPainter {
  _PlotPainter({
    required this.markers,
    required this.polygon,
    required this.closed,
    required this.zones,
    required this.grid,
    required this.user,
    required this.routeTo,
  });

  final List<PlotMarker> markers;
  final List<Offset> polygon;
  final bool closed;
  final bool zones;
  final bool grid;
  final Offset? user;
  final Offset? routeTo;

  Offset _s(Offset n, Size size) => Offset(n.dx * size.width, n.dy * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.mapBg);

    // decorative road / canal
    final road = Path()
      ..moveTo(0, size.height * 0.82)
      ..cubicTo(size.width * 0.3, size.height * 0.74, size.width * 0.6, size.height * 0.95, size.width, size.height * 0.84);
    canvas.drawPath(
      road,
      Paint()
        ..color = AppColors.mapRoad
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    if (polygon.isNotEmpty) {
      final path = Path()..moveTo(_s(polygon.first, size).dx, _s(polygon.first, size).dy);
      for (final p in polygon.skip(1)) {
        final o = _s(p, size);
        path.lineTo(o.dx, o.dy);
      }
      if (closed && polygon.length >= 3) {
        path.close();
        canvas.drawPath(path, Paint()..color = AppColors.mapPlot);
      }
      canvas.save();
      if (closed && polygon.length >= 3) canvas.clipPath(path);
      if (zones) {
        final amber = Paint()
          ..shader = RadialGradient(colors: const [Color(0x66D49717), Color(0x00D49717)])
              .createShader(Rect.fromCircle(center: _s(const Offset(0.52, 0.78), size), radius: size.width * 0.28));
        canvas.drawCircle(_s(const Offset(0.52, 0.78), size), size.width * 0.28, amber);
        final green = Paint()
          ..shader = RadialGradient(colors: const [Color(0x332F7D4A), Color(0x002F7D4A)])
              .createShader(Rect.fromCircle(center: _s(const Offset(0.40, 0.30), size), radius: size.width * 0.35));
        canvas.drawCircle(_s(const Offset(0.40, 0.30), size), size.width * 0.35, green);
      }
      canvas.restore();
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (grid) {
      final xs = markers.map((m) => m.pos.dx).toSet().toList()..sort();
      final ys = markers.map((m) => m.pos.dy).toSet().toList()..sort();
      final gp = Paint()
        ..color = AppColors.mapRoad
        ..strokeWidth = 1;
      if (xs.isNotEmpty && ys.isNotEmpty) {
        for (final x in xs) {
          _dashed(canvas, _s(Offset(x, ys.first), size) - const Offset(0, 10), _s(Offset(x, ys.last), size) + const Offset(0, 10), gp);
        }
        for (final y in ys) {
          _dashed(canvas, _s(Offset(xs.first, y), size) - const Offset(10, 0), _s(Offset(xs.last, y), size) + const Offset(10, 0), gp);
        }
      }
    }

    if (user != null && routeTo != null) {
      _dashed(
        canvas,
        _s(user!, size),
        _s(routeTo!, size),
        Paint()
          ..color = AppColors.blue
          ..strokeWidth = 2,
        dash: 6,
        gap: 4,
      );
    }

    for (final m in markers) {
      final c = _s(m.pos, size);
      switch (m.kind) {
        case MarkerKind.normal:
        case MarkerKind.watch:
        case MarkerKind.check:
          final color = m.kind == MarkerKind.normal
              ? AppColors.green
              : m.kind == MarkerKind.watch
                  ? AppColors.amber
                  : AppColors.red;
          canvas.drawCircle(c, 9, Paint()..color = Colors.white);
          canvas.drawCircle(c, 6, Paint()..color = color);
        case MarkerKind.done:
          canvas.drawCircle(c, 7, Paint()..color = AppColors.green);
        case MarkerKind.next:
          canvas.drawCircle(c, 15, Paint()..color = const Color(0xFFD6E7F5));
          canvas.drawCircle(c, 8, Paint()..color = AppColors.blue);
        case MarkerKind.todo:
          canvas.drawCircle(c, 7, Paint()..color = Colors.white);
          canvas.drawCircle(
              c,
              7,
              Paint()
                ..color = AppColors.hint
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.6);
        case MarkerKind.plan:
          canvas.drawCircle(c, 7, Paint()..color = Colors.white);
          canvas.drawCircle(
              c,
              7,
              Paint()
                ..color = AppColors.green
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2);
        case MarkerKind.vertex:
          canvas.drawCircle(c, 7, Paint()..color = Colors.white);
          canvas.drawCircle(
              c,
              7,
              Paint()
                ..color = AppColors.green
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.2);
      }
      if (m.label != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: m.label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, c - Offset(tp.width / 2, 22));
      }
    }

    if (user != null) {
      final u = _s(user!, size);
      canvas.drawCircle(u, 13, Paint()..color = const Color(0xFFCFE2F3));
      canvas.drawCircle(u, 7, Paint()..color = Colors.white);
      canvas.drawCircle(u, 5, Paint()..color = AppColors.blue);
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint p, {double dash = 3, double gap = 4}) {
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    double t = 0;
    while (t < total) {
      final end = math.min(t + dash, total);
      canvas.drawLine(a + dir * t, a + dir * end, p);
      t += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _PlotPainter old) => true;
}

/// Simple line chart for trends (no chart package needed).
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.values, required this.labels, this.height = 150, this.unit = ''});
  final List<double> values;
  final List<String> labels;
  final double height;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _TrendPainter(values, labels, unit)),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.labels, this.unit);
  final List<double> values;
  final List<String> labels;
  final String unit;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const left = 8.0, right = 8.0, top = 18.0, bottom = 24.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    if (hi - lo < 1e-6) {
      hi += 1;
      lo -= 1;
    }
    final pad = (hi - lo) * 0.2;
    lo -= pad;
    hi += pad;

    final axis = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    canvas.drawLine(Offset(left, top + h), Offset(left + w, top + h), axis);

    Offset pt(int i) {
      final x = left + (values.length == 1 ? w / 2 : w * i / (values.length - 1));
      final y = top + h - (values[i] - lo) / (hi - lo) * h;
      return Offset(x, y);
    }

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < values.length; i++) {
      final p = pt(i);
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(p, 4, Paint()..color = AppColors.green);
      _text(canvas, '${values[i].toStringAsFixed(values[i] % 1 == 0 ? 0 : 1)}$unit', p - const Offset(0, 16),
          const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.dark));
      if (i < labels.length) {
        _text(canvas, labels[i], Offset(p.dx, top + h + 14), const TextStyle(fontSize: 10, color: AppColors.muted));
      }
    }
  }

  void _text(Canvas canvas, String s, Offset center, TextStyle style) {
    final tp = TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.values != values;
}
