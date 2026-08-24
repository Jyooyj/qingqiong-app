import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'map_view_data.dart';

class CleaningMapView extends StatelessWidget {
  const CleaningMapView({
    super.key,
    this.zones = const [],
    this.robotPosition,
    this.plannedPath = const [],
    this.cleanedPath = const [],
    this.obstacles = const [],
    this.chargingStation,
    this.highlightedWarningCode,
  });

  final List<MapZoneView> zones;
  final MapPointView? robotPosition;
  final List<MapPointView> plannedPath;
  final List<MapPointView> cleanedPath;
  final List<MapObstacleView> obstacles;
  final MapPointView? chargingStation;
  final String? highlightedWarningCode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.clamp(0.0, 1080.0);
        final height = (constraints.maxWidth >= 900) ? 520.0 : 340.0;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LayoutBuilder(
                      builder: (ctx, inner) {
                        final size = inner.biggest;
                        return Stack(
                          children: [
                            CustomPaint(
                              size: Size(size.width, size.height),
                              painter: _CleaningMapPainter(
                                zones: zones,
                                plannedPath: plannedPath,
                                cleanedPath: cleanedPath,
                                obstacles: obstacles,
                              ),
                            ),
                            // overlay labels and highlights using finite size
                            ..._buildZoneLabels(size),
                            ..._buildHighlights(size),
                            // robot and charger markers as overlay widgets for testing
                            ..._buildMarkers(size),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // legend always outside map, uses Wrap to auto-flow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _Legend(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildZoneLabels(Size size) {
    final widgets = <Widget>[];
    for (final z in zones) {
      if (z.points.isEmpty) continue;
      // compute bounding box and place label near top-left within zone
      final xs = z.points.map((p) => p.x).toList();
      final ys = z.points.map((p) => p.y).toList();
      final minX = xs.reduce(math.min);
      final minY = ys.reduce(math.min);
      var left = (minX * size.width) + 8.0;
      var top = (minY * size.height) + 6.0;
      if (z.id == 'a') {
        left += 18.0;
        top += 18.0;
      }
      widgets.add(
        Positioned(
          left: left,
          top: top,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(z.label, key: Key('zone-label-${z.id}')),
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildHighlights(Size size) {
    final widgets = <Widget>[];
    for (final o in obstacles) {
      if (o.code != null && o.code == highlightedWarningCode) {
        final off = Offset(
          o.position.x * size.width,
          o.position.y * size.height,
        );
        widgets.add(
          Positioned(
            left: off.dx - 12,
            top: off.dy - 12,
            child: Container(
              key: Key('obstacle-highlight-${o.code}'),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellow.withValues(alpha: 0.95),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: Colors.black,
              ),
            ),
          ),
        );

        // label near obstacle but kept away from the route and robot; prefer upper-left.
        final labelLeft = math.max(
          8.0,
          math.min(off.dx - 140.0, size.width - 130.0),
        );
        final labelTop = math.max(
          10.0,
          math.min(off.dy - 30.0, size.height - 36.0),
        );
        final isNarrow = size.width < 420;
        widgets.add(
          Positioned(
            left: isNarrow ? math.max(8.0, off.dx - 80.0) : labelLeft,
            top: isNarrow ? (off.dy - 26.0) : labelTop,
            child: Container(
              key: Key('highlight-label-${o.code}'),
              constraints: const BoxConstraints(maxWidth: 120),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.yellow.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 12),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '路径阻塞 · ${o.code}',
                      style: TextStyle(fontSize: isNarrow ? 12 : 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  List<Widget> _buildMarkers(Size size) {
    final widgets = <Widget>[];
    if (robotPosition != null) {
      final off = Offset(
        robotPosition!.x * size.width,
        robotPosition!.y * size.height,
      );
      widgets.add(
        Positioned(
          left: off.dx - 8,
          top: off.dy - 8,
          child: Container(
            key: const Key('robot-marker'),
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    if (chargingStation != null) {
      final off = Offset(
        chargingStation!.x * size.width,
        chargingStation!.y * size.height,
      );
      widgets.add(
        Positioned(
          left: off.dx - 10,
          top: off.dy - 10,
          child: Container(
            key: const Key('charger-marker'),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Icon(Icons.flash_on, size: 12, color: Colors.white),
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final items = [
      _LegendItem(
        key: const Key('legend-charger'),
        symbol: _LegendCharger(),
        label: '充电桩',
      ),
      _LegendItem(
        key: const Key('legend-robot'),
        symbol: _LegendCircle(color: Colors.black),
        label: '机器人',
      ),
      _LegendItem(
        key: const Key('legend-planned'),
        symbol: _LegendLine(dashed: true, color: Colors.lightBlue),
        label: '规划路线',
      ),
      _LegendItem(
        key: const Key('legend-cleaned'),
        symbol: _LegendLine(dashed: false, color: Colors.green),
        label: '已清扫轨迹',
      ),
      _LegendItem(
        key: const Key('legend-obstacle'),
        symbol: _LegendCircle(color: Colors.red),
        label: '障碍物',
      ),
      _LegendItem(
        key: const Key('legend-warn'),
        symbol: _LegendWarn(),
        label: '路径阻塞告警',
      ),
    ];

    return Card(
      key: const Key('legend-card'),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(spacing: 12, runSpacing: 8, children: items),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.symbol, required this.label, super.key});
  final Widget symbol;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [symbol, const SizedBox(width: 8), Text(label)],
    );
  }
}

class _LegendCircle extends StatelessWidget {
  const _LegendCircle({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _LegendCharger extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: 14,
    decoration: BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(3),
    ),
    child: const Center(
      child: Icon(Icons.flash_on, size: 12, color: Colors.white),
    ),
  );
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({required this.dashed, required this.color});
  final bool dashed;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 36,
    height: 16,
    child: CustomPaint(
      painter: _LegendLinePainter(dashed: dashed, color: color),
    ),
  );
}

class _LegendLinePainter extends CustomPainter {
  _LegendLinePainter({required this.dashed, required this.color});
  final bool dashed;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, size.height / 2);
    if (dashed) {
      final metrics = path.computeMetrics();
      for (final m in metrics) {
        var distance = 0.0;
        while (distance < m.length) {
          final len = 8.0;
          final extract = m.extractPath(distance, distance + len);
          canvas.drawPath(extract, p);
          distance += len + 6.0;
        }
      }
    } else {
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegendWarn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Colors.yellow,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 6),
      const Icon(Icons.warning_amber_rounded, size: 14),
    ],
  );
}

class _CleaningMapPainter extends CustomPainter {
  _CleaningMapPainter({
    required this.zones,
    required this.plannedPath,
    required this.cleanedPath,
    required this.obstacles,
  });

  final List<MapZoneView> zones;
  final List<MapPointView> plannedPath;
  final List<MapPointView> cleanedPath;
  final List<MapObstacleView> obstacles;

  @override
  void paint(Canvas canvas, Size size) {
    final zonePaint = Paint()..color = Colors.grey.shade200;
    final zoneBorder = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey
      ..strokeWidth = 1;

    for (final z in zones) {
      final path = Path();
      if (z.points.isEmpty) continue;
      for (var i = 0; i < z.points.length; i++) {
        final p = z.points[i].toOffset(size);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, zonePaint);
      canvas.drawPath(path, zoneBorder);
    }

    // planned path dashed
    if (plannedPath.length >= 2) {
      final p = Path();
      for (var i = 0; i < plannedPath.length; i++) {
        final o = plannedPath[i].toOffset(size);
        if (i == 0) {
          p.moveTo(o.dx, o.dy);
        } else {
          p.lineTo(o.dx, o.dy);
        }
      }
      final dashPaint = Paint()
        ..color = Colors.lightBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      _drawDashedPath(canvas, p, dashPaint, dash: 6, gap: 4);
    }

    // cleaned path solid
    if (cleanedPath.length >= 2) {
      final p = Path();
      for (var i = 0; i < cleanedPath.length; i++) {
        final o = cleanedPath[i].toOffset(size);
        if (i == 0) {
          p.moveTo(o.dx, o.dy);
        } else {
          p.lineTo(o.dx, o.dy);
        }
      }
      final paint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawPath(p, paint);
    }

    // obstacles (normal red)
    for (final o in obstacles) {
      final pos = o.position.toOffset(size);
      final paint = Paint()..color = Colors.red;
      canvas.drawCircle(pos, 6, paint);
    }

    // charging station and robot intentionally not painted here — overlays draw them
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dash = 5,
    double gap = 3,
  }) {
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      var distance = 0.0;
      while (distance < m.length) {
        final len = dash;
        final extract = m.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += len + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! _CleaningMapPainter) {
      return true;
    }
    final o = oldDelegate;
    bool pointsEqual(List<MapPointView> a, List<MapPointView> b) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i].x != b[i].x || a[i].y != b[i].y) return false;
      }
      return true;
    }

    if (!pointsEqual(plannedPath, o.plannedPath)) {
      return true;
    }
    if (!pointsEqual(cleanedPath, o.cleanedPath)) {
      return true;
    }
    if (obstacles.length != o.obstacles.length) {
      return true;
    }
    for (var i = 0; i < obstacles.length; i++) {
      if (obstacles[i].position.x != o.obstacles[i].position.x ||
          obstacles[i].position.y != o.obstacles[i].position.y ||
          obstacles[i].code != o.obstacles[i].code) {
        return true;
      }
    }
    if (zones.length != o.zones.length) {
      return true;
    }
    for (var i = 0; i < zones.length; i++) {
      final a = zones[i].points;
      final b = o.zones[i].points;
      if (a.length != b.length) {
        return true;
      }
      for (var j = 0; j < a.length; j++) {
        if (a[j].x != b[j].x || a[j].y != b[j].y) {
          return true;
        }
      }
    }
    return false;
  }
}
