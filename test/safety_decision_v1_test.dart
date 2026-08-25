import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/controllers/robot_controller.dart';
import 'package:robot_cleaner/models/robot_status.dart';
import 'package:robot_cleaner/services/safety/safety_decision.dart';
import 'package:robot_cleaner/services/warning_service.dart';

void main() {
  const decisionService = SafetyDecisionService();
  final warningService = WarningService();

  RobotController cleaningController() => RobotController(
    autoProgress: false,
    initialStatus: const RobotStatus(
      robotId: 'R-SAFE',
      robotName: '安全测试车',
      online: true,
      battery: 80,
      state: RobotState.cleaning,
      area: 'A区',
      progress: 30,
    ),
  );

  test('WARN-007 形成 pause 决策并让 RobotController 安全暂停', () {
    final controller = cleaningController();
    addTearDown(controller.dispose);

    controller.setPathBlocked(true);
    final decision = decisionService.decide(controller.warningResult);

    expect(decision.directive, SafetyDirective.pause);
    expect(controller.currentStatus.state, RobotState.paused);
    expect(decision.recommendation, contains('重新评估'));
  });

  test('WARN-005 形成 stop 决策并让 RobotController 安全停止', () {
    final controller = cleaningController();
    addTearDown(controller.dispose);

    controller.setDeviceError(true);
    final decision = decisionService.decide(controller.warningResult);

    expect(decision.directive, SafetyDirective.stop);
    expect(controller.currentStatus.state, RobotState.idle);
    expect(controller.currentStatus.progress, 0);
  });

  test('WARN-002 禁止启动新清扫并建议返回充电', () {
    final warning = warningService.evaluate(
      const RobotWarningState(battery: 9),
    );
    final decision = decisionService.decide(warning);

    expect(decision.primaryWarningCode, 'WARN-002');
    expect(decision.canStartNewTask, isFalse);
    expect(decision.recommendation, contains('返回充电'));
  });

  test('WARN-004 形成 emergencyStop 决策并保持 Controller 锁存', () {
    final controller = cleaningController();
    addTearDown(controller.dispose);

    expect(controller.emergencyStop().success, isTrue);
    final decision = decisionService.decide(controller.warningResult);

    expect(decision.directive, SafetyDirective.emergencyStop);
    expect(decision.requiresReset, isTrue);
    expect(controller.start().success, isFalse);
    expect(controller.pause().success, isFalse);
    expect(controller.resume().success, isFalse);
    expect(controller.charge().success, isFalse);
    expect(controller.currentStatus.state, RobotState.emergency);
  });

  test('WARN-004 未 reset 前不可恢复，reset 后才解除', () {
    final controller = cleaningController();
    addTearDown(controller.dispose);

    controller.emergencyStop();
    expect(controller.resume().success, isFalse);
    expect(controller.currentStatus.state, RobotState.emergency);

    expect(controller.reset().success, isTrue);
    expect(controller.currentStatus.state, RobotState.idle);
    expect(controller.warningResult.requireReset, isFalse);
  });

  test('DATA-001 标记数据不可信且不触发错误任务动作', () {
    final controller = RobotController(
      autoProgress: false,
      initialStatus: const RobotStatus(
        robotId: 'R-DATA',
        robotName: '数据测试车',
        online: true,
        battery: 80,
        state: RobotState.idle,
        area: 'A区',
        progress: 0,
      ),
    );
    addTearDown(controller.dispose);

    controller.setBattery(101);
    final decision = decisionService.decide(controller.warningResult);

    expect(decision.primaryWarningCode, 'DATA-001');
    expect(decision.dataValid, isFalse);
    expect(decision.canStartNewTask, isFalse);
    expect(decision.directive, SafetyDirective.none);
    expect(controller.currentStatus.state, RobotState.idle);
    expect(controller.start().success, isFalse);
  });
}
