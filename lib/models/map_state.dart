class MapPoint {
  final double x;
  final double y;

  const MapPoint({
    required this.x,
    required this.y,
  });
}

class CleaningZone {
  final String id;
  final String name;
  final List<MapPoint> boundary;

  const CleaningZone({
    required this.id,
    required this.name,
    required this.boundary,
  });
}

class Obstacle {
  final String id;
  final MapPoint position;

  const Obstacle({
    required this.id,
    required this.position,
  });
}

class ChargingStation {
  final String id;
  final String name;
  final MapPoint position;

  const ChargingStation({
    required this.id,
    required this.name,
    required this.position,
  });
}

class RobotMapState {
  final MapPoint robotPosition;
  final List<MapPoint> plannedPath;
  final List<MapPoint> cleanedPath;
  final List<CleaningZone> zones;
  final List<Obstacle> obstacles;
  final ChargingStation chargingStation;

  const RobotMapState({
    required this.robotPosition,
    required this.plannedPath,
    required this.cleanedPath,
    required this.zones,
    required this.obstacles,
    required this.chargingStation,
  });

  RobotMapState copyWith({
    MapPoint? robotPosition,
    List<MapPoint>? plannedPath,
    List<MapPoint>? cleanedPath,
    List<CleaningZone>? zones,
    List<Obstacle>? obstacles,
    ChargingStation? chargingStation,
  }) {
    return RobotMapState(
      robotPosition: robotPosition ?? this.robotPosition,
      plannedPath: plannedPath ?? this.plannedPath,
      cleanedPath: cleanedPath ?? this.cleanedPath,
      zones: zones ?? this.zones,
      obstacles: obstacles ?? this.obstacles,
      chargingStation: chargingStation ?? this.chargingStation,
    );
  }
}