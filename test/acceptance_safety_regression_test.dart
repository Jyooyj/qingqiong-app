import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/main.dart';
import 'package:robot_cleaner/models/cleaning_task.dart';
import 'package:robot_cleaner/models/robot_status.dart';
import 'package:robot_cleaner/pages/alerts_page.dart';
import 'package:robot_cleaner/services/product_session.dart';
import 'package:robot_cleaner/services/warning/warning_record.dart';
import 'package:robot_cleaner/widgets/geo_map/campus_geo_map_view.dart';
import 'package:robot_cleaner/widgets/geo_map/campus_geo_preview_page.dart';

void main() {
  test(
    'ordinary pause/resume/stop preserves real progress and stopped state',
    () {
      final session = ProductSession();
      try {
        expect(session.startOrCreateTask(area: 'A区').success, isTrue);
        session.simulationEngine.advanceOneTick();
        final progress = session.currentTask!.progress;
        expect(progress, greaterThan(0));
        expect(session.pauseCurrentTask().success, isTrue);
        expect(session.currentTask!.status, CleaningTaskStatus.paused);
        session.simulationEngine.advanceOneTick();
        expect(session.currentTask!.progress, progress);
        expect(session.resumeCurrentTask().success, isTrue);
        expect(session.currentTask!.status, CleaningTaskStatus.running);
        session.simulationEngine.advanceOneTick();
        final beforeStop = session.currentTask!.progress;
        expect(beforeStop, greaterThan(progress));
        expect(session.stopCurrentTask().success, isTrue);
        expect(session.robotController.currentStatus.state, RobotState.idle);
        expect(session.currentTask!.status, CleaningTaskStatus.cancelled);
        expect(session.currentTask!.progress, beforeStop);
        expect(session.currentTask!.progress, lessThan(100));
        session.simulationEngine.advanceOneTick();
        expect(session.currentTask!.progress, beforeStop);
      } finally {
        session.dispose();
      }
    },
  );
  testWidgets(
    'real map switch enters safety chain and clearing never resumes',
    (tester) async {
      final session = ProductSession();
      final coordinator = session.campusCoordinator;
      try {
        expect(coordinator.startCampusCleaning('lab_building').success, isTrue);
        await tester.pumpWidget(
          MaterialApp(home: CampusGeoPreviewPage(coordinator: coordinator)),
        );
        await tester.pump(const Duration(seconds: 10));
        final toggle = find.widgetWithText(SwitchListTile, '模拟路径阻塞');
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pump();
        expect(session.warningHistory.currentWarnings.single.code, 'WARN-007');
        expect(session.currentTask!.status, CleaningTaskStatus.paused);
        expect(session.robotController.currentStatus.state, RobotState.paused);
        expect(
          tester
              .widget<CampusGeoMapView>(find.byType(CampusGeoMapView))
              .obstacles,
          isNotEmpty,
        );
        final position = coordinator.geoRobotPosition;
        final trail = coordinator.geoCleanedPath;
        final localPosition = coordinator.robotPosition;
        await tester.pump(const Duration(seconds: 30));
        expect(coordinator.geoRobotPosition, position);
        expect(coordinator.geoCleanedPath, trail);
        expect(coordinator.robotPosition, localPosition);
        expect(coordinator.resume().success, isFalse);

        await tester.tap(toggle);
        await tester.pump();
        expect(session.warningHistory.currentWarnings, isEmpty);
        expect(
          session.warningHistory.historyWarnings.single.handleStatus,
          WarningHandleStatus.resolved,
        );
        expect(session.currentTask!.status, CleaningTaskStatus.paused);
        expect(session.robotController.currentStatus.state, RobotState.paused);
        expect(
          tester
              .widget<CampusGeoMapView>(find.byType(CampusGeoMapView))
              .obstacles,
          isEmpty,
        );
        await tester.pump(const Duration(seconds: 30));
        expect(coordinator.geoRobotPosition, position);
        expect(coordinator.geoCleanedPath, trail);
        expect(coordinator.robotPosition, localPosition);
        expect(coordinator.resume().success, isTrue);
        expect(session.currentTask!.status, CleaningTaskStatus.running);
        await tester.pump(const Duration(seconds: 10));
        expect(coordinator.geoRobotPosition, isNot(position));
        expect(coordinator.geoCleanedPath.length, greaterThan(trail.length));

        // External fault changes must also update the switch.
        coordinator.setDemoPathBlocked(true);
        await tester.pump();
        expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        session.dispose();
      }
    },
  );

  for (final code in ['WARN-004', 'WARN-007']) {
    testWidgets(
      '$code clears into resolved history retaining identity and time',
      (tester) async {
        final session = ProductSession();
        final coordinator = session.campusCoordinator;
        try {
          coordinator.startCampusCleaning('lab_building');
          if (code == 'WARN-004') {
            expect(coordinator.emergencyStop().success, isTrue);
          } else {
            coordinator.setDemoPathBlocked(true);
          }
          final original = session.warningHistory.currentWarnings.single;
          expect(original.code, code);
          expect(original.title, code == 'WARN-004' ? '紧急停止' : '路径阻塞');
          expect(original.handleStatus, WarningHandleStatus.unhandled);
          expect(session.currentTask!.status, CleaningTaskStatus.paused);
          expect(coordinator.resume().success, isFalse);
          await tester.pumpWidget(QingQiongApp(session: session));
          await tester.tap(find.byIcon(Icons.notifications).first);
          await tester.pumpAndSettle();
          expect(find.text('待处理'), findsWidgets);

          session.acknowledgeWarning(original.id);
          await tester.pump();
          expect(find.text('已确认'), findsWidgets);
          if (code == 'WARN-004') {
            expect(coordinator.reset().success, isTrue);
          } else {
            coordinator.setDemoPathBlocked(false);
          }
          await tester.pump();
          expect(session.warningHistory.currentWarnings, isEmpty);
          expect(
            tester
                .widget<AlertsPage>(find.byType(AlertsPage))
                .currentAlertCount,
            0,
          );
          expect(
            tester.widget<AlertsPage>(find.byType(AlertsPage)).highestLevelText,
            '无',
          );
          final record = session.warningHistory.historyWarnings.single;
          expect(record.id, original.id);
          expect(record.code, original.code);
          expect(record.title, original.title);
          expect(record.occurredAt, original.occurredAt);
          expect(record.handleStatus, WarningHandleStatus.resolved);
          expect(record.resolvedAt, isNotNull);
          await tester.tap(find.byKey(const Key('alerts-history-tab')));
          await tester.pumpAndSettle();
          expect(find.text('待处理'), findsNothing);
          expect(find.text('已解决'), findsWidgets);
          expect(find.text(code), findsWidgets);
          expect(find.text(original.title), findsWidgets);
          final time = [
            original.occurredAt.hour,
            original.occurredAt.minute,
            original.occurredAt.second,
          ].map((value) => value.toString().padLeft(2, '0')).join(':');
          expect(find.text(time), findsWidgets);
          final position = coordinator.geoRobotPosition;
          final trail = coordinator.geoCleanedPath;
          await tester.pump(const Duration(seconds: 30));
          expect(session.currentTask!.status, CleaningTaskStatus.paused);
          expect(coordinator.geoRobotPosition, position);
          expect(coordinator.geoCleanedPath, trail);
          expect(coordinator.resume().success, isTrue);
          expect(session.currentTask!.status, CleaningTaskStatus.running);
          await tester.pump(const Duration(seconds: 10));
          expect(coordinator.geoRobotPosition, isNot(position));
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          session.dispose();
        }
      },
    );
  }
}
