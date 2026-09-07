import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/adapters/location/demo_location_adapter.dart';
import 'package:robot_cleaner/data/campus/campus_map_data.dart';
import 'package:robot_cleaner/main.dart';
import 'package:robot_cleaner/models/cleaning_task.dart';
import 'package:robot_cleaner/models/robot_status.dart';
import 'package:robot_cleaner/pages/home_page.dart';
import 'package:robot_cleaner/pages/map_page.dart';
import 'package:robot_cleaner/services/campus_demo_coordinator.dart';
import 'package:robot_cleaner/services/product_session.dart';
import 'package:robot_cleaner/services/safety/safety_decision.dart';
import 'package:robot_cleaner/widgets/campus/campus_demo_page.dart';
import 'package:robot_cleaner/widgets/campus/campus_map_view.dart';
import 'package:robot_cleaner/widgets/campus/current_task_map_card.dart';
import 'package:robot_cleaner/widgets/map/cleaning_map_view.dart';

void main() {
  Future<CampusDemoCoordinator> showPage(WidgetTester tester) async {
    final session = ProductSession();
    final adapter = DemoLocationAdapter();
    final coordinator = CampusDemoCoordinator(
      session: session,
      locationAdapter: adapter,
    );
    await tester.pumpWidget(
      _TestOwner(
        onDispose: () {
          coordinator.dispose();
          adapter.dispose();
          session.dispose();
        },
        child: MaterialApp(home: CampusDemoPage(coordinator: coordinator)),
      ),
    );
    return coordinator;
  }

  CampusMapView map(WidgetTester tester) =>
      tester.widget<CampusMapView>(find.byType(CampusMapView));

  Future<void> tap(WidgetTester tester, String key) async {
    final target = find.byKey(Key(key));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pump();
  }

  Future<void> command(
    WidgetTester tester,
    String text, {
    bool keyboard = false,
  }) async {
    final input = find.byKey(const Key('campus-command-input'));
    await tester.ensureVisible(input);
    await tester.enterText(input, text);
    if (keyboard) {
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
    } else {
      await tap(tester, 'campus-execute-command');
    }
  }

  testWidgets(
    'AppShell shares session, retains coordinator across navigation and owns its lifecycle',
    (tester) async {
      final session = ProductSession();
      addTearDown(session.dispose);
      await tester.pumpWidget(QingQiongApp(session: session));
      final home = tester.widget<HomePage>(find.byType(HomePage));
      await tester.tap(find.byIcon(Icons.map).first);
      await tester.pumpAndSettle();
      expect(find.byType(CleaningMapView), findsOneWidget);
      final coordinator = tester
          .widget<MapPage>(find.byType(MapPage))
          .campusCoordinator!;
      expect(identical(coordinator.session, session), isTrue);
      expect(identical(coordinator.session, home.session), isTrue);
      await tap(tester, 'open-campus-map');
      await tester.pumpAndSettle();
      expect(find.text('校园智能清扫'), findsOneWidget);
      expect(
        tester.widget<CampusDemoPage>(find.byType(CampusDemoPage)).coordinator,
        same(coordinator),
      );
      await command(tester, '去实验楼附近清扫');
      expect(session.currentTask?.name, '实验楼清扫任务');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.assignment).first);
      await tester.pumpAndSettle();
      expect(find.text('实验楼清扫任务'), findsWidgets);
      await tester.tap(find.byIcon(Icons.map).first);
      await tester.pumpAndSettle();
      await tap(tester, 'open-campus-map');
      await tester.pumpAndSettle();
      expect(
        tester.widget<CampusDemoPage>(find.byType(CampusDemoPage)).coordinator,
        same(coordinator),
      );
      var closed = false;
      coordinator.locationAdapter.watchRobotPosition().listen(
        (_) {},
        onDone: () => closed = true,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(coordinator.locationAdapter.isRunning, isFalse);
      expect(closed, isTrue);
      expect(session.pauseCurrentTask().success, isTrue);
      session.simulationEngine.stop();
    },
  );

  testWidgets(
    'AppShell also creates a single owned session for home and campus',
    (tester) async {
      await tester.pumpWidget(const QingQiongApp());
      final home = tester.widget<HomePage>(find.byType(HomePage));
      final page = tester.widget<MapPage>(
        find.byType(MapPage, skipOffstage: false),
      );
      expect(page.campusCoordinator!.session, same(home.session));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'legacy MapPage without coordinator keeps old map and disables campus entry',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MapPage()));
      expect(find.byType(CleaningMapView), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('open-campus-map')))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('map tap and ChoiceChip only select and preview a real route', (
    tester,
  ) async {
    final c = await showPage(tester);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('campus-start-selected')))
          .onPressed,
      isNull,
    );
    await tap(tester, 'campus-zone-lab_building');
    expect(c.selectedZoneId, 'lab_building');
    expect(
      map(tester).plannedPath,
      CampusMapData.routeForZone('lab_building').plannedPath,
    );
    expect(c.currentTask, isNull);
    expect(c.locationAdapter.isRunning, isFalse);
    await tap(tester, 'campus-choice-canteen_1');
    expect(c.selectedZoneId, 'canteen_1');
    expect(c.currentTask, isNull);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('campus-choice-canteen_1')))
          .selected,
      isTrue,
    );
  });

  for (final entry in {
    '去实验楼附近清扫': 'lab_building',
    '去一餐附近清扫': 'canteen_1',
    '清扫二教周边': 'teaching_2',
  }.entries) {
    testWidgets('natural language creates real campus task: ${entry.key}', (
      tester,
    ) async {
      final c = await showPage(tester);
      await command(tester, entry.key);
      expect(
        c.currentTask?.name,
        '${CampusMapData.findZoneById(entry.value)!.name}清扫任务',
      );
      expect(c.currentTask?.status, CleaningTaskStatus.running);
      expect(map(tester).selectedZoneId, entry.value);
      expect(map(tester).zones, CampusMapData.zones);
      expect(map(tester).plannedPath, c.plannedPath);
      expect(map(tester).robotPosition, c.robotPosition);
      expect(map(tester).cleanedPath, c.cleanedPath);
      expect(map(tester).chargingStation, c.chargingStation);
      expect(map(tester).taskData!.targetZoneName, c.selectedZoneName);
      expect(map(tester).taskData!.status, CampusTaskStatus.running);
      expect(find.text(c.lastMessage!), findsOneWidget);
      expect(find.textContaining('A区'), findsNothing);
      final before = map(tester).robotPosition;
      final count = map(tester).cleanedPath.length;
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(map(tester).robotPosition, isNot(before));
      expect(map(tester).cleanedPath.length, count + 1);
    });
  }

  testWidgets('manual start respects selection and session permission', (
    tester,
  ) async {
    final c = await showPage(tester);
    await tap(tester, 'campus-choice-lab_building');
    await tap(tester, 'campus-start-selected');
    expect(c.currentTask?.status, CleaningTaskStatus.running);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('campus-start-selected')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('task card pause and resume control position advancement', (
    tester,
  ) async {
    final c = await showPage(tester);
    await command(tester, '去实验楼附近清扫');
    await tap(tester, 'campus-pause');
    expect(c.currentTask?.status, CleaningTaskStatus.paused);
    expect(c.session.robotController.currentStatus.state, RobotState.paused);
    expect(map(tester).taskData!.status, CampusTaskStatus.paused);
    final position = map(tester).robotPosition;
    final trail = map(tester).cleanedPath;
    await tester.pump(const Duration(seconds: 2));
    expect(map(tester).robotPosition, position);
    expect(map(tester).cleanedPath, trail);
    await tap(tester, 'campus-resume');
    expect(c.currentTask?.status, CleaningTaskStatus.running);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(map(tester).robotPosition, isNot(position));
  });

  testWidgets('WARN-007 switch uses real safety and clearing does not resume', (
    tester,
  ) async {
    final c = await showPage(tester);
    await command(tester, '去实验楼附近清扫');
    await tap(tester, 'campus-path-blocked');
    expect(c.session.safetyDecision.activeWarningCodes, contains('WARN-007'));
    expect(c.session.safetyDecision.directive, SafetyDirective.pause);
    expect(c.currentTask?.status, CleaningTaskStatus.paused);
    expect(c.session.robotController.currentStatus.state, RobotState.paused);
    expect(c.locationAdapter.isPaused, isTrue);
    expect(map(tester).obstacles, CampusMapData.obstacles);
    expect(map(tester).taskData!.message, contains('WARN-007'));
    expect(map(tester).onResume, isNull);
    expect(
      find.byKey(const Key('campus-obstacle-lab_obstacle_01')),
      findsOneWidget,
    );
    await tap(tester, 'campus-path-blocked');
    expect(map(tester).obstacles, isEmpty);
    expect(c.currentTask?.status, CleaningTaskStatus.paused);
    final trail = c.cleanedPath;
    await tester.pump(const Duration(seconds: 2));
    expect(c.cleanedPath, trail);
    expect(c.locationAdapter.isPaused, isTrue);
    await tap(tester, 'campus-resume');
    expect(c.currentTask?.status, CleaningTaskStatus.running);
  });

  testWidgets('external path-blocked changes update the switch', (
    tester,
  ) async {
    final c = await showPage(tester);
    c.session.robotController.setPathBlocked(true);
    await tester.pump();
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('campus-path-blocked')))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('campus-start-selected')))
          .onPressed,
      isNull,
    );
    c.session.robotController.setPathBlocked(false);
    await tester.pump();
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('campus-path-blocked')))
          .value,
      isFalse,
    );
  });

  testWidgets('emergency and reset require explicit resume from task card', (
    tester,
  ) async {
    final c = await showPage(tester);
    await command(tester, '去实验楼附近清扫');
    await tap(tester, 'campus-emergency');
    expect(c.session.robotController.currentStatus.state, RobotState.emergency);
    expect(c.currentTask?.status, CleaningTaskStatus.paused);
    expect(map(tester).taskData!.status, CampusTaskStatus.emergency);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('campus-resume')))
          .onPressed,
      isNull,
    );
    expect(c.locationAdapter.isPaused, isTrue);
    await command(tester, '继续清扫');
    expect(c.currentTask?.status, CleaningTaskStatus.paused);
    expect(c.locationAdapter.isPaused, isTrue);
    await tap(tester, 'campus-reset');
    expect(c.session.robotController.currentStatus.state, RobotState.idle);
    expect(map(tester).taskData!.status, CampusTaskStatus.paused);
    final trail = c.cleanedPath;
    await tester.pump(const Duration(seconds: 2));
    expect(c.cleanedPath, trail);
    expect(c.locationAdapter.isPaused, isTrue);
    await tap(tester, 'campus-resume');
    expect(c.currentTask?.status, CleaningTaskStatus.running);
    expect(c.locationAdapter.isPaused, isFalse);
  });

  testWidgets(
    'keyboard submission dispatches control sentences through coordinator',
    (tester) async {
      final c = await showPage(tester);
      await command(tester, '去实验楼附近清扫', keyboard: true);
      for (final entry in {
        '暂停任务': RobotState.paused,
        '继续清扫': RobotState.cleaning,
        '紧急停止': RobotState.emergency,
        '解除急停': RobotState.idle,
      }.entries) {
        await command(tester, entry.key, keyboard: true);
        expect(c.session.robotController.currentStatus.state, entry.value);
      }
      expect(c.locationAdapter.isPaused, isTrue);
    },
  );

  for (final text in ['不要去实验楼清扫', '可以去实验楼清扫吗', '去一餐还是二教清扫']) {
    testWidgets('rejected sentence shows feedback and creates no task: $text', (
      tester,
    ) async {
      final c = await showPage(tester);
      await command(tester, text);
      expect(c.session.taskController.tasks, isEmpty);
      expect(c.locationAdapter.isRunning, isFalse);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(c.selectedZoneId, isNull);
    });
  }

  testWidgets(
    'task metrics remain live and unavailable battery stays unknown',
    (tester) async {
      final c = await showPage(tester);
      expect(map(tester).taskData!.status, CampusTaskStatus.preview);
      expect(map(tester).taskData!.progress, isNull);
      await command(tester, '去实验楼附近清扫');
      c.session.simulationEngine.advanceOneTick();
      await tester.pump();
      final task = c.currentTask!;
      final data = map(tester).taskData!;
      expect(data.progress, task.progress);
      expect(data.cleanedArea, task.cleanedArea);
      expect(data.elapsed, task.elapsed);
      expect(data.battery, isNull);
      expect(find.text('—'), findsOneWidget);
    },
  );

  for (final terminal in [
    CleaningTaskStatus.completed,
    CleaningTaskStatus.cancelled,
    CleaningTaskStatus.failed,
  ]) {
    testWidgets('task card maps $terminal without fabricating completion', (
      tester,
    ) async {
      final c = await showPage(tester);
      await command(tester, '去实验楼附近清扫');
      switch (terminal) {
        case CleaningTaskStatus.completed:
          c.session.taskController.completeTask(c.currentTask!.id);
        case CleaningTaskStatus.cancelled:
          await command(tester, '停止任务');
        case CleaningTaskStatus.failed:
          c.session.robotController.setDeviceError(true);
        default:
          fail('Unexpected terminal state');
      }
      await tester.pump();
      expect(
        map(tester).taskData!.status,
        terminal == CleaningTaskStatus.failed
            ? CampusTaskStatus.fault
            : CampusTaskStatus.completed,
      );
      if (terminal == CleaningTaskStatus.cancelled) {
        expect(map(tester).taskData!.message, '任务已停止/取消');
        expect(find.text('正常完成'), findsNothing);
      }
      expect(c.locationAdapter.isRunning, isFalse);
    });
  }

  testWidgets('pending task and emergency priority map from session', (
    tester,
  ) async {
    final c = await showPage(tester);
    c.session.createTask(name: '实验楼清扫任务', area: 'A区', mode: '校园标准清扫');
    await tester.pump();
    expect(map(tester).taskData!.status, CampusTaskStatus.pending);
    c.session.robotController.setDeviceError(true);
    c.session.emergencyStop();
    await tester.pump();
    expect(map(tester).taskData!.status, CampusTaskStatus.emergency);
  });

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
    const Size(1366, 768),
  ]) {
    testWidgets('integrated campus workflow has no overflow at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await showPage(tester);
      await command(tester, '清扫二教周边');
      await tap(tester, 'campus-pause');
      await tap(tester, 'campus-resume');
      await tap(tester, 'campus-path-blocked');
      await tap(tester, 'campus-path-blocked');
      await tap(tester, 'campus-emergency');
      await tap(tester, 'campus-reset');
      await tap(tester, 'campus-resume');
      final input = find.byKey(const Key('campus-command-input'));
      await tester.ensureVisible(input);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pump();
      await tester.enterText(input, '不要去实验楼清扫');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
    });
  }
}

class _TestOwner extends StatefulWidget {
  const _TestOwner({required this.child, required this.onDispose});
  final Widget child;
  final VoidCallback onDispose;

  @override
  State<_TestOwner> createState() => _TestOwnerState();
}

class _TestOwnerState extends State<_TestOwner> {
  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }
}
