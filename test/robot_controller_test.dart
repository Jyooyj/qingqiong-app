import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/controllers/robot_controller.dart';
import 'package:robot_cleaner/models/robot_status.dart';

void main() {
  late RobotController controller;

  setUp(() {
    controller = RobotController(autoProgress: false);
  });

  tearDown(() {
    controller.dispose();
  });

  group('RobotController 状态机', () {
    test('待机允许开始，开始后进入清扫中', () {
      final result = controller.start();

      expect(result.success, isTrue);
      expect(controller.currentStatus.state, RobotState.cleaning);
      expect(controller.canPause, isTrue);
      expect(controller.canStart, isFalse);
    });

    test('待机不能暂停或继续', () {
      expect(controller.pause().success, isFalse);
      expect(controller.resume().success, isFalse);
      expect(controller.currentStatus.state, RobotState.idle);
    });

    test('清扫可暂停，暂停可继续', () {
      controller.start();
      expect(controller.pause().success, isTrue);
      expect(controller.currentStatus.state, RobotState.paused);

      expect(controller.resume().success, isTrue);
      expect(controller.currentStatus.state, RobotState.cleaning);
    });

    test('清扫或暂停后停止会回待机并重置进度', () {
      controller.start();
      controller.advanceProgress(35);
      controller.pause();

      expect(controller.stop().success, isTrue);
      expect(controller.currentStatus.state, RobotState.idle);
      expect(controller.currentStatus.progress, 0);
    });

    test('充电中不能继续，但可停止充电回待机', () {
      expect(controller.charge().success, isTrue);
      expect(controller.currentStatus.state, RobotState.charging);
      expect(controller.resume().success, isFalse);
      expect(controller.currentStatus.state, RobotState.charging);

      expect(controller.stop().success, isTrue);
      expect(controller.currentStatus.state, RobotState.idle);
    });

    test('急停是锁存状态，普通操作都不能解除', () {
      controller.start();
      expect(controller.emergencyStop().success, isTrue);
      expect(controller.currentStatus.state, RobotState.emergency);

      expect(controller.start().success, isFalse);
      expect(controller.pause().success, isFalse);
      expect(controller.resume().success, isFalse);
      expect(controller.stop().success, isFalse);
      expect(controller.charge().success, isFalse);
      expect(controller.currentStatus.state, RobotState.emergency);
      expect(controller.warningResult.primaryWarningCode, 'WARN-004');
      expect(controller.warningResult.requireReset, isTrue);
    });

    test('急停后只有 reset 能恢复待机', () {
      controller.emergencyStop();

      final result = controller.reset();

      expect(result.success, isTrue);
      expect(controller.currentStatus.state, RobotState.idle);
      expect(controller.warningResult.primaryWarningCode, isNull);
      expect(controller.start().success, isTrue);
    });

    test('非急停状态复位会被拒绝', () {
      expect(controller.reset().success, isFalse);
      expect(controller.currentStatus.state, RobotState.idle);
    });

    test('区域只能在在线待机状态选择', () {
      expect(controller.selectArea('B区').success, isTrue);
      expect(controller.currentStatus.area, 'B区');
      controller.start();

      expect(controller.selectArea('C区').success, isFalse);
      expect(controller.currentStatus.area, 'B区');
      expect(controller.selectArea('D区').success, isFalse);
    });

    test('开始时可原子设置区域', () {
      final result = controller.start(area: 'C区');

      expect(result.success, isTrue);
      expect(controller.currentStatus.area, 'C区');
      expect(controller.currentStatus.state, RobotState.cleaning);
    });

    test('离线和严重低电量通过 Warning 权限禁止开始', () {
      controller.setOnline(false);
      expect(controller.start().success, isFalse);
      expect(controller.warningResult.primaryWarningCode, 'WARN-003');

      controller.setOnline(true);
      controller.setBattery(9);
      expect(controller.start().success, isFalse);
      expect(controller.warningResult.primaryWarningCode, 'WARN-002');
    });

    test('路径阻塞由 Warning 安全动作暂停任务', () {
      controller.start();
      controller.advanceProgress(20);

      controller.setPathBlocked(true);

      expect(controller.currentStatus.state, RobotState.paused);
      expect(controller.currentStatus.progress, 20);
      expect(controller.warningResult.primaryWarningCode, 'WARN-007');
      expect(controller.resume().success, isFalse);
    });

    test('设备故障由 Warning 安全动作停止任务', () {
      controller.start();
      controller.advanceProgress(20);

      controller.setDeviceError(true);

      expect(controller.currentStatus.state, RobotState.idle);
      expect(controller.currentStatus.progress, 0);
      expect(controller.warningResult.primaryWarningCode, 'WARN-005');
      expect(controller.start().success, isFalse);
    });

    test('手动进度支持暂停、继续和完成', () {
      controller.start();
      controller.advanceProgress(25);
      expect(controller.currentStatus.progress, 25);

      controller.pause();
      controller.advanceProgress(25);
      expect(controller.currentStatus.progress, 25);

      controller.resume();
      controller.advanceProgress(75);
      expect(controller.currentStatus.progress, 100);
      expect(controller.currentStatus.state, RobotState.idle);
      expect(controller.currentStatus.stateText, '任务完成');

      controller.start();
      expect(controller.currentStatus.progress, 0);
    });

    test('重复快速开始不会产生第二次状态变更', () {
      var notifications = 0;
      controller.addListener(() => notifications++);

      expect(controller.start().success, isTrue);
      expect(controller.start().success, isFalse);

      expect(notifications, 1);
      expect(controller.currentStatus.state, RobotState.cleaning);
    });
  });
}
