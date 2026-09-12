import '../models/map_state.dart';

class MockMapData {
  static const List<MapPoint> areaAPath = [
    MapPoint(x: 0.15, y: 0.20),
    MapPoint(x: 0.30, y: 0.20),
    MapPoint(x: 0.45, y: 0.20),
    MapPoint(x: 0.60, y: 0.20),
    MapPoint(x: 0.75, y: 0.20),
    MapPoint(x: 0.75, y: 0.35),
    MapPoint(x: 0.60, y: 0.35),
    MapPoint(x: 0.45, y: 0.35),
    MapPoint(x: 0.30, y: 0.35),
    MapPoint(x: 0.15, y: 0.35),
  ];

  static const List<MapPoint> areaBPath = [
    MapPoint(x: 0.15, y: 0.45),
    MapPoint(x: 0.30, y: 0.45),
    MapPoint(x: 0.45, y: 0.45),
    MapPoint(x: 0.60, y: 0.45),
    MapPoint(x: 0.75, y: 0.45),
    MapPoint(x: 0.75, y: 0.60),
    MapPoint(x: 0.60, y: 0.60),
    MapPoint(x: 0.45, y: 0.60),
    MapPoint(x: 0.30, y: 0.60),
    MapPoint(x: 0.15, y: 0.60),
  ];

  static const List<MapPoint> areaCPath = [
    MapPoint(x: 0.15, y: 0.70),
    MapPoint(x: 0.30, y: 0.70),
    MapPoint(x: 0.45, y: 0.70),
    MapPoint(x: 0.60, y: 0.70),
    MapPoint(x: 0.75, y: 0.70),
    MapPoint(x: 0.75, y: 0.85),
    MapPoint(x: 0.60, y: 0.85),
    MapPoint(x: 0.45, y: 0.85),
    MapPoint(x: 0.30, y: 0.85),
    MapPoint(x: 0.15, y: 0.85),
  ];

  static const List<CleaningZone> zones = [
    CleaningZone(
      id: 'A',
      name: 'A区',
      boundary: [
        MapPoint(x: 0.10, y: 0.15),
        MapPoint(x: 0.80, y: 0.15),
        MapPoint(x: 0.80, y: 0.40),
        MapPoint(x: 0.10, y: 0.40),
      ],
    ),
    CleaningZone(
      id: 'B',
      name: 'B区',
      boundary: [
        MapPoint(x: 0.10, y: 0.42),
        MapPoint(x: 0.80, y: 0.42),
        MapPoint(x: 0.80, y: 0.65),
        MapPoint(x: 0.10, y: 0.65),
      ],
    ),
    CleaningZone(
      id: 'C',
      name: 'C区',
      boundary: [
        MapPoint(x: 0.10, y: 0.67),
        MapPoint(x: 0.80, y: 0.67),
        MapPoint(x: 0.80, y: 0.90),
        MapPoint(x: 0.10, y: 0.90),
      ],
    ),
  ];

  static const List<Obstacle> obstacles = [
    Obstacle(id: 'obstacle_01', position: MapPoint(x: 0.52, y: 0.28)),
    Obstacle(id: 'obstacle_02', position: MapPoint(x: 0.38, y: 0.53)),
    Obstacle(id: 'obstacle_03', position: MapPoint(x: 0.62, y: 0.78)),
  ];

  static const ChargingStation chargingStation = ChargingStation(
    id: 'charging_station_01',
    name: '充电桩',
    position: MapPoint(x: 0.08, y: 0.92),
  );

  static List<MapPoint> pathForArea(String area) {
    switch (area) {
      case 'A区':
        return List<MapPoint>.from(areaAPath);

      case 'B区':
        return List<MapPoint>.from(areaBPath);

      case 'C区':
        return List<MapPoint>.from(areaCPath);

      default:
        return List<MapPoint>.from(areaAPath);
    }
  }

  static RobotMapState initialMapState() {
    return RobotMapState(
      robotPosition: chargingStation.position,
      plannedPath: const [],
      cleanedPath: const [],
      zones: zones,
      obstacles: obstacles,
      chargingStation: chargingStation,
    );
  }
}
