import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/controllers/robot_controller.dart';
import 'package:robot_cleaner/main.dart';

void main() {
  late RobotController controller;

  setUp(() {
    controller = RobotController(autoProgress: false);
  });

  tearDown(() => controller.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(QingQiongApp(controller: controller));
    await tester.pumpAndSettle();
  }

  testWidgets('Dashboard displays sections and navigates', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);

    // Device overview (robot status card)
    expect(find.byKey(const Key('robot-status-card')), findsOneWidget);

    // Current task card
    expect(find.byKey(const Key('dashboard-current-task')), findsOneWidget);

    // Quick controls (control panel)
    expect(find.byKey(const Key('control-panel')), findsOneWidget);
    // Voice control entry exists
    expect(find.byKey(const Key('voice-button')), findsOneWidget);

    // Area selector should exist exactly once on mobile
    expect(find.byKey(const Key('area-selector')), findsOneWidget);

    // Stats
    expect(find.byKey(const Key('dashboard-stats')), findsOneWidget);

    // Recent alert
    expect(find.byKey(const Key('dashboard-recent-alert')), findsOneWidget);

    // Tap current task should navigate to Tasks tab
    await tester.ensureVisible(find.byKey(const Key('dashboard-current-task')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dashboard-current-task')));
    await tester.pumpAndSettle();
    expect(find.text('任务中心'), findsOneWidget);
    expect(find.byKey(const Key('filter-all')), findsOneWidget);

    // Back to home
    await tester.tap(find.byIcon(Icons.home).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('robot-status-card')), findsOneWidget);

    // Tap recent alert should navigate to Alerts tab
    await tester.ensureVisible(find.byKey(const Key('dashboard-recent-alert')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dashboard-recent-alert')));
    await tester.pumpAndSettle();
    expect(find.text('告警中心'), findsOneWidget);

    // Back to home then trigger a demo fault to produce a warning and verify severity and time display
    await tester.tap(find.byIcon(Icons.home).first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('demo-fault-panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('demo-fault-panel')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('fault-低电量')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fault-低电量')));
    await tester.pump();

    // Severity mapping 'high' -> '高' and occurred time '刚刚' should be visible
    expect(find.text('高'), findsWidgets);
    expect(find.text('刚刚'), findsWidgets);

    // Now verify desktop viewport also has exactly one area-selector
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester);
    expect(find.byKey(const Key('area-selector')), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
