import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/main.dart';
import 'package:robot_cleaner/services/product_session.dart';
import 'package:robot_cleaner/pages/tasks_page.dart';
import 'package:robot_cleaner/widgets/tasks/task_card.dart';
import 'package:robot_cleaner/widgets/tasks/task_view_data.dart';
import 'package:robot_cleaner/widgets/geo_map/campus_geo_preview_page.dart';
import 'package:robot_cleaner/widgets/geo_map/campus_geo_map_view.dart';

void main() {
  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    testWidgets('five tabs fit ${size.width} x ${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = ProductSession();
      await tester.pumpWidget(QingQiongApp(session: session));
      await tester.pump(const Duration(milliseconds: 300));
      for (final icon in [
        Icons.assignment,
        Icons.map,
        Icons.notifications,
        Icons.person,
        Icons.home,
      ]) {
        await tester.tap(find.byIcon(icon).last);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: 'tab $icon at $size');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    });
  }
  testWidgets('empty task page and form do not overlap FAB', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TasksPage(tasks: [])));
    expect(find.byType(TaskCard), findsNothing);
    expect(find.text('暂无清扫任务，可通过自然语言控制或 + 创建任务'), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-new-task')));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byKey(const Key('execute-task-button')), findsOneWidget);
  });
  testWidgets('status card consumes shared geo progress without advancing it', (
    tester,
  ) async {
    final session = ProductSession();
    final coordinator = session.campusCoordinator;
    await tester.pumpWidget(
      MaterialApp(home: CampusGeoPreviewPage(coordinator: coordinator)),
    );
    expect(session.voiceControlService.execute('去实验楼清扫').success, isTrue);
    await tester.pump(const Duration(seconds: 10));
    final progress = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('geo-task-progress')),
    );
    expect(progress.value, coordinator.geoProgress);
    expect(progress.value, greaterThan(0));
    coordinator.pause();
    await tester.pump();
    expect(find.text('已暂停'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });
  test('all lifecycle statuses have Chinese presentation', () {
    expect(
      [
        'pending',
        'running',
        'paused',
        'completed',
        'cancelled',
        'failed',
      ].map(taskStatusLabel),
      ['待执行', '执行中', '已暂停', '已完成', '已停止', '失败'],
    );
  });
  testWidgets('map uses supplied coordinates and selected labels', (
    tester,
  ) async {
    // The geographic widget must not mutate data while resolving label overlap.
    final session = ProductSession();
    await tester.pumpWidget(
      MaterialApp(
        home: CampusGeoPreviewPage(coordinator: session.campusCoordinator),
      ),
    );
    final before = tester
        .widget<CampusGeoMapView>(find.byType(CampusGeoMapView))
        .zones;
    session.campusCoordinator.selectZone('lab_building');
    await tester.pump();
    final after = tester
        .widget<CampusGeoMapView>(find.byType(CampusGeoMapView))
        .zones;
    expect(after.map((z) => z.center), before.map((z) => z.center));
    expect(find.byKey(const Key('geo-zone-lab_building')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });
}
