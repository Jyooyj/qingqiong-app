import 'package:robot_cleaner/data/campus_geo/campus_college_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/data/campus_geo/campus_geo_map_data.dart';
import 'package:robot_cleaner/data/campus_geo/campus_buildings.dart';
import 'package:robot_cleaner/models/campus_geo/campus_building.dart';
import 'package:robot_cleaner/data/campus_geo/campus_cleaning_catalog.dart';
import 'package:robot_cleaner/services/product_session.dart';

void main() {
  test('campus zones have unique ids, names and valid campus coordinates', () {
    final ids = CampusGeoMapData.zones.map((zone) => zone.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final zone in CampusGeoMapData.zones) {
      expect(zone.name.trim(), isNotEmpty);
      expect(zone.type.trim(), isNotEmpty);
      expect(zone.center.isValid, isTrue);
      expect(zone.center.latitude, inInclusiveRange(30.87, 30.90));
      expect(zone.center.longitude, inInclusiveRange(121.88, 121.91));
      for (final point in zone.polygon) {
        expect(point.isValid, isTrue);
        expect(point.latitude, inInclusiveRange(30.87, 30.90));
        expect(point.longitude, inInclusiveRange(121.88, 121.91));
      }
    }
  });

  test('task target zones have distinct routes ending in their zone', () {
    for (final id in ['lab_building', 'canteen_1', 'teaching_2', 'dormitory']) {
      final zone = CampusGeoMapData.findZoneById(id)!;
      expect(zone.isTaskTarget, isTrue);
      final route = CampusGeoMapData.routeForZone(id)!;
      expect(route.zoneId, id);
      expect(route.plannedPath, isNotEmpty);
      final endpoint = route.plannedPath.last;
      expect((endpoint.latitude - zone.center.latitude).abs(), lessThan(0.001));
      expect(
        (endpoint.longitude - zone.center.longitude).abs(),
        lessThan(0.001),
      );
    }
    expect(
      CampusGeoMapData.routeForZone('lab_building'),
      isNot(CampusGeoMapData.routeForZone('canteen_1')),
    );
    expect(
      CampusGeoMapData.routeForZone('canteen_1'),
      isNot(CampusGeoMapData.routeForZone('teaching_2')),
    );
  });

  test('permanent campus building labels are independent and valid', () {
    final ids = CampusBuildings.all.map((building) => building.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, isNot(contains('teaching_5')));
    expect(ids, isNot(contains('teaching_6')));
    for (final building in CampusBuildings.all) {
      expect(building.name.trim(), isNotEmpty);
      if (building.pendingCalibration) {
        expect(building.displayOnly, isTrue);
        expect(building.latitude, isNull);
        expect(building.longitude, isNull);
        expect(building.zoneId, isNull);
        continue;
      }
      expect(building.latitude, isNotNull);
      expect(building.longitude, isNotNull);
      expect(building.latitude!, inInclusiveRange(30.87, 30.90));
      expect(building.longitude!, inInclusiveRange(121.88, 121.91));
      if (building.zoneId != null) {
        final source = CampusGeoMapData.findZoneById(building.zoneId!);
        expect(source, isNotNull);
      }
    }
    const calibratedBuildingCoordinates = {
      'teaching_2': (30.885200, 121.893501),
      'teaching_1': (30.884428, 121.894047),
      'dormitory': (30.881308, 121.892049),
      'library': (30.885826, 121.891878),
      'canteen_2': (30.882666, 121.891107),
      'canteen_3': (30.889386, 121.891885),
      'teaching_3': (30.885779, 121.894235),
      'teaching_4': (30.886403, 121.894931),
    };
    for (final entry in calibratedBuildingCoordinates.entries) {
      final building = CampusBuildings.all.firstWhere(
        (candidate) => candidate.id == entry.key,
      );
      expect(building.latitude, entry.value.$1);
      expect(building.longitude, entry.value.$2);
    }
    const calibratedColleges = {
      'ain_college': (30.888560, 121.893287),
      'engineering_college': (30.887970, 121.892293),
      'information_college': (30.888320, 121.894264),
      'food_college': (30.887495, 121.891124),
      'ocean_college': (30.887474, 121.892207),
      'fisheries_life_college': (30.887360, 121.890232),
    };
    for (final entry in calibratedColleges.entries) {
      final building = CampusBuildings.all.firstWhere(
        (candidate) => candidate.id == entry.key,
      );
      expect(building.latitude, entry.value.$1);
      expect(building.longitude, entry.value.$2);
      expect(building.pendingCalibration, isFalse);
      expect(building.displayOnly, isFalse);
      expect(building.zoneId, entry.key);
    }

    final pending = CampusBuildings.all.where((b) => b.pendingCalibration);
    expect(pending, isEmpty);
    expect(pending.every((b) => b.displayOnly), isTrue);
    expect(
      CampusBuildings.all
          .where((b) => b.displayOnly && !b.pendingCalibration)
          .map((b) => b.id),
      unorderedEquals(['canteen_2', 'canteen_3', 'teaching_3', 'teaching_4']),
    );
  });

  test(
    'merged POIs preserve upstream coordinates and aliases without tasks',
    () {
      const pois = {
        'canteen_2': (30.883500, 121.892400, ['第二餐厅', '第二食堂', '二餐']),
        'canteen_3': (30.886350, 121.890700, ['第三餐厅', '第三食堂', '三餐']),
        'teaching_3': (30.885100, 121.893300, ['第三教学楼', '三教']),
        'teaching_4': (30.885550, 121.893700, ['第四教学楼', '四教']),
        'teaching_5': (30.884650, 121.894050, ['第五教学楼', '五教']),
        'teaching_6': (30.884450, 121.894200, ['第六教学楼', '六教']),
      };
      final session = ProductSession();
      addTearDown(session.dispose);
      for (final entry in pois.entries) {
        final zone = CampusGeoMapData.findZoneById(entry.key)!;
        expect(zone.center.latitude, entry.value.$1);
        expect(zone.center.longitude, entry.value.$2);
        expect(zone.aliases, containsAll(entry.value.$3));
        expect(zone.isTaskTarget, isFalse);
        expect(CampusGeoMapData.routeForZone(zone.id), isNull);
        expect(
          session.campusCoordinator.startCampusCleaning(zone.id).success,
          isFalse,
        );
      }
      expect(session.taskController.tasks, isEmpty);
      expect(
        CampusCleaningCatalog.shortcuts.map((zone) => zone.id),
        orderedEquals(['lab_building', 'canteen_1', 'teaching_2']),
      );
      expect(
        CampusCleaningCatalog.areas.map((zone) => zone.id),
        unorderedEquals([
          'lab_building',
          'canteen_1',
          'teaching_2',
          'dormitory',
          ...CampusCollegeData.ids,
        ]),
      );
      expect(
        CampusGeoMapData.routes.map((route) => route.zoneId),
        unorderedEquals([
          'lab_building',
          'canteen_1',
          'teaching_2',
          'dormitory',
          ...CampusCollegeData.ids,
        ]),
      );
    },
  );

  test('upstream naming aliases retain current product task labels', () {
    for (final entry in {
      'lab_building': ['公共实验楼', '实验楼', '实验楼A', '公共实验楼A', '公共实验楼B'],
      'canteen_1': ['第一餐厅', '第一食堂', '一餐'],
    }.entries) {
      final zone = CampusGeoMapData.findZoneById(entry.key)!;
      expect(zone.aliases, containsAll(entry.value));
      for (final alias in entry.value) {
        final session = ProductSession();
        try {
          expect(
            session.campusCoordinator.handleVoiceText('去$alias清扫').success,
            isTrue,
          );
          final name = entry.key == 'lab_building' ? '实验楼' : '第一食堂';
          expect(session.currentTask!.displayArea, name);
          expect(session.currentTask!.displayTaskName, '$name清扫任务');
        } finally {
          session.dispose();
        }
      }
    }
  });

  test('display-only buildings are never task targets', () {
    const displayOnly = CampusBuilding(
      id: 'verified-display-example',
      name: '展示地点',
      latitude: 30.884,
      longitude: 121.892,
      displayOnly: true,
    );
    expect(displayOnly.displayOnly, isTrue);
    expect(displayOnly.zoneId, isNull);
    expect(CampusGeoMapData.findZoneById(displayOnly.id), isNull);
    expect(CampusGeoMapData.routeForZone(displayOnly.id), isNull);
    expect(
      CampusGeoMapData.zones
          .where((zone) => zone.isTaskTarget)
          .map((zone) => zone.id),
      unorderedEquals([
        'lab_building',
        'canteen_1',
        'teaching_2',
        'dormitory',
        ...CampusCollegeData.ids,
      ]),
    );
  });
}
