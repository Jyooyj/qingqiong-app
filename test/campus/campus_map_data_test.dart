import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/data/campus/campus_map_data.dart';

void main() {
  group('CampusMapData', () {
    test('zone ids are unique', () {
      final ids = CampusMapData.zones
          .map((zone) => zone.id)
          .toList();

      expect(ids.toSet().length, ids.length);
    });

    test('zone aliases do not conflict', () {
      final aliasOwners = <String, String>{};

      for (final zone in CampusMapData.zones) {
        for (final alias in zone.aliases) {
          expect(
            aliasOwners.containsKey(alias),
            isFalse,
            reason:
                'Alias "$alias" is used by both '
                '${aliasOwners[alias]} and ${zone.id}',
          );

          aliasOwners[alias] = zone.id;
        }
      }
    });

    test('all zone centers use valid normalized coordinates', () {
      for (final zone in CampusMapData.zones) {
        expect(
          zone.center.isValid,
          isTrue,
          reason:
              '${zone.id} has invalid center: '
              '(${zone.center.x}, ${zone.center.y})',
        );
      }
    });

    test('all polygon points use valid normalized coordinates', () {
      for (final zone in CampusMapData.zones) {
        for (final point in zone.polygon) {
          expect(
            point.isValid,
            isTrue,
            reason:
                '${zone.id} has invalid polygon point: '
                '(${point.x}, ${point.y})',
          );
        }
      }
    });

    test('experiment building has a valid planned path', () {
      final route =
          CampusMapData.routeForZone('lab_building');

      expect(route.zoneId, 'lab_building');
      expect(route.plannedPath, isNotEmpty);

      for (final point in route.plannedPath) {
        expect(
          point.isValid,
          isTrue,
          reason:
              'Experiment building route has invalid point: '
              '(${point.x}, ${point.y})',
        );
      }
    });

    test('charging station uses valid normalized coordinates', () {
      expect(
        CampusMapData.chargingStation.position.isValid,
        isTrue,
      );
    });

    test('all obstacles use valid normalized coordinates', () {
      for (final obstacle in CampusMapData.obstacles) {
        expect(
          obstacle.position.isValid,
          isTrue,
          reason:
              '${obstacle.id} has invalid position: '
              '(${obstacle.position.x}, '
              '${obstacle.position.y})',
        );
      }
    });
     test('finds zone by alias', () {
      final zone =
          CampusMapData.findZoneByAlias('请去实验楼附近清扫');

      expect(zone, isNotNull);
      expect(zone!.id, 'lab_building');
    });

    test('uses the longest matching alias', () {
      final zone =
          CampusMapData.findZoneByAlias('去校园主干道清扫');

      expect(zone, isNotNull);
      expect(zone!.id, 'main_road');
    });
     });
}