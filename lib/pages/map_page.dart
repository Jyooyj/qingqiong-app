import '../widgets/geo_map/campus_geo_preview_page.dart';
import 'package:flutter/material.dart';
import '../widgets/map/map_view_data.dart';
import '../widgets/map/cleaning_map_view.dart';

class MapPage extends StatelessWidget {
  const MapPage({
    super.key,
    this.zones = const <MapZoneView>[],
    this.robotPosition,
    this.plannedPath = const <MapPointView>[],
    this.cleanedPath = const <MapPointView>[],
    this.obstacles = const <MapObstacleView>[],
    this.chargingStation,
    this.highlightedWarningCode,
  });

  final List<MapZoneView> zones;
  final MapPointView? robotPosition;
  final List<MapPointView> plannedPath;
  final List<MapPointView> cleanedPath;
  final List<MapObstacleView> obstacles;
  final MapPointView? chargingStation;
  final String? highlightedWarningCode;

  @override
  Widget build(BuildContext context) {
    // page-level demo data (UI-only)
    final demoZones = [
      MapZoneView(
        id: 'a',
        label: 'A区',
        points: const [
          MapPointView(x: 0.05, y: 0.1),
          MapPointView(x: 0.45, y: 0.12),
          MapPointView(x: 0.45, y: 0.45),
          MapPointView(x: 0.05, y: 0.44),
        ],
      ),
      MapZoneView(
        id: 'b',
        label: 'B区',
        points: const [
          MapPointView(x: 0.5, y: 0.12),
          MapPointView(x: 0.95, y: 0.1),
          MapPointView(x: 0.95, y: 0.45),
          MapPointView(x: 0.5, y: 0.44),
        ],
      ),
      MapZoneView(
        id: 'c',
        label: 'C区',
        points: const [
          MapPointView(x: 0.05, y: 0.5),
          MapPointView(x: 0.95, y: 0.5),
          MapPointView(x: 0.95, y: 0.95),
          MapPointView(x: 0.05, y: 0.95),
        ],
      ),
    ];

    // Demo task is only cleaning A区, so planned/cleaned/robot/warn are all inside A区.
    final demoPlanned = [
      const MapPointView(x: 0.12, y: 0.16),
      const MapPointView(x: 0.24, y: 0.16),
      const MapPointView(x: 0.24, y: 0.22),
      const MapPointView(x: 0.34, y: 0.22),
      const MapPointView(x: 0.34, y: 0.30),
      const MapPointView(x: 0.20, y: 0.30),
      const MapPointView(x: 0.20, y: 0.36),
      const MapPointView(x: 0.36, y: 0.36),
      const MapPointView(x: 0.36, y: 0.39),
      const MapPointView(x: 0.16, y: 0.39),
    ];

    final demoCleaned = demoPlanned.sublist(0, 5);
    final demoRobot = demoCleaned.last;
    final demoCharging = const MapPointView(x: 0.10, y: 0.13, label: 'Charger');

    // WARN-007 sits on the next uncleaned section immediately after the robot.
    final warningPoint = demoPlanned[demoCleaned.length];
    final demoObstacles = [
      MapObstacleView(position: warningPoint, code: 'WARN-007'),
      MapObstacleView(position: const MapPointView(x: 0.41, y: 0.26)),
    ];

    final hasInjectedData = zones.isNotEmpty;
    final effectiveZones = hasInjectedData ? zones : demoZones;
    final effectivePlanned = hasInjectedData ? plannedPath : demoPlanned;
    final effectiveCleaned = hasInjectedData ? cleanedPath : demoCleaned;
    final effectiveRobot = hasInjectedData ? robotPosition : demoRobot;
    final effectiveCharging = hasInjectedData ? chargingStation : demoCharging;
    final effectiveObstacles = hasInjectedData ? obstacles : demoObstacles;
    final effectiveWarningCode = hasInjectedData
        ? highlightedWarningCode
        : 'WARN-007';

    return Scaffold(
      appBar: AppBar(title: const Text('地图 / 轨迹')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  key: const Key('open-geo-map'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CampusGeoPreviewPage(),
                    ),
                  ),
                  icon: const Icon(Icons.public),
                  label: const Text('查看校园地图'),
                ),
                const SizedBox(height: 12),
                CleaningMapView(
                  zones: effectiveZones,
                  robotPosition: effectiveRobot,
                  plannedPath: effectivePlanned,
                  cleanedPath: effectiveCleaned,
                  obstacles: effectiveObstacles,
                  chargingStation: effectiveCharging,
                  highlightedWarningCode: effectiveWarningCode,
                ),
                const SizedBox(height: 12),
                const Text(
                  '说明：地图读取 DemoSimulationEngine 的实时位置与轨迹。',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text('图例用于区分机器人、充电桩、规划路线、已清扫轨迹和障碍物。'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
