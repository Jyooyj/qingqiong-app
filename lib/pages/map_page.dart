import '../services/campus_demo_coordinator.dart';
import '../widgets/geo_map/campus_geo_preview_page.dart';
import 'package:flutter/material.dart';
import '../widgets/map/map_view_data.dart';

class MapPage extends StatelessWidget {
  const MapPage({
    super.key,
    this.campusCoordinator,
    this.zones = const <MapZoneView>[],
    this.robotPosition,
    this.plannedPath = const <MapPointView>[],
    this.cleanedPath = const <MapPointView>[],
    this.obstacles = const <MapObstacleView>[],
    this.chargingStation,
    this.highlightedWarningCode,
  });

  final CampusDemoCoordinator? campusCoordinator;
  final List<MapZoneView> zones;
  final MapPointView? robotPosition;
  final List<MapPointView> plannedPath;
  final List<MapPointView> cleanedPath;
  final List<MapObstacleView> obstacles;
  final MapPointView? chargingStation;
  final String? highlightedWarningCode;

  @override
  Widget build(BuildContext context) =>
      CampusGeoPreviewPage(coordinator: campusCoordinator);
}
