import 'campus_point.dart';

class CampusRoute {
  final String zoneId;
  final List<CampusPoint> plannedPath;

  const CampusRoute({
    required this.zoneId,
    required this.plannedPath,
  });
}
