import 'campus_geo_point.dart';
import 'campus_geo_route.dart';

enum CustomAreaType {
  road('道路'),
  publicArea('公共区域'),
  other('其他');

  const CustomAreaType(this.label);
  final String label;
}

/// Session geometry with a generated closed boundary route for demo cleaning.
class CustomCleaningArea {
  CustomCleaningArea({
    required this.id,
    required String name,
    required this.type,
    required List<CampusGeoPoint> polygon,
    required this.createdAt,
  }) : name = name.trim(),
       polygon = List.unmodifiable(polygon),
       generatedRoute = _routeFor(id, polygon) {
    if (this.name.isEmpty || polygonError(polygon) != null) {
      throw ArgumentError('区域名称和有效地图范围不能为空');
    }
  }

  final String id;
  final String name;
  final CustomAreaType type;
  final List<CampusGeoPoint> polygon;
  final DateTime createdAt;
  final CampusGeoRoute generatedRoute;
  bool get isCustom => true;

  static CampusGeoRoute _routeFor(String id, List<CampusGeoPoint> polygon) {
    return CampusGeoRoute(
      zoneId: id,
      plannedPath: polygon.isEmpty
          ? const []
          : List.unmodifiable([...polygon, polygon.first]),
    );
  }

  static String? polygonError(List<CampusGeoPoint> points) {
    if (points.length < 3) return '请在地图上选择至少 3 个点';
    if (points.any((p) => !p.isValid) ||
        points.toSet().length != points.length) {
      return '请选择不同的有效位置';
    }
    double cross(CampusGeoPoint a, CampusGeoPoint b, CampusGeoPoint c) =>
        (b.longitude - a.longitude) * (c.latitude - a.latitude) -
        (b.latitude - a.latitude) * (c.longitude - a.longitude);
    double area = 0;
    for (var i = 1; i < points.length - 1; i++) {
      area += cross(points.first, points[i], points[i + 1]);
    }
    if (area.abs() < 1e-12) return '所选点不能形成有效范围，请重新选择';
    for (var i = 0; i < points.length; i++) {
      final a = points[i], b = points[(i + 1) % points.length];
      for (var j = i + 2; j < points.length; j++) {
        if (i == 0 && j == points.length - 1) continue;
        final c = points[j], d = points[(j + 1) % points.length];
        if (cross(a, b, c) * cross(a, b, d) <= 0 &&
            cross(c, d, a) * cross(c, d, b) <= 0) {
          return '范围边界不能交叉，请撤销后重新选择';
        }
      }
    }
    return null;
  }
}
