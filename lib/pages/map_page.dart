import 'package:flutter/material.dart';
import '../widgets/map/map_view_data.dart';
import '../widgets/map/cleaning_map_view.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    // page-level demo data (UI-only)
    final zones = [
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
    final planned = [
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

    final cleaned = planned.sublist(0, 5);
    final robot = cleaned.last;
    final charging = const MapPointView(x: 0.10, y: 0.13, label: 'Charger');

    // WARN-007 sits on the next uncleaned section immediately after the robot.
    final warningPoint = planned[cleaned.length];
    final obstacles = [
      MapObstacleView(position: warningPoint, code: 'WARN-007'),
      MapObstacleView(position: const MapPointView(x: 0.41, y: 0.26)),
    ];

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
                CleaningMapView(
                  zones: zones,
                  robotPosition: robot,
                  plannedPath: planned,
                  cleanedPath: cleaned,
                  obstacles: obstacles,
                  chargingStation: charging,
                  highlightedWarningCode: 'WARN-007',
                ),
                const SizedBox(height: 12),
                const Text(
                  '说明：地图为演示层，仅用于UI显示。',
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
