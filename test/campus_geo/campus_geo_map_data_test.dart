import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/data/campus_geo/campus_geo_map_data.dart';

void main() {
  group('CampusGeoMapData', () {
    test('findZoneById returns lab building', () {
      final zone = CampusGeoMapData.findZoneById('lab_building');

      expect(zone, isNotNull);
      expect(zone!.name, '实验楼');
    });

    test('findZoneByAlias returns canteen_1 for 一餐', () {
      final zone = CampusGeoMapData.findZoneByAlias('一餐');

      expect(zone, isNotNull);
      expect(zone!.id, 'canteen_1');
    });

    test('findZoneByAlias returns teaching_2 for 二教', () {
      final zone = CampusGeoMapData.findZoneByAlias('二教');

      expect(zone, isNotNull);
      expect(zone!.id, 'teaching_2');
    });

    test('all P0 zones have non-empty polygons', () {
      const p0ZoneIds = [
        'lab_building',
        'canteen_1',
        'teaching_2',
        'dormitory',
        'library',
      ];

      for (final id in p0ZoneIds) {
        final zone = CampusGeoMapData.findZoneById(id);

        expect(
          zone,
          isNotNull,
          reason: '$id should exist',
        );

        expect(
          zone!.polygon,
          isNotEmpty,
          reason: '$id polygon should not be empty',
        );
      }
    });

    test('all P0 coordinates are valid', () {
      const p0ZoneIds = [
        'lab_building',
        'canteen_1',
        'teaching_2',
        'dormitory',
        'library',
      ];

      for (final id in p0ZoneIds) {
        final zone = CampusGeoMapData.findZoneById(id)!;

        expect(
          zone.center.isValid,
          isTrue,
          reason: '$id center should be valid',
        );

        for (final point in zone.polygon) {
          expect(
            point.isValid,
            isTrue,
            reason: '$id polygon point should be valid',
          );
        }
      }
    });

    test('four main demo routes are non-empty', () {
      const routeZoneIds = [
        'lab_building',
        'canteen_1',
        'teaching_2',
        'dormitory',
      ];

      for (final id in routeZoneIds) {
        final route = CampusGeoMapData.routeForZone(id);

        expect(
          route,
          isNotNull,
          reason: '$id route should exist',
        );

        expect(
          route!.plannedPath,
          isNotEmpty,
          reason: '$id route should not be empty',
        );
      }
    });

    test('main routes start at charging station', () {
      const routeZoneIds = [
        'lab_building',
        'canteen_1',
        'teaching_2',
        'dormitory',
      ];

      for (final id in routeZoneIds) {
        final route = CampusGeoMapData.routeForZone(id)!;

        expect(
          route.plannedPath.first,
          CampusGeoMapData.chargingStation.position,
          reason: '$id route should start at charging station',
        );
      }
    });

    test('main routes end at target zone center', () {
      const routeZoneIds = [
        'lab_building',
        'canteen_1',
        'teaching_2',
        'dormitory',
      ];

      for (final id in routeZoneIds) {
        final route = CampusGeoMapData.routeForZone(id)!;
        final zone = CampusGeoMapData.findZoneById(id)!;

        expect(
          route.plannedPath.last,
          zone.center,
          reason: '$id route should end at target zone center',
        );
      }
    });
  });
}