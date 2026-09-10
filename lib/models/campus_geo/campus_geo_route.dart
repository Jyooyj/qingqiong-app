import 'campus_geo_point.dart';

class CampusGeoRoute {
  final String zoneId;
  final List<CampusGeoPoint> plannedPath;

  const CampusGeoRoute({
    required this.zoneId,
    required this.plannedPath,
  });
}