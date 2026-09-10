import 'package:flutter_test/flutter_test.dart';

import 'package:robot_cleaner/data/mock_map_data.dart';
import 'package:robot_cleaner/models/map_state.dart';

void main() {
  group('MockMapData', () {
    test('A/B/C三区都有模拟路径', () {
      expect(MockMapData.areaAPath, isNotEmpty);
      expect(MockMapData.areaBPath, isNotEmpty);
      expect(MockMapData.areaCPath, isNotEmpty);
    });

    test('pathForArea可以返回正确区域路径', () {
      expect(
        MockMapData.pathForArea('A区'),
        hasLength(MockMapData.areaAPath.length),
      );

      expect(
        MockMapData.pathForArea('B区'),
        hasLength(MockMapData.areaBPath.length),
      );

      expect(
        MockMapData.pathForArea('C区'),
        hasLength(MockMapData.areaCPath.length),
      );
    });

    test('所有路径坐标都在0到1范围内', () {
      final allPaths = <List<MapPoint>>[
        MockMapData.areaAPath,
        MockMapData.areaBPath,
        MockMapData.areaCPath,
      ];

      for (final path in allPaths) {
        for (final point in path) {
          expect(
            point.x,
            inInclusiveRange(0.0, 1.0),
          );

          expect(
            point.y,
            inInclusiveRange(0.0, 1.0),
          );
        }
      }
    });

    test('所有障碍物坐标都在0到1范围内', () {
      expect(MockMapData.obstacles, isNotEmpty);

      for (final obstacle in MockMapData.obstacles) {
        expect(
          obstacle.position.x,
          inInclusiveRange(0.0, 1.0),
        );

        expect(
          obstacle.position.y,
          inInclusiveRange(0.0, 1.0),
        );
      }
    });

    test('充电桩坐标在0到1范围内', () {
      final position =
          MockMapData.chargingStation.position;

      expect(
        position.x,
        inInclusiveRange(0.0, 1.0),
      );

      expect(
        position.y,
        inInclusiveRange(0.0, 1.0),
      );
    });

    test('初始地图状态包含三区、障碍物和充电桩', () {
      final state = MockMapData.initialMapState();

      expect(state.zones.length, 3);
      expect(state.obstacles, isNotEmpty);

      expect(
        state.robotPosition.x,
        MockMapData.chargingStation.position.x,
      );

      expect(
        state.robotPosition.y,
        MockMapData.chargingStation.position.y,
      );

      expect(state.plannedPath, isEmpty);
      expect(state.cleanedPath, isEmpty);
    });
  });
}