import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Spherical ring area in square metres, using the mean Earth radius.
/// Chamberlain–Duquette longitude/sine integration; winding is irrelevant.
/// https://github.com/Turfjs/turf/blob/master/packages/turf-area/index.ts
class AreaCalculationService {
  const AreaCalculationService();
  static const earthRadius = 6371008.8;

  double calculate(List<LatLng> polygon) {
    if (polygon.length < 3 || polygon.any((p) => !_valid(p))) return 0;
    final baseline = math.sin(polygon.first.latitudeInRad);
    var sum = 0.0;
    for (var i = 0; i < polygon.length; i++) {
      final a = polygon[i];
      final b = polygon[(i + 1) % polygon.length];
      final delta = _wrap(b.longitudeInRad - a.longitudeInRad);
      sum +=
          delta *
          (math.sin(a.latitudeInRad) +
              math.sin(b.latitudeInRad) -
              2 * baseline);
    }
    return sum.abs() * earthRadius * earthRadius / 2;
  }

  /// Route extent, not a swept footprint: no cleaning width is available.
  /// A convex hull avoids inventing a boundary ordering for a zigzag path.
  double routeCoverage(List<LatLng> route) {
    if (route.length < 3 || route.any((p) => !_valid(p))) return 0;
    final origin = route.first.longitudeInRad;
    final points =
        route
            .map(
              (p) => (
                x: origin + _wrap(p.longitudeInRad - origin),
                y: p.latitudeInRad,
                point: p,
              ),
            )
            .toSet()
            .toList()
          ..sort(
            (a, b) => a.x == b.x ? a.y.compareTo(b.y) : a.x.compareTo(b.x),
          );
    double cross(int a, int b, int c) =>
        (points[b].x - points[a].x) * (points[c].y - points[a].y) -
        (points[b].y - points[a].y) * (points[c].x - points[a].x);
    List<int> half(Iterable<int> indices) {
      final result = <int>[];
      for (final i in indices) {
        while (result.length >= 2 &&
            cross(result[result.length - 2], result.last, i) <= 0) {
          result.removeLast();
        }
        result.add(i);
      }
      return result;
    }

    final indices = List.generate(points.length, (i) => i);
    final lower = half(indices);
    final upper = half(indices.reversed);
    final hull = [
      ...lower.take(lower.length - 1),
      ...upper.take(upper.length - 1),
    ];
    return calculate(hull.map((i) => points[i].point).toList());
  }

  static double _wrap(double radians) =>
      (radians + math.pi) % (2 * math.pi) - math.pi;
  static bool _valid(LatLng point) =>
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude.abs() <= 90 &&
      point.longitude.abs() <= 180;
}
