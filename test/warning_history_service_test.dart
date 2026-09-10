import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/controllers/robot_controller.dart';
import 'package:robot_cleaner/models/robot_status.dart';
import 'package:robot_cleaner/services/warning/warning_history_service.dart';
import 'package:robot_cleaner/services/warning/warning_record.dart';
import 'package:robot_cleaner/services/warning_service.dart';

void main() {
  final warningService = WarningService();
  final occurredAt = DateTime.utc(2026, 8, 25, 10, 30);
  final resolvedAt = DateTime.utc(2026, 8, 25, 10, 35);

  test('WarningRecord 正确创建并包含时间与处理建议', () {
    final history = WarningHistoryService(clock: () => occurredAt);
    final result = warningService.evaluate(
      const RobotWarningState(pathBlocked: true),
    );

    final records = history.synchronize(result, taskId: 'TASK-007');

    expect(records, hasLength(1));
    expect(records.single.code, 'WARN-007');
    expect(records.single.title, '路径阻塞');
    expect(records.single.level, WarningLevel.medium);
    expect(records.single.occurredAt, occurredAt);
    expect(records.single.taskId, 'TASK-007');
    expect(records.single.recommendation, contains('重新评估'));
    expect(records.single.handleStatus, WarningHandleStatus.unhandled);
  });

  test('同一当前告警不重复建档，消失后进入历史', () {
    final history = WarningHistoryService(clock: () => occurredAt);
    final warning = warningService.evaluate(
      const RobotWarningState(deviceError: true),
    );

    history.synchronize(warning);
    history.synchronize(warning);
    expect(history.currentWarnings, hasLength(1));
    expect(history.allRecords, hasLength(1));

    history.synchronize(warningService.evaluate(const RobotWarningState()));
    expect(history.currentWarnings, isEmpty);
    expect(history.historyWarnings, hasLength(1));
    expect(history.historyWarnings.single.code, 'WARN-005');
  });

  test('acknowledge 只确认告警，不移除当前安全条件', () {
    final history = WarningHistoryService(clock: () => occurredAt);
    final warning = warningService.evaluate(
      const RobotWarningState(pathBlocked: true),
    );
    final record = history.synchronize(warning).single;

    final acknowledged = history.acknowledgeWarning(record.id);

    expect(acknowledged.handleStatus, WarningHandleStatus.acknowledged);
    expect(history.currentWarnings, hasLength(1));
    expect(history.resolveWarning(record.id, reevaluated: warning), isFalse);
    expect(history.recordById(record.id).resolvedAt, isNull);
  });

  test('安全条件消失后 resolve 状态、时间和历史正确', () {
    final history = WarningHistoryService(clock: () => occurredAt);
    final warning = warningService.evaluate(
      const RobotWarningState(pathBlocked: true),
    );
    final record = history.synchronize(warning).single;
    final cleared = warningService.evaluate(const RobotWarningState());

    history.synchronize(cleared);
    final resolved = history.resolveWarning(
      record.id,
      reevaluated: cleared,
      resolvedAt: resolvedAt,
    );

    expect(resolved, isTrue);
    expect(
      history.recordById(record.id).handleStatus,
      WarningHandleStatus.resolved,
    );
    expect(history.recordById(record.id).resolvedAt, resolvedAt);
    expect(history.handledWarnings, hasLength(1));
    expect(history.historyWarnings, hasLength(1));
  });

  test('WARN-004 点击已处理不能代替 RobotController.reset', () {
    final controller = RobotController(
      autoProgress: false,
      initialStatus: const RobotStatus(
        robotId: 'R-HISTORY',
        robotName: '告警测试车',
        online: true,
        battery: 80,
        state: RobotState.idle,
        area: 'A区',
        progress: 0,
      ),
    );
    final history = WarningHistoryService(clock: () => occurredAt);
    addTearDown(controller.dispose);

    controller.emergencyStop();
    final record = history.synchronize(controller.warningResult).single;
    history.acknowledgeWarning(record.id);

    expect(
      history.resolveWarning(record.id, reevaluated: controller.warningResult),
      isFalse,
    );
    expect(controller.currentStatus.state, RobotState.emergency);

    expect(controller.reset().success, isTrue);
    final cleared = controller.warningResult;
    history.synchronize(cleared);
    expect(history.resolveWarning(record.id, reevaluated: cleared), isTrue);
  });
}
