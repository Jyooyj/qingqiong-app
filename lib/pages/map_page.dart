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

    // planned path within A区 (zig-zag / back-and-forth)
    final planned = [
      const MapPointView(x: 0.14, y: 0.16),
      const MapPointView(x: 0.40, y: 0.16),
      const MapPointView(x: 0.40, y: 0.23),
      const MapPointView(x: 0.14, y: 0.23),
      const MapPointView(x: 0.14, y: 0.30),
      const MapPointView(x: 0.40, y: 0.30),
      const MapPointView(x: 0.40, y: 0.37),
      const MapPointView(x: 0.14, y: 0.37),
    ];

    // cleaned path is strictly the first three planned points
    final cleaned = [planned[0], planned[1], planned[2]];

    final robot = cleaned.last; // should equal planned[2]
    final charging = const MapPointView(x: 0.09, y: 0.15, label: 'Charger');

    // place WARN-007 at planned[3]
    final obstacles = [
      MapObstacleView(position: planned[3], code: 'WARN-007'),
      // ordinary red obstacle in C区 but not overlapping key items
      MapObstacleView(position: const MapPointView(x: 0.72, y: 0.65)),
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
