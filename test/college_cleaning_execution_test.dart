import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:robot_cleaner/data/campus_geo/campus_buildings.dart';
import 'package:robot_cleaner/data/campus_geo/campus_cleaning_catalog.dart';
import 'package:robot_cleaner/data/campus_geo/campus_college_data.dart';
import 'package:robot_cleaner/data/campus_geo/campus_geo_map_data.dart';
import 'package:robot_cleaner/models/cleaning_task.dart';
import 'package:robot_cleaner/services/product_session.dart';

void main() {
  for (final id in CampusCollegeData.ids) {
    testWidgets('$id supports a complete route with pause and resume', (
      tester,
    ) async {
      final building = CampusBuildings.all.singleWhere((b) => b.id == id);
      final zone = CampusGeoMapData.findZoneById(id)!;
      final path = CampusGeoMapData.routeForZone(id)!.plannedPath;
      expect(building.displayOnly, isFalse);
      expect(building.zoneId, id);
      expect(zone.center.latitude, building.latitude);
      expect(zone.center.longitude, building.longitude);
      expect(zone.isTaskTarget, isTrue);
      expect(CampusCleaningCatalog.areas.map((z) => z.id), contains(id));
      expect(path, hasLength(5));
      expect(path.first, path.last);
      expect(path.toSet(), hasLength(4));
      final session = ProductSession();
      addTearDown(session.dispose);
      final coordinator = session.campusCoordinator;
      expect(coordinator.startCampusCleaning(id).success, isTrue);
      await tester.pump();
      expect(session.currentTask!.displayTaskName, '${building.name}清扫任务');
      expect(session.currentTask!.displayArea, building.name);
      expect(
        coordinator.geoPlannedPath,
        path.map((p) => LatLng(p.latitude, p.longitude)).toList(),
      );
      expect(session.currentTask!.status, CleaningTaskStatus.running);
      expect(session.currentTask!.progress, 0);
      expect(coordinator.geoCleanedPath, hasLength(1));
      await tester.pump(const Duration(seconds: 10));
      expect(session.currentTask!.progress, 25);
      expect(coordinator.pause().success, isTrue);
      final trail = coordinator.geoCleanedPath;
      await tester.pump(const Duration(seconds: 20));
      expect(coordinator.geoCleanedPath, trail);
      expect(session.currentTask!.status, CleaningTaskStatus.paused);
      expect(coordinator.resume().success, isTrue);
      for (var i = 2; i < path.length; i++) {
        await tester.pump(const Duration(seconds: 10));
        expect(
          coordinator.geoRobotPosition,
          LatLng(path[i].latitude, path[i].longitude),
        );
        expect(session.currentTask!.progress, 25 * i);
      }
      expect(session.currentTask!.status, CleaningTaskStatus.completed);
      expect(coordinator.geoCleanedPath, coordinator.geoPlannedPath);
    });
  }
}
