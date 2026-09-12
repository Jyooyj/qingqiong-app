import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/main.dart';
import 'package:robot_cleaner/services/product_session.dart';
import 'package:robot_cleaner/pages/alerts_page.dart';
import 'package:robot_cleaner/services/warning/warning_record.dart';
import 'package:robot_cleaner/services/warning/warning_history_service.dart';
import 'package:robot_cleaner/services/warning_service.dart';

void main() {
  final cases = <String, RobotWarningState>{
    'WARN-001': const RobotWarningState(battery: 15),
    'WARN-002': const RobotWarningState(battery: 9),
    'WARN-003': const RobotWarningState(online: false),
    'WARN-004': const RobotWarningState(emergency: true),
    'WARN-005': const RobotWarningState(deviceError: true),
    'WARN-006': const RobotWarningState(locationFailed: true),
    'WARN-007': const RobotWarningState(pathBlocked: true),
    'WARN-008': const RobotWarningState(taskFailed: true),
    'DATA-001': const RobotWarningState(batterySensorError: true),
    'customWarning': const RobotWarningState(customWarning: '自定义安全提示'),
  };
  for (final entry in cases.entries) {
    test(
      '${entry.key} archives every occurrence and preserves resolved history',
      () {
        final history = WarningHistoryService();
        final service = WarningService();
        final active = service.evaluate(entry.value);
        final clear = service.evaluate(const RobotWarningState());
        final original = history.synchronize(active).single;
        expect(original.code, entry.key);
        history.synchronize(active);
        expect(history.allRecords, hasLength(1));
        history.synchronize(clear);
        history.synchronize(clear);
        expect(history.currentWarnings, isEmpty);
        final saved = history.historyWarnings.single;
        expect(saved.id, original.id);
        expect(saved.title, original.title);
        expect(saved.occurredAt, original.occurredAt);
        expect(saved.handleStatus, WarningHandleStatus.resolved);
        expect(saved.resolvedAt, isNotNull);
        final next = history.synchronize(active).single;
        expect(next.id, isNot(original.id));
        expect(history.historyWarnings.single.id, original.id);
        expect(history.allRecords, hasLength(2));
        history.synchronize(clear);
        expect(history.currentWarnings, isEmpty);
        expect(history.historyWarnings, hasLength(2));
      },
    );
  }
  test('simultaneous offline and low battery both remain in history', () {
    final history = WarningHistoryService();
    final service = WarningService();
    history.synchronize(
      service.evaluate(const RobotWarningState(online: false, battery: 9)),
    );
    expect(
      history.currentWarnings.map((r) => r.code),
      containsAll(['WARN-003', 'WARN-002']),
    );
    history.synchronize(service.evaluate(const RobotWarningState(battery: 15)));
    expect(history.currentWarnings.single.code, 'WARN-001');
    history.synchronize(service.evaluate(const RobotWarningState()));
    expect(history.currentWarnings, isEmpty);
    expect(
      history.historyWarnings.map((r) => r.code),
      containsAll(['WARN-001', 'WARN-002', 'WARN-003']),
    );
    expect(
      history.historyWarnings.every(
        (r) => r.handleStatus == WarningHandleStatus.resolved,
      ),
      isTrue,
    );
  });
  testWidgets(
    'offline simulation retains WARN-003 after clear and tab navigation',
    (tester) async {
      final session = ProductSession();
      await tester.pumpWidget(QingQiongApp(session: session));
      final panel = find.byKey(const Key('demo-fault-panel'));
      await tester.ensureVisible(panel);
      await tester.tap(panel);
      await tester.pumpAndSettle();
      final offline = find.byKey(const Key('fault-离线'));
      await tester.ensureVisible(offline);
      await tester.tap(offline);
      await tester.pump();
      final original = session.warningHistory.currentWarnings.single;
      expect(original.code, 'WARN-003');
      final clear = find.byKey(const Key('clear-demo-faults-button'));
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pump();
      expect(session.warningHistory.currentWarnings, isEmpty);
      expect(session.warningHistory.historyWarnings.single.id, original.id);
      expect(
        session.warningHistory.historyWarnings.single.handleStatus,
        WarningHandleStatus.resolved,
      );
      await tester.tap(find.byIcon(Icons.notifications).first);
      await tester.pumpAndSettle();
      expect(
        tester.widget<AlertsPage>(find.byType(AlertsPage)).currentAlertCount,
        0,
      );
      await tester.tap(find.byKey(const Key('alerts-history-tab')));
      await tester.pumpAndSettle();
      expect(find.text('WARN-003'), findsWidgets);
      expect(find.text('设备离线'), findsWidgets);
      expect(find.text('已解决'), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    },
  );
}
