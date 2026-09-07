import 'campus_point.dart';

class CampusObstacle {
  final String id;
  final CampusPoint position;
  final String? zoneId;

  const CampusObstacle({required this.id, required this.position, this.zoneId});
}

class CampusChargingStation {
  final String id;
  final String name;
  final CampusPoint position;

  const CampusChargingStation({
    required this.id,
    required this.name,
    required this.position,
  });
}
