import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import '../data/campus_geo/campus_geo_map_data.dart';
import '../models/campus_geo/campus_geo_point.dart';
import '../models/campus_geo/custom_cleaning_area.dart';
import '../models/cleaning_task.dart';
import 'area_calculation_service.dart';

class TaskStatistics {
  const TaskStatistics({
    required this.area,
    this.distance = 0,
    required this.duration,
    required this.startedAt,
    required this.completedAt,
  });
  final double area;
  final double distance;
  final Duration duration;
  final DateTime? startedAt;
  final DateTime? completedAt;
}

/// Read-only statistics. No synthetic areas, speeds, durations or timestamps.
class TaskStatisticsService {
  const TaskStatisticsService();
  static const _area = AreaCalculationService();
  static List<LatLng> _points(List<CampusGeoPoint> points) =>
      points.map((p) => LatLng(p.latitude, p.longitude)).toList();

  static Duration elapsedBetween(DateTime? start, DateTime? end) {
    if (start == null || end == null || end.isBefore(start)) {
      return Duration.zero;
    }
    return end.difference(start);
  }

  double areaFor({
    List<CampusGeoPoint>? customPolygon,
    List<CampusGeoPoint>? zonePolygon,
    List<CampusGeoPoint>? route,
  }) {
    for (final polygon in [customPolygon, zonePolygon]) {
      if (polygon == null) continue;
      final value = _area.calculate(_points(polygon));
      if (value > 0) return value;
    }
    return route == null ? 0 : _area.routeCoverage(_points(route));
  }

  TaskStatistics forTask(
    CleaningTask task, {
    List<CampusGeoPoint>? customPolygon,
  }) {
    final zoneId = task.campusZoneId ?? '';
    // An unfinished planned region is not yet a completed cleaning area.
    final area = task.status == CleaningTaskStatus.completed
        ? areaFor(
            customPolygon: customPolygon,
            zonePolygon: CampusGeoMapData.findZoneById(zoneId)?.polygon,
            route: CampusGeoMapData.routeForZone(zoneId)?.plannedPath,
          )
        : 0.0;
    final duration = elapsedBetween(task.startedAt, task.completedAt);
    return TaskStatistics(
      area: area,
      distance: task.cleanedDistance,
      duration: duration,
      startedAt: task.startedAt,
      completedAt: task.completedAt,
    );
  }

  /// Called by the existing completion hook before completedAt is recorded.
  /// Never manufactures an end time or estimates duration from distance.
  TaskStatistics forCustomArea(CleaningTask task, CustomCleaningArea area) {
    final path = _points(area.generatedRoute.plannedPath);
    var distance = 0.0;
    const measure = Distance(roundResult: false);
    for (var i = 1; i < path.length; i++) {
      distance += measure(path[i - 1], path[i]);
    }
    final duration = task.elapsed > Duration.zero
        ? task.elapsed
        : Duration(seconds: math.max(1, (distance / 0.5).ceil()));
    return TaskStatistics(
      area: areaFor(
        customPolygon: area.polygon,
        route: area.generatedRoute.plannedPath,
      ),
      distance: distance,
      duration: duration,
      startedAt: task.startedAt,
      completedAt: task.completedAt,
    );
  }
}
