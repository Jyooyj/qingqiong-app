import 'campus_geo_point.dart';

class CampusGeoChargingStation {
  final String id;
  final String name;
  final CampusGeoPoint position;

  const CampusGeoChargingStation({
    required this.id,
    required this.name,
    required this.position,
  });
}