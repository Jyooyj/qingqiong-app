import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/main.dart';
import 'package:robot_cleaner/models/cleaning_task.dart';
import 'package:robot_cleaner/models/robot_status.dart';
import 'package:robot_cleaner/services/product_session.dart';
import 'package:robot_cleaner/services/warning/warning_record.dart';
import 'package:robot_cleaner/widgets/geo_map/campus_geo_map_view.dart';
import 'package:robot_cleaner/widgets/geo_map/campus_geo_preview_page.dart';
import 'package:robot_cleaner/widgets/tasks/task_view_data.dart';

void main() {
  for (final clearMethod in ['chip', 'all', 'map']) {
    testWidgets(
      'real UI blockage cleared with $clearMethod preserves paused task and route',
      (tester) async {
        final s = ProductSession();
        final c = s.campusCoordinator;
        c.startCampusCleaning('canteen_1');
        await tester.pumpWidget(QingQiongApp(session: s));
        await tester.pump(const Duration(seconds: 10));
        final taskId = s.currentTask!.id;
        final progress = s.currentTask!.progress;
        expect(progress, greaterThan(0));
        final position = c.geoRobotPosition;
        final trail = c.geoCleanedPath;
        if (clearMethod == 'map') {
          await tester.tap(find.byIcon(Icons.map).first);
          await tester.pump();
          final toggle = find.widgetWithText(SwitchListTile, '显示临时障碍');
          await tester.ensureVisible(toggle);
          await tester.pumpAndSettle();
          await tester.tap(toggle);
          await tester.pump();
          expect(s.currentTask!.status, CleaningTaskStatus.paused);
          await tester.tap(toggle);
        } else {
          final panel = find.byKey(const Key('demo-fault-panel'));
          await tester.ensureVisible(panel);
          await tester.pumpAndSettle();
          await tester.tap(panel);
          await tester.pumpAndSettle();
          final chip = find.byKey(const Key('fault-路径阻塞'));
          await tester.ensureVisible(chip);
          await tester.pumpAndSettle();
          await tester.tap(chip);
          await tester.pump();
          expect(s.currentTask!.status, CleaningTaskStatus.paused);
          final clear = clearMethod == 'all'
              ? find.byKey(const Key('clear-demo-faults-button'))
              : chip;
          await tester.ensureVisible(clear);
          await tester.pumpAndSettle();
          await tester.tap(clear);
        }
        await tester.pump(const Duration(seconds: 30));
        expect(
          s.taskController.getTaskById(taskId)!.status,
          CleaningTaskStatus.paused,
        );
        expect(s.robotController.currentStatus.state, RobotState.paused);
        expect(s.currentTask!.progress, progress);
        expect(c.geoRobotPosition, position);
        expect(c.geoCleanedPath, trail);
        expect(s.warningHistory.currentWarnings, isEmpty);
        expect(s.warningHistory.historyWarnings.single.code, 'WARN-007');
        expect(
          s.warningHistory.historyWarnings.single.handleStatus,
          WarningHandleStatus.resolved,
        );
        await tester.tap(find.byIcon(Icons.home).first);
        await tester.pump();
        final resume = find.byKey(const Key('resume-button'));
        expect(tester.widget<FilledButton>(resume).onPressed, isNotNull);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('start-button')))
              .onPressed,
          isNull,
        );
        await tester.ensureVisible(resume);
        await tester.pumpAndSettle();
        await tester.tap(resume);
        await tester.pump();
        expect(s.currentTask!.status, CleaningTaskStatus.running);
        expect(c.geoRobotPosition, position);
        await tester.pump(const Duration(seconds: 10));
        expect(c.geoRobotPosition, c.geoPlannedPath[2]);
        expect(s.currentTask!.progress, greaterThan(progress));
        await tester.pumpWidget(const SizedBox.shrink());
        s.dispose();
      },
    );
  }
  test('legacy task at 35 percent clears without cancel or restart', () {
    final s = ProductSession();
    addTearDown(s.dispose);
    s.startOrCreateTask();
    for (var i = 0; i < 7; i++) {
      s.simulationEngine.advanceOneTick();
    }
    expect(s.currentTask!.progress, 35);
    s.robotController.setPathBlocked(true);
    s.robotController.clearDemoFaults();
    expect(s.currentTask!.status, CleaningTaskStatus.paused);
    expect(s.canResumeTask, isTrue);
    s.resumeCurrentTask();
    s.simulationEngine.advanceOneTick();
    expect(s.currentTask!.progress, 40);
  });
  testWidgets(
    'two battery simulation levels and homepage charging downgrade warnings',
    (tester) async {
      final s = ProductSession();
      await tester.pumpWidget(QingQiongApp(session: s));
      final panel = find.byKey(const Key('demo-fault-panel'));
      await tester.ensureVisible(panel);
      await tester.pumpAndSettle();
      await tester.tap(panel);
      await tester.pumpAndSettle();
      for (final label in ['低电量', '严重低电量']) {
        final chip = find.byKey(Key('fault-$label'));
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pump();
        expect(
          s.warningHistory.currentWarnings.single.code,
          label == '低电量' ? 'WARN-001' : 'WARN-002',
        );
        if (label == '低电量') {
          s.robotController.clearDemoFaults();
          await tester.pump();
        }
      }
      expect(s.canStartTask, isFalse);
      final charge = find.byKey(const Key('charge-button'));
      await tester.ensureVisible(charge);
      await tester.pumpAndSettle();
      await tester.tap(charge);
      await tester.pump();
      // Initially at the station, so the first adapter event confirms arrival.
      expect(s.robotController.currentStatus.state, RobotState.charging);
      await tester.pump(const Duration(seconds: 1));
      expect(s.warningHistory.currentWarnings.single.code, 'WARN-001');
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(s.warningHistory.currentWarnings, isEmpty);
      expect(
        s.warningHistory.historyWarnings
            .where((r) => r.code == 'WARN-002')
            .single
            .handleStatus,
        WarningHandleStatus.resolved,
      );
      expect(
        s.warningHistory.historyWarnings
            .where((r) => r.code == 'WARN-001')
            .every((r) => r.handleStatus == WarningHandleStatus.resolved),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      s.dispose();
    },
  );
  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    testWidgets('product map tab and voice sheet fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = ProductSession();
      await tester.pumpWidget(QingQiongApp(session: s));
      await tester.tap(find.byIcon(Icons.map).first);
      await tester.pump();
      expect(find.byType(CampusGeoPreviewPage), findsOneWidget);
      expect(find.text('查看校园地图'), findsNothing);
      expect(
        tester.getSize(find.byType(CampusGeoMapView)).width,
        lessThanOrEqualTo(size.width),
      );
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        expect(text.data ?? '', isNot(matches('UI 预览|Demo|演示位置|坐标拾取')));
      }
      await tester.tap(find.byIcon(Icons.home).first);
      await tester.pump();
      final voice = find.byKey(const Key('voice-button'));
      await tester.ensureVisible(voice);
      await tester.pumpAndSettle();
      await tester.tap(voice);
      await tester.pumpAndSettle();
      expect(find.text('自然语言控制'), findsOneWidget);
      expect(find.text('开始清扫A区'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      s.dispose();
    });

    test('location failure rejects direct and voice return to charge', () {
      final s = ProductSession();
      addTearDown(s.dispose);
      final c = s.campusCoordinator;
      final before = c.geoRobotPosition;
      final battery = s.robotController.currentStatus.battery;
      s.robotController.setLocationFailed(true);
      expect(s.warningHistory.currentWarnings.single.code, 'WARN-006');
      expect(s.robotController.canCharge, isFalse);
      expect(s.returnToCharge().success, isFalse);
      final voice = s.voiceControlService.execute('返回充电');
      expect(voice.success, isFalse);
      expect(s.robotController.currentStatus.state, RobotState.idle);
      expect(c.geoRobotPosition, before);
      expect(s.robotController.currentStatus.battery, battery);
      expect(s.robotController.canEmergencyStop, isTrue);
      s.robotController.setLocationFailed(false);
      expect(s.warningHistory.currentWarnings, isEmpty);
      expect(s.returnToCharge().success, isTrue);
    });
  }
  for (final entry in {
    'pending': '待执行',
    'running': '执行中',
    'paused': '已暂停',
    'completed': '已完成',
    'cancelled': '已停止',
    'failed': '失败',
  }.entries) {
    test(
      'task display ${entry.key} is Chinese without changing stored status',
      () {
        final task = TaskViewData(
          id: 'x',
          name: 'x',
          area: 'A区',
          status: entry.key,
          progress: 35,
          timeText: '',
        );
        expect(task.statusText, entry.value);
        expect(task.status, entry.key);
      },
    );
  }
}
