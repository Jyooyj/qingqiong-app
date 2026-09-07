import 'package:flutter/material.dart';
import 'current_task_map_card.dart';
import '../../models/campus/campus_point.dart';
import '../../models/campus/campus_zone.dart';
import '../../models/campus/campus_map_objects.dart';

/// Controlled map. Coordinates: 0..1, top-left origin, x right, y down.
/// This widget never starts tasks or advances location data.
class CampusMapView extends StatelessWidget {
  const CampusMapView({
    super.key,
    required this.zones,
    this.selectedZoneId,
    this.robotPosition,
    this.plannedPath = const [],
    this.cleanedPath = const [],
    this.obstacles = const [],
    this.chargingStation,
    this.onZoneTap,
    this.taskData,
    this.onPause,
    this.onResume,
    this.onEmergencyStop,
    this.onReset,
  });

  final List<CampusZone> zones;
  final String? selectedZoneId;
  final CampusPoint? robotPosition;
  final List<CampusPoint> plannedPath;
  final List<CampusPoint> cleanedPath;
  final List<CampusObstacle> obstacles;
  final CampusChargingStation? chargingStation;
  final ValueChanged<String>? onZoneTap;
  final CampusTaskViewData? taskData;
  final VoidCallback? onPause, onResume, onEmergencyStop, onReset;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = box.maxWidth;
      final height = width < 600 ? 380.0 : 480.0;
      final size = Size(width, height);
      final sharedMarker =
          robotPosition != null &&
          chargingStation != null &&
          (Offset(robotPosition!.x * width, robotPosition!.y * height) -
                      Offset(
                        chargingStation!.position.x * width,
                        chargingStation!.position.y * height,
                      ))
                  .distance <
              30;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: height,
              child: GestureDetector(
                key: const Key('campus-map-surface'),
                behavior: HitTestBehavior.opaque,
                onTapUp: onZoneTap == null
                    ? null
                    : (event) {
                        // Reverse paint order makes overlapping polygons deterministic.
                        for (final zone in zones.reversed) {
                          if (_polygon(
                            zone,
                            size,
                          ).contains(event.localPosition)) {
                            onZoneTap!(zone.id);
                            return;
                          }
                        }
                      },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CampusPainter(
                          zones: zones,
                          selected: selectedZoneId,
                          planned: plannedPath,
                          cleaned: cleanedPath,
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 16,
                      top: 16,
                      child: Text(
                        '上海海洋大学',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff163d3a),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 16,
                      top: 42,
                      child: Text(
                        '校园清扫示意图 · 非实测地图',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xff526c66),
                        ),
                      ),
                    ),
                    for (final zone in zones)
                      Positioned(
                        left: (zone.center.x * width - _labelWidth(zone) / 2)
                            .clamp(
                              0.0,
                              (width - _labelWidth(zone)).clamp(0.0, width),
                            ),
                        top: (zone.center.y * height - 12).clamp(
                          0.0,
                          height - 28,
                        ),
                        child: Semantics(
                          button: true,
                          selected: zone.id == selectedZoneId,
                          child: InkWell(
                            key: Key('campus-zone-${zone.id}'),
                            onTap: onZoneTap == null
                                ? null
                                : () => onZoneTap!(zone.id),
                            child: Container(
                              width: _labelWidth(zone),
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 2,
                              ),
                              decoration: BoxDecoration(
                                color: zone.id == selectedZoneId
                                    ? const Color(0xff126b61)
                                    : Colors.white.withValues(alpha: .90),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _label(zone),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: zone.id == selectedZoneId
                                      ? Colors.white
                                      : const Color(0xff264c48),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (chargingStation != null && !sharedMarker)
                      _marker(
                        chargingStation!.position,
                        size,
                        'campus-charger',
                        Icons.ev_station,
                        Colors.indigo,
                        chargingStation!.name,
                      ),
                    for (final obstacle in obstacles)
                      _marker(
                        obstacle.position,
                        size,
                        'campus-obstacle-${obstacle.id}',
                        Icons.warning_amber_rounded,
                        Colors.deepOrange,
                        '障碍点',
                      ),
                    if (sharedMarker)
                      _sharedMarker(chargingStation!.position, size),
                    if (robotPosition != null && !sharedMarker)
                      _marker(
                        robotPosition!,
                        size,
                        'campus-robot',
                        Icons.smart_toy,
                        const Color(0xff123f57),
                        '机器人',
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              Text('┄ 规划路线', style: TextStyle(color: Colors.blue)),
              Text('━ 已清扫轨迹', style: TextStyle(color: Color(0xff168b67))),
              Text('◆ 目标区域', style: TextStyle(color: Color(0xff126b61))),
              Text('▲ 障碍', style: TextStyle(color: Colors.deepOrange)),
              Text('⚡ 充电桩', style: TextStyle(color: Colors.indigo)),
            ],
          ),
          if (taskData != null) ...[
            const SizedBox(height: 12),
            CurrentTaskMapCard(
              data: taskData!,
              onPause: onPause,
              onResume: onResume,
              onEmergencyStop: onEmergencyStop,
              onReset: onReset,
            ),
          ],
        ],
      );
    },
  );

  Widget _sharedMarker(CampusPoint point, Size size) => Positioned(
    left: (point.x * size.width - 30).clamp(
      0.0,
      (size.width - 60).clamp(0.0, size.width),
    ),
    top: (point.y * size.height - 16).clamp(0.0, size.height - 32),
    child: IgnorePointer(
      child: Semantics(
        label: '机器人位于充电桩附近',
        child: Container(
          key: const Key('campus-shared-marker'),
          width: 60,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xff607d8b)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(
                Icons.ev_station,
                key: Key('campus-charger'),
                color: Colors.indigo,
                size: 21,
              ),
              Icon(
                Icons.smart_toy,
                key: Key('campus-robot'),
                color: Color(0xff123f57),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _marker(
    CampusPoint point,
    Size size,
    String key,
    IconData icon,
    Color color,
    String label,
  ) => Positioned(
    left: (point.x * size.width - 14).clamp(
      0.0,
      (size.width - 28).clamp(0.0, size.width),
    ),
    top: (point.y * size.height - 14).clamp(0.0, size.height - 28),
    child: IgnorePointer(
      child: Tooltip(
        message: label,
        child: Container(
          key: Key(key),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
      ),
    ),
  );
}

double _labelWidth(CampusZone zone) =>
    zone.category == CampusZoneCategory.teaching ? 30 : 52;
String _label(CampusZone zone) => switch (zone.id) {
  'teaching_1' => '一教',
  'teaching_2' => '二教',
  'teaching_3' => '三教',
  'main_road' => '主干道',
  _ => zone.name,
};

Path _polygon(CampusZone zone, Size size) {
  final path = Path();
  for (var i = 0; i < zone.polygon.length; i++) {
    final point = zone.polygon[i];
    if (i == 0) {
      path.moveTo(point.x * size.width, point.y * size.height);
    } else {
      path.lineTo(point.x * size.width, point.y * size.height);
    }
  }
  return path..close();
}

class _CampusPainter extends CustomPainter {
  _CampusPainter({
    required this.zones,
    required this.selected,
    required this.planned,
    required this.cleaned,
  });
  final List<CampusZone> zones;
  final String? selected;
  final List<CampusPoint> planned, cleaned;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xffedf3e9),
    );
    final grid = Paint()
      ..color = const Color(0xffe7eee2)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (final zone in zones) {
      final active = zone.id == selected;
      final path = _polygon(zone, size);
      canvas.drawShadow(path, const Color(0xff789080), 2, false);
      canvas.drawPath(
        path,
        Paint()
          ..color = active
              ? const Color(0xff86d4b5)
              : _zoneColor(zone.category),
      );
      // Roof insets and paving are decorative, clipped to supplied boundaries.
      // They do not add new geographic data or change region coordinates.
      canvas.save();
      canvas.clipPath(path);
      final bounds = path.getBounds();
      if (zone.category == CampusZoneCategory.road) {
        final lane = Paint()
          ..color = Colors.white.withValues(alpha: .8)
          ..strokeWidth = 2;
        for (double x = bounds.left + 8; x < bounds.right; x += 22) {
          canvas.drawLine(
            Offset(x, bounds.center.dy),
            Offset(x + 10, bounds.center.dy),
            lane,
          );
        }
      } else {
        final roof = bounds.deflate(5);
        if (!roof.isEmpty) {
          canvas.drawRect(
            roof,
            Paint()
              ..style = PaintingStyle.stroke
              ..color = Colors.white.withValues(alpha: .7)
              ..strokeWidth = 2,
          );
          final windows = Paint()..color = Colors.white.withValues(alpha: .65);
          for (double x = roof.left + 5; x < roof.right - 4; x += 12) {
            canvas.drawRect(Rect.fromLTWH(x, roof.top + 3, 5, 3), windows);
            canvas.drawRect(Rect.fromLTWH(x, roof.bottom - 6, 5, 3), windows);
          }
        }
      }
      canvas.restore();
      canvas.drawPath(
        path,
        Paint()
          ..color = active ? const Color(0xff126b61) : const Color(0xff94afa1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 3 : 1,
      );
    }
    _route(canvas, size, planned, Colors.blue, true);
    _route(canvas, size, cleaned, const Color(0xff168b67), false);
  }

  void _route(
    Canvas canvas,
    Size size,
    List<CampusPoint> points,
    Color color,
    bool dashed,
  ) {
    if (points.length < 2) return;
    final path = Path()
      ..moveTo(points.first.x * size.width, points.first.y * size.height);
    for (final point in points.skip(1)) {
      path.lineTo(point.x * size.width, point.y * size.height);
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = dashed ? 3 : 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 13) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CampusPainter oldDelegate) => true;
}

Color _zoneColor(CampusZoneCategory category) => switch (category) {
  CampusZoneCategory.teaching => const Color(0xffc8dce7),
  CampusZoneCategory.laboratory => const Color(0xffc7d4e7),
  CampusZoneCategory.dining => const Color(0xffeddbbf),
  CampusZoneCategory.dormitory => const Color(0xffdfd3c6),
  CampusZoneCategory.library => const Color(0xffd7d0e5),
  CampusZoneCategory.road => const Color(0xffbdc8c0),
  CampusZoneCategory.publicArea => const Color(0xffd0dfc0),
};
