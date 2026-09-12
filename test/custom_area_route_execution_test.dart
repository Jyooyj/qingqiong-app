import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:robot_cleaner/models/campus_geo/campus_geo_point.dart';
import 'package:robot_cleaner/models/campus_geo/custom_cleaning_area.dart';
import 'package:robot_cleaner/models/cleaning_task.dart';
import 'package:robot_cleaner/services/product_session.dart';

void main() {
  const polygon = [
    CampusGeoPoint(latitude: 30.884, longitude: 121.892),
    CampusGeoPoint(latitude: 30.885, longitude: 121.892),
    CampusGeoPoint(latitude: 30.885, longitude: 121.893),
    CampusGeoPoint(latitude: 30.884, longitude: 121.893),
  ];

  for (final count in [3, 4]) {
    testWidgets('$count boundary points move through a complete closed route', (
      tester,
    ) async {
      final session = ProductSession();
      addTearDown(session.dispose);
      final input = polygon.take(count).toList();
      final area = session.customCleaningAreas.save(
        name: 'Demo boundary',
        type: CustomAreaType.road,
        polygon: input,
      );
      final route = area.generatedRoute;
      expect(route.zoneId, area.id);
      expect(route.plannedPath, [...input, input.first]);
      input.clear();
      expect(route.plannedPath, hasLength(count + 1));
      expect(() => route.plannedPath.clear(), throwsUnsupportedError);
      expect(session.customCleaningAreas.findById(area.id), same(area));

      final coordinator = session.campusCoordinator;
      expect(coordinator.startCampusCleaning(area.id).success, isTrue);
      await tester.pump();
      expect(session.currentTask!.status, CleaningTaskStatus.running);
      expect(session.currentTask!.progress, 0);
      expect(coordinator.geoCleanedPath, hasLength(1));

      for (var i = 1; i < route.plannedPath.length; i++) {
        if (i == 2) {
          expect(coordinator.pause().success, isTrue);
          final pausedPosition = coordinator.geoRobotPosition;
          await tester.pump(const Duration(seconds: 20));
          expect(coordinator.geoRobotPosition, pausedPosition);
          expect(coordinator.resume().success, isTrue);
        }
        await tester.pump(const Duration(seconds: 10));
        final point = route.plannedPath[i];
        expect(
          coordinator.geoRobotPosition,
          LatLng(point.latitude, point.longitude),
        );
        if (i < count) {
          expect(session.currentTask!.status, CleaningTaskStatus.running);
          expect(session.currentTask!.progress, closeTo(100 * i / count, .01));
        }
      }
      final task = session.taskController.tasks.single;
      expect(task.status, CleaningTaskStatus.completed);
      expect(task.progress, 100);
      // Independent metre-scale expectations for the triangle and rectangle.
      expect(task.cleanedArea, closeTo(count == 3 ? 5305 : 10611, 20));
      expect(task.cleanedDistance, closeTo(count == 3 ? 353.6 : 413.7, 1));
      expect(task.elapsed, isNot(Duration.zero));
      expect(session.currentTask!.cleanedArea, task.cleanedArea);
      final saved = (await session.taskController.repository!.getAll()).single;
      expect(saved.cleanedArea, task.cleanedArea);
      expect(saved.cleanedDistance, task.cleanedDistance);
      expect(saved.elapsed, task.elapsed);
      expect(coordinator.geoCleanedPath, hasLength(count + 1));
    });
  }
}
