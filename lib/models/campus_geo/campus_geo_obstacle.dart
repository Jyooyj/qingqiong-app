import 'campus_geo_point.dart';

class CampusGeoObstacle {
  final String id;
  final CampusGeoPoint position;
  final String? zoneId;

  const CampusGeoObstacle({
    required this.id,
    required this.position,
    this.zoneId,
  });
}