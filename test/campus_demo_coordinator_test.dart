import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/adapters/location/demo_location_adapter.dart';
import 'package:robot_cleaner/data/campus/campus_map_data.dart';
import 'package:robot_cleaner/models/campus/campus_point.dart';
import 'package:robot_cleaner/models/cleaning_task.dart';
import 'package:robot_cleaner/models/robot_status.dart';
import 'package:robot_cleaner/services/campus_demo_coordinator.dart';
import 'package:robot_cleaner/services/product_session.dart';
import 'package:robot_cleaner/services/safety/safety_decision.dart';

void main() {
  Future<void> withCoordinator(
    Future<void> Function(
      ProductSession session,
      DemoLocationAdapter adapter,
      CampusDemoCoordinator coordinator,
    )
    body,
  ) async {
    final session = ProductSession();
    final adapter = DemoLocationAdapter(
      interval: const Duration(milliseconds: 10),
    );
    final coordinator = CampusDemoCoordinator(
      session: session,
      locationAdapter: adapter,
    );
    try {
      await body(session, adapter, coordinator);
    } finally {
      coordinator.dispose();
      adapter.dispose();
      session.dispose();
    }
  }

  test('selectZone selects without starting a task or location', () async {
    await withCoordinator((session, adapter, c) async {
      expect(c.selectZone('lab_building'), isTrue);
      expect(c.selectedZoneId, 'lab_building');
      expect(c.selectedZoneName, '实验楼');
      expect(c.selectedZone, CampusMapData.findZoneById('lab_building'));
      expect(c.chargingStation, CampusMapData.chargingStation);
      expect(
        c.plannedPath,
        CampusMapData.routeForZone('lab_building').plannedPath,
      );
      expect(session.currentTask, isNull);
      expect(adapter.isRunning, isFalse);
    });
  });

  for (final item in <Map<String, String>>[
    {'text': '去实验楼附近清扫', 'id': 'lab_building', 'name': '实验楼'},
    {'text': '去一餐附近清扫', 'id': 'canteen_1', 'name': '一餐'},
    {'text': '清扫二教周边', 'id': 'teaching_2', 'name': '第二教学楼'},
  ]) {
    test('voice starts ${item['id']}', () async {
      await withCoordinator((session, adapter, c) async {
        final result = c.handleVoiceText(item['text']!);
        expect(result.success, isTrue);
        expect(c.selectedZoneId, item['id']);
        expect(session.currentTask?.name, '${item['name']}清扫任务');
        expect(session.currentTask?.area, 'A区');
        expect(session.currentTask?.mode, '校园标准清扫');
        expect(result.message, contains(item['name']!));
        expect(result.message, isNot(contains('A区')));
        expect(c.lastMessage, result.message);
        expect(session.currentTask?.status, CleaningTaskStatus.running);
        expect(
          session.robotController.currentStatus.state,
          RobotState.cleaning,
        );
        expect(adapter.isRunning, isTrue);
      });
    });
  }

  for (final text in <String>['不要去实验楼清扫', '可以去实验楼清扫吗', '去一餐还是二教清扫']) {
    test('rejects non executable voice: $text', () async {
      await withCoordinator((session, adapter, c) async {
        c.selectZone('canteen_1');
        var notifications = 0;
        c.addListener(() => notifications++);
        final result = c.handleVoiceText(text);
        expect(result.success, isFalse);
        expect(result.message, isNotEmpty);
        expect(notifications, 0);
        expect(c.lastMessage, isNull);
        expect(c.selectedZoneId, 'canteen_1');
        expect(session.currentTask, isNull);
        expect(adapter.isRunning, isFalse);
      });
    });
  }

  test('pause and resume freeze and continue location', () async {
    await withCoordinator((session, adapter, c) async {
      c.startCampusCleaning('lab_building');
      expect(c.pause().success, isTrue);
      expect(session.currentTask?.status, CleaningTaskStatus.paused);
      expect(session.robotController.currentStatus.state, RobotState.paused);
      expect(adapter.isPaused, isTrue);
      expect(c.resume().success, isTrue);
      expect(session.currentTask?.status, CleaningTaskStatus.running);
      expect(session.robotController.currentStatus.state, RobotState.cleaning);
      expect(adapter.isPaused, isFalse);
    });
  });

  test('emergency, reset and explicit resume semantics', () async {
    await withCoordinator((session, adapter, c) async {
      c.startCampusCleaning('lab_building');
      expect(c.emergencyStop().success, isTrue);
      expect(session.robotController.currentStatus.state, RobotState.emergency);
      expect(session.currentTask?.status, CleaningTaskStatus.paused);
      expect(adapter.isPaused, isTrue);
      expect(c.handleVoiceText('继续清扫').success, isFalse);
      expect(adapter.isPaused, isTrue);
      expect(session.currentTask?.status, CleaningTaskStatus.paused);
      expect(c.reset().success, isTrue);
      expect(session.robotController.currentStatus.state, RobotState.idle);
      expect(adapter.isPaused, isTrue);
      expect(session.currentTask?.status, CleaningTaskStatus.paused);
      expect(c.handleVoiceText('继续清扫').success, isTrue);
      expect(session.robotController.currentStatus.state, RobotState.cleaning);
      expect(session.currentTask?.status, CleaningTaskStatus.running);
      expect(adapter.isPaused, isFalse);
    });
  });

  test('path blocking pauses through existing safety decision', () async {
    await withCoordinator((session, adapter, c) async {
      c.startCampusCleaning('lab_building');
      c.setDemoPathBlocked(true);
      expect(session.safetyDecision.activeWarningCodes, contains('WARN-007'));
      expect(session.safetyDecision.directive, SafetyDirective.pause);
      expect(session.robotController.currentStatus.state, RobotState.paused);
      expect(session.currentTask?.status, CleaningTaskStatus.paused);
      expect(adapter.isPaused, isTrue);
      expect(c.handleVoiceText('继续清扫').success, isFalse);
      expect(adapter.isPaused, isTrue);
      expect(c.visibleObstacles, isNotEmpty);
      c.setDemoPathBlocked(false);
      expect(c.visibleObstacles, isEmpty);
      expect(session.currentTask?.status, CleaningTaskStatus.paused);
      expect(adapter.isPaused, isTrue);
      expect(c.handleVoiceText('继续清扫').success, isTrue);
      expect(adapter.isPaused, isFalse);
    });
  });

  test('stop stops adapter and location events grow cleaned path', () async {
    await withCoordinator((session, adapter, c) async {
      c.startCampusCleaning('canteen_1');
      await Future<void>.delayed(const Duration(milliseconds: 25));
      final before = c.cleanedPath.length;
      expect(c.robotPosition, isNotNull);
      expect(before, greaterThan(0));
      expect(c.stop().success, isTrue);
      expect(session.currentTask?.status, CleaningTaskStatus.cancelled);
      expect(adapter.isRunning, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(c.cleanedPath.length, before);
    });
  });

  test('unknown zone does not create task', () async {
    await withCoordinator((session, adapter, c) async {
      c.selectZone('lab_building');
      expect(c.startCampusCleaning('missing').success, isFalse);
      expect(c.selectZone('missing'), isFalse);
      expect(c.selectedZoneId, 'lab_building');
      expect(session.currentTask, isNull);
      expect(adapter.isRunning, isFalse);
    });
  });

  test('busy or unsafe session rejects start before creating a task', () async {
    await withCoordinator((session, adapter, c) async {
      session.robotController.setPathBlocked(true);
      expect(c.startCampusCleaning('lab_building').success, isFalse);
      expect(session.taskController.tasks, isEmpty);
      expect(adapter.isRunning, isFalse);
      session.robotController.setPathBlocked(false);
      expect(c.startCampusCleaning('lab_building').success, isTrue);
      expect(c.startCampusCleaning('canteen_1').success, isFalse);
      expect(session.taskController.tasks, hasLength(1));
      expect(c.selectedZoneId, 'lab_building');
    });
  });

  test('failed startTask leaves the location and selection untouched', () {
    final session = _RejectingStartSession();
    final adapter = DemoLocationAdapter();
    final c = CampusDemoCoordinator(session: session, locationAdapter: adapter);
    addTearDown(() {
      c.dispose();
      adapter.dispose();
      session.dispose();
    });
    c.selectZone('canteen_1');
    expect(session.canStartTask, isTrue);
    expect(c.startCampusCleaning('lab_building').success, isFalse);
    expect(session.currentTask?.status, CleaningTaskStatus.pending);
    expect(adapter.isRunning, isFalse);
    expect(adapter.currentPosition, isNull);
    expect(c.selectedZoneId, 'canteen_1');
    expect(c.cleanedPath, isEmpty);
  });

  test(
    'campus start requires zoneId even for a legacy start command',
    () async {
      await withCoordinator((session, adapter, c) async {
        c.selectZone('lab_building');
        final result = c.handleVoiceText('开始清扫A区');
        expect(result.success, isFalse);
        expect(result.message, isNot(contains('A区')));
        expect(session.taskController.tasks, isEmpty);
        expect(adapter.isRunning, isFalse);
      });
    },
  );

  test('voice control actions dispatch through session', () async {
    await withCoordinator((session, adapter, c) async {
      c.startCampusCleaning('lab_building');
      expect(c.handleVoiceText('暂停任务').success, isTrue);
      expect(adapter.isPaused, isTrue);
      expect(c.handleVoiceText('继续清扫').success, isTrue);
      expect(adapter.isPaused, isFalse);
      expect(c.handleVoiceText('紧急停止').success, isTrue);
      expect(c.canReset, isTrue);
      expect(c.handleVoiceText('解除急停').success, isTrue);
      expect(adapter.isPaused, isTrue);
      expect(c.handleVoiceText('继续清扫').success, isTrue);
      expect(c.handleVoiceText('停止任务').success, isTrue);
      expect(adapter.isRunning, isFalse);
      expect(c.handleVoiceText('返回充电桩').success, isTrue);
      expect(
        session.robotController.currentStatus.state,
        RobotState.returningToCharge,
      );
    });
  });

  test('public permissions follow the session and robot', () async {
    await withCoordinator((session, adapter, c) async {
      expect(c.canPause, isFalse);
      expect(c.canResume, isFalse);
      expect(c.canEmergencyStop, isTrue);
      expect(c.canReset, isFalse);
      c.startCampusCleaning('lab_building');
      expect(c.canPause, isTrue);
      c.pause();
      expect(c.canResume, isTrue);
      c.emergencyStop();
      expect(c.canResume, isFalse);
      expect(c.canEmergencyStop, isFalse);
      expect(c.canReset, isTrue);
      c.reset();
      expect(c.canResume, isTrue);
      expect(c.canReset, isFalse);
    });
  });

  test('rejected controls do not start or pause the adapter', () async {
    await withCoordinator((session, adapter, c) async {
      expect(c.pause().success, isFalse);
      expect(c.resume().success, isFalse);
      expect(c.stop().success, isFalse);
      expect(c.reset().success, isFalse);
      expect(adapter.isRunning, isFalse);
      expect(adapter.isPaused, isFalse);
    });
  });

  testWidgets('each real stream step grows an independent immutable trail', (
    tester,
  ) async {
    await withCoordinator((session, adapter, c) async {
      final path = CampusMapData.routeForZone('lab_building').plannedPath;
      c.startCampusCleaning('lab_building');
      expect(c.robotPosition, path.first);
      expect(c.cleanedPath, isEmpty);
      var notifications = 0;
      c.addListener(() => notifications++);
      await tester.pump();
      expect(c.cleanedPath, [path.first]);
      expect(notifications, greaterThan(0));
      final snapshot = c.cleanedPath;
      for (var i = 1; i < 4; i++) {
        await tester.pump(adapter.interval);
        expect(c.robotPosition, path[i]);
        expect(c.cleanedPath, path.take(i + 1).toList());
      }
      expect(snapshot, hasLength(1));
      expect(c.cleanedPath, isNot(c.plannedPath));
      expect(() => c.cleanedPath.clear(), throwsUnsupportedError);
      expect(() => c.plannedPath.clear(), throwsUnsupportedError);
    });
  });

  testWidgets('consecutive equal positions do not grow trail', (tester) async {
    await withCoordinator((session, adapter, c) async {
      c.startCampusCleaning('lab_building');
      await tester.pump();
      adapter.start();
      await tester.pump();
      expect(c.cleanedPath, hasLength(1));
      await tester.pump(adapter.interval);
      expect(c.cleanedPath, hasLength(2));
    });
  });

  testWidgets('pause freezes position until explicit resume advances it', (
    tester,
  ) async {
    await withCoordinator((session, adapter, c) async {
      c.startCampusCleaning('lab_building');
      await tester.pump(adapter.interval);
      c.pause();
      final position = c.robotPosition;
      final trail = c.cleanedPath;
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.robotPosition, position);
      expect(c.cleanedPath, trail);
      c.resume();
      await tester.pump(adapter.interval);
      expect(c.robotPosition, isNot(position));
      expect(c.cleanedPath.length, trail.length + 1);
    });
  });

  testWidgets('reset and cleared blockage stay frozen while time advances', (
    tester,
  ) async {
    await withCoordinator((session, adapter, c) async {
      c.startCampusCleaning('lab_building');
      await tester.pump();
      c.emergencyStop();
      c.reset();
      final trail = c.cleanedPath;
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.cleanedPath, trail);
      expect(adapter.isPaused, isTrue);
      c.resume();
      await tester.pump(adapter.interval);
      c.setDemoPathBlocked(true);
      c.setDemoPathBlocked(false);
      final blockedTrail = c.cleanedPath;
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.cleanedPath, blockedTrail);
      expect(adapter.isPaused, isTrue);
    });
  });

  for (final terminal in ['cancelled', 'completed', 'failed']) {
    testWidgets('external $terminal task stops campus location', (
      tester,
    ) async {
      await withCoordinator((session, adapter, c) async {
        c.startCampusCleaning('lab_building');
        await tester.pump();
        final trail = c.cleanedPath;
        switch (terminal) {
          case 'cancelled':
            session.stopCurrentTask();
          case 'completed':
            session.taskController.completeTask(c.currentTask!.id);
          case 'failed':
            session.robotController.setDeviceError(true);
        }
        expect(c.currentTask!.status.name, terminal);
        expect(adapter.isRunning, isFalse);
        await tester.pump(const Duration(milliseconds: 100));
        expect(c.cleanedPath, trail);
      });
    });
  }

  testWidgets('external robot pause and emergency freeze location', (
    tester,
  ) async {
    await withCoordinator((session, adapter, c) async {
      c.startCampusCleaning('lab_building');
      await tester.pump();
      session.robotController.pause();
      expect(adapter.isPaused, isTrue);
      expect(session.robotController.resume().success, isTrue);
      expect(session.pauseCurrentTask().success, isTrue);
      expect(c.resume().success, isTrue);
      session.emergencyStop();
      expect(adapter.isPaused, isTrue);
      expect(c.currentTask?.status, CleaningTaskStatus.paused);
      final trail = c.cleanedPath;
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.cleanedPath, trail);
    });
  });

  testWidgets('queued start event cannot extend trail after stop', (
    tester,
  ) async {
    await withCoordinator((session, adapter, c) async {
      c.startCampusCleaning('lab_building');
      c.stop();
      await tester.pump();
      expect(c.cleanedPath, isEmpty);
    });
  });

  testWidgets('new task clears previous trail and loads its own route', (
    tester,
  ) async {
    await withCoordinator((session, adapter, c) async {
      c.startCampusCleaning('lab_building');
      await tester.pump(const Duration(milliseconds: 20));
      c.stop();
      expect(c.startCampusCleaning('canteen_1').success, isTrue);
      expect(c.cleanedPath, isEmpty);
      expect(
        c.plannedPath,
        CampusMapData.routeForZone('canteen_1').plannedPath,
      );
      await tester.pump();
      expect(c.cleanedPath, [c.plannedPath.first]);
    });
  });

  testWidgets(
    'dispose removes listeners and preserves caller owned dependencies',
    (tester) async {
      await withCoordinator((session, adapter, c) async {
        c.startCampusCleaning('lab_building');
        await tester.pump();
        final position = c.robotPosition;
        var notifications = 0;
        c.addListener(() => notifications++);
        c.dispose();
        session.robotController.setBattery(81);
        await tester.pump(adapter.interval);
        expect(adapter.currentPosition, isNot(position));
        expect(c.robotPosition, position);
        expect(notifications, 0);
        expect(session.pauseCurrentTask().success, isTrue);
        expect(adapter.isPaused, isFalse);
      });
    },
  );

  test(
    'constructor reads existing position and synchronizes paused state',
    () async {
      final session = ProductSession();
      final adapter = DemoLocationAdapter();
      const point = CampusPoint(x: 0.2, y: 0.3);
      adapter.loadPath([point]);
      session.emergencyStop();
      final c = CampusDemoCoordinator(
        session: session,
        locationAdapter: adapter,
      );
      expect(c.robotPosition, point);
      expect(adapter.isPaused, isTrue);
      c.dispose();
      adapter.dispose();
      session.dispose();
    },
  );
}

class _RejectingStartSession extends ProductSession {
  @override
  bool startTask(String taskId) => false;
}
