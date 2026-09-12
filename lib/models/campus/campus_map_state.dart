import 'campus_map_objects.dart';
import 'campus_point.dart';

class CampusMapState {
  final CampusPoint robotPosition;
  final List<CampusPoint> plannedPath;
  final List<CampusPoint> cleanedPath;
  final List<CampusObstacle> obstacles;
  final CampusChargingStation chargingStation;

  const CampusMapState({
    required this.robotPosition,
    required this.plannedPath,
    required this.cleanedPath,
    required this.obstacles,
    required this.chargingStation,
  });

  CampusMapState copyWith({
    CampusPoint? robotPosition,
    List<CampusPoint>? plannedPath,
    List<CampusPoint>? cleanedPath,
    List<CampusObstacle>? obstacles,
    CampusChargingStation? chargingStation,
  }) {
    return CampusMapState(
      robotPosition: robotPosition ?? this.robotPosition,
      plannedPath: plannedPath ?? this.plannedPath,
      cleanedPath: cleanedPath ?? this.cleanedPath,
      obstacles: obstacles ?? this.obstacles,
      chargingStation: chargingStation ?? this.chargingStation,
    );
  }
}
