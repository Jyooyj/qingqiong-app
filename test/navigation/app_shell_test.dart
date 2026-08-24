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

  testWidgets('AppShell default shows Home and navigation works', (
    tester,
  ) async {
    // Set mobile size 360x800
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await pumpApp(tester);

    // Default should show Home (area selector present)
    expect(find.byKey(const Key('area-selector')), findsOneWidget);

    // Bottom navigation has five entries (icons should be present)
    expect(find.byIcon(Icons.home), findsWidgets);
    expect(find.byIcon(Icons.assignment), findsWidgets);
    expect(find.byIcon(Icons.map), findsWidgets);
    expect(find.byIcon(Icons.notifications), findsWidgets);
    expect(find.byIcon(Icons.person), findsWidgets);

    // Tap 任务
    await tester.tap(find.byIcon(Icons.assignment).first);
    await tester.pumpAndSettle();
    expect(find.text('任务中心'), findsOneWidget);
    expect(find.byKey(const Key('filter-all')), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tap 地图
    await tester.tap(find.byIcon(Icons.map).first);
    await tester.pumpAndSettle();
    expect(find.text('地图 / 轨迹'), findsOneWidget);
    expect(find.text('A区'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Tap 告警
    await tester.ensureVisible(find.byIcon(Icons.notifications).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.notifications).first);
    await tester.pumpAndSettle();
    expect(find.text('告警中心'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tap 我的
    await tester.tap(find.byIcon(Icons.person).first);
    await tester.pumpAndSettle();
    expect(find.text('我的 / 设置'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tap 回首页
    await tester.tap(find.byIcon(Icons.home).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('area-selector')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
