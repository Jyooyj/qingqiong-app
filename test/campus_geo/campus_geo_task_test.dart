import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:robot_cleaner/adapters/geo_location/demo_geo_location_adapter.dart';
import 'package:robot_cleaner/data/campus_geo/campus_geo_map_data.dart';
import 'package:robot_cleaner/models/cleaning_task.dart';
import 'package:robot_cleaner/services/campus_demo_coordinator.dart';
import 'package:robot_cleaner/services/product_session.dart';

void main() {
  test('empty and single-point routes have zero display progress', () {
    final session = ProductSession();
    final coordinator = _ProgressFixture(session: session);
    try {
      expect(coordinator.geoProgress, 0.0);
      coordinator.planned = [const LatLng(30, 120)];
      expect(coordinator.geoProgress, 0.0);
      coordinator.cleaned = coordinator.planned;
      expect(coordinator.geoProgress, 0.0);
      expect(session.currentTask, isNull);
    } finally {
      coordinator.dispose();
      session.dispose();
    }
  });

  const interval = Duration(milliseconds: 100);
  late ProductSession session;
  late DemoGeoLocationAdapter adapter;
  late CampusDemoCoordinator coordinator;

  setUp(() {
    session = ProductSession();
    adapter = DemoGeoLocationAdapter(stepInterval: interval);
    coordinator = CampusDemoCoordinator(
      session: session,
      geoLocationAdapter: adapter,
    );
  });
  void geoTest(String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        coordinator.dispose();
        adapter.dispose();
        session.dispose();
      }
    });
  }

  geoTest('lab voice creates task and immutable LatLng route', (tester) async {
    expect(coordinator.handleVoiceText('去实验楼清扫').success, isTrue);
    expect(coordinator.selectedZoneId, 'lab_building');
    expect(session.currentTask!.name, '实验楼清扫任务');
    expect(session.currentTask!.status, CleaningTaskStatus.running);
    final expected = CampusGeoMapData.routeForZone(
      'lab_building',
    )!.plannedPath.map((p) => LatLng(p.latitude, p.longitude)).toList();
    expect(coordinator.geoPlannedPath, expected);
    expect(coordinator.geoRobotPosition, expected.first);
    expect(() => coordinator.geoPlannedPath.clear(), throwsUnsupportedError);
    expect(session.simulationEngine.isRunning, isFalse);
    await tester.pump();
    final snapshot = coordinator.geoCleanedPath;
    await tester.pump(interval);
    expect(coordinator.geoRobotPosition, expected[1]);
    expect(coordinator.geoCleanedPath, expected.take(2).toList());
    expect(snapshot, [expected.first]);
    expect(() => coordinator.geoCleanedPath.clear(), throwsUnsupportedError);
  });

  geoTest('task progress follows the same geo route', (tester) async {
    expect(coordinator.geoProgress, 0.0);
    coordinator.selectZone('lab_building');
    expect(coordinator.geoProgress, 0.0);
    coordinator.startCampusCleaning('lab_building');
    expect(coordinator.geoProgress, 0.0);
    await tester.pump();
    expect(coordinator.geoProgress, 0.0);
    for (var i = 1; i < 4; i++) {
      await tester.pump(interval);
      expect(coordinator.geoProgress, i / 4);
      expect(session.currentTask!.progress, i * 25);
      expect(session.currentTask!.status, CleaningTaskStatus.running);
    }
    await tester.pump(interval);
    expect(coordinator.geoProgress, 1.0);
    expect(session.currentTask!.status, CleaningTaskStatus.completed);
    coordinator.startCampusCleaning('canteen_1');
    expect(coordinator.geoProgress, 0.0);
    await tester.pump();
    expect(coordinator.geoProgress, 0.0);
  });

  geoTest('display progress freezes for pause, blockage, emergency and reset', (
    tester,
  ) async {
    coordinator.startCampusCleaning('lab_building');
    await tester.pump();
    coordinator.pause();
    await tester.pump(interval * 3);
    expect(coordinator.geoProgress, 0.0);
    coordinator.resume();
    await tester.pump(interval);
    expect(coordinator.geoProgress, 0.25);
    coordinator.setDemoPathBlocked(true);
    await tester.pump(interval * 3);
    expect(coordinator.geoProgress, 0.25);
    coordinator.setDemoPathBlocked(false);
    await tester.pump(interval * 3);
    expect(coordinator.geoProgress, 0.25);
    coordinator.resume();
    await tester.pump(interval);
    expect(coordinator.geoProgress, 0.5);
    coordinator.emergencyStop();
    expect(coordinator.resume().success, isFalse);
    await tester.pump(interval * 3);
    expect(coordinator.geoProgress, 0.5);
    coordinator.reset();
    await tester.pump(interval * 3);
    expect(coordinator.geoProgress, 0.5);
    coordinator.resume();
    await tester.pump(interval);
    expect(coordinator.geoProgress, 0.75);
  });

  geoTest('pause freezes position and trail; resume continues route', (
    tester,
  ) async {
    coordinator.startCampusCleaning('lab_building');
    await tester.pump();
    await tester.pump(interval);
    expect(coordinator.pause().success, isTrue);
    final position = coordinator.geoRobotPosition;
    final trail = coordinator.geoCleanedPath;
    await tester.pump(const Duration(seconds: 3));
    expect(coordinator.geoRobotPosition, position);
    expect(coordinator.geoCleanedPath, trail);
    expect(coordinator.resume().success, isTrue);
    await tester.pump(interval);
    expect(coordinator.geoRobotPosition, coordinator.geoPlannedPath[2]);
    expect(coordinator.geoCleanedPath.length, trail.length + 1);
    expect(session.simulationEngine.isRunning, isFalse);
  });

  geoTest('emergency locks movement and rejects resume until reset', (
    tester,
  ) async {
    coordinator.startCampusCleaning('lab_building');
    await tester.pump();
    expect(coordinator.emergencyStop().success, isTrue);
    final position = coordinator.geoRobotPosition;
    final trail = coordinator.geoCleanedPath;
    expect(coordinator.resume().success, isFalse);
    expect(session.resumeCurrentTask().success, isFalse);
    await tester.pump(const Duration(seconds: 3));
    expect(coordinator.geoRobotPosition, position);
    expect(coordinator.geoCleanedPath, trail);
    expect(coordinator.reset().success, isTrue);
    await tester.pump(interval);
    expect(coordinator.geoRobotPosition, position);
    expect(coordinator.resume().success, isTrue);
    await tester.pump(interval);
    expect(coordinator.geoRobotPosition, isNot(position));
  });

  geoTest('arrival completes task and stops movement', (tester) async {
    coordinator.startCampusCleaning('lab_building');
    await tester.pump();
    for (var i = 1; i < coordinator.geoPlannedPath.length; i++) {
      await tester.pump(interval);
    }
    expect(coordinator.geoCleanedPath, coordinator.geoPlannedPath);
    expect(session.currentTask!.status, CleaningTaskStatus.completed);
    expect(session.currentTask!.progress, 100);
    expect(coordinator.resume().success, isFalse);
    await tester.pump(const Duration(seconds: 3));
    expect(coordinator.geoRobotPosition, coordinator.geoPlannedPath.last);
  });

  geoTest(
    'session safety pause freezes geo adapter and external resume works',
    (tester) async {
      coordinator.startCampusCleaning('lab_building');
      await tester.pump();
      coordinator.setDemoPathBlocked(true);
      final position = coordinator.geoRobotPosition;
      await tester.pump(interval);
      expect(coordinator.geoRobotPosition, position);
      expect(coordinator.resume().success, isFalse);
      coordinator.setDemoPathBlocked(false);
      await tester.pump(interval);
      expect(coordinator.geoRobotPosition, position);
      expect(session.resumeCurrentTask().success, isTrue);
      await tester.pump(interval);
      expect(coordinator.geoRobotPosition, isNot(position));
    },
  );

  geoTest(
    'queued event after stop is ignored and missing route creates no task',
    (tester) async {
      expect(coordinator.startCampusCleaning('library').success, isFalse);
      expect(session.currentTask, isNull);
      coordinator.startCampusCleaning('lab_building');
      coordinator.stop();
      await tester.pump();
      expect(coordinator.geoCleanedPath, isEmpty);
    },
  );

  geoTest('application voice service uses shared campus coordinator', (
    tester,
  ) async {
    final shared = session.campusCoordinator;
    expect(identical(shared, session.campusCoordinator), isTrue);
    expect(session.voiceControlService.execute('去实验楼清扫').success, isTrue);
    await tester.pump();
    expect(shared.selectedZoneId, 'lab_building');
    expect(shared.geoPlannedPath, isNotEmpty);
    expect(session.voiceControlService.execute('暂停任务').success, isTrue);
    final position = shared.geoRobotPosition;
    await tester.pump(const Duration(seconds: 2));
    expect(shared.geoRobotPosition, position);
    expect(session.voiceControlService.execute('继续任务').success, isTrue);
    expect(session.simulationEngine.isRunning, isFalse);
    await tester.pump(const Duration(seconds: 10));
    expect(shared.geoRobotPosition, isNot(position));
  });
}

// Supply degenerate display routes without changing production campus data.
class _ProgressFixture extends CampusDemoCoordinator {
  _ProgressFixture({required super.session});

  List<LatLng> planned = const [];
  List<LatLng> cleaned = const [];

  @override
  List<LatLng> get geoPlannedPath => planned;
  @override
  List<LatLng> get geoCleanedPath => cleaned;
}
