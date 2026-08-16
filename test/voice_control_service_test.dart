import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/controllers/robot_controller.dart';
import 'package:robot_cleaner/models/robot_status.dart';
import 'package:robot_cleaner/services/voice_control_service.dart';

void main() {
  late RobotController controller;
  late VoiceControlService service;

  setUp(() {
    controller = RobotController(autoProgress: false);
    service = VoiceControlService(controller: controller);
  });

  tearDown(() => controller.dispose());

  group('VoiceControlService 集成', () {
    test('开始清扫A区会选择 A 区并进入清扫中', () {
      final result = service.execute('开始清扫A区');

      expect(result.recognized, isTrue);
      expect(result.success, isTrue);
      expect(result.command, 'start');
      expect(result.area, 'A区');
      expect(controller.currentStatus.area, 'A区');
      expect(controller.currentStatus.state, RobotState.cleaning);
    });

    test('比赛短命令暂停和继续仍经过 Parser 后执行', () {
      service.execute('开始');
      expect(service.execute('暂停').success, isTrue);
      expect(controller.currentStatus.state, RobotState.paused);

      expect(service.execute('继续').success, isTrue);
      expect(controller.currentStatus.state, RobotState.cleaning);
    });

    test('停止和返回充电真实联动状态机', () {
      service.execute('开始清扫B区');
      expect(service.execute('停止').success, isTrue);
      expect(controller.currentStatus.state, RobotState.idle);

      expect(service.execute('返回充电').success, isTrue);
      expect(controller.currentStatus.state, RobotState.charging);
    });

    test('紧急停止触发 emergency 和 WARN-004', () {
      final result = service.execute('紧急停止');

      expect(result.success, isTrue);
      expect(controller.currentStatus.state, RobotState.emergency);
      expect(controller.warningResult.primaryWarningCode, 'WARN-004');
    });

    test('急停后语音开始被 Controller 拒绝', () {
      service.execute('紧急停止');

      final result = service.execute('开始');

      expect(result.recognized, isTrue);
      expect(result.success, isFalse);
      expect(result.resultMessage, contains('先复位'));
      expect(controller.currentStatus.state, RobotState.emergency);
    });

    test('急停后短命令复位可解除锁存', () {
      service.execute('紧急停止');

      final result = service.execute('复位');

      expect(result.recognized, isTrue);
      expect(result.command, 'reset');
      expect(result.success, isTrue);
      expect(controller.currentStatus.state, RobotState.idle);
    });

    test('充电中语音继续被拒绝', () {
      service.execute('返回充电');

      final result = service.execute('继续');

      expect(result.success, isFalse);
      expect(controller.currentStatus.state, RobotState.charging);
    });

    test('无法识别的语句不会调用状态机', () {
      final result = service.execute('今天天气怎么样');

      expect(result.recognized, isFalse);
      expect(result.controlResult, isNull);
      expect(controller.currentStatus.state, RobotState.idle);
    });
  });
}
