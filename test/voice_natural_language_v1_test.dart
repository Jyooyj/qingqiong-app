import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/controllers/robot_controller.dart';
import 'package:robot_cleaner/models/robot_status.dart';
import 'package:robot_cleaner/services/voice_control_service.dart';
import 'package:robot_cleaner/utils/voice_command_parser.dart';

void main() {
  final parser = VoiceCommandParser();

  group('V1 自然语言命令', () {
    final cases = <({String input, String command, String? area})>[
      (input: '开始清扫A区', command: 'start', area: 'A区'),
      (input: '去A区清扫', command: 'start', area: 'A区'),
      (input: '帮我开始清扫A区', command: 'start', area: 'A区'),
      (input: '开始B区清扫', command: 'start', area: 'B区'),
      (input: '去C区打扫', command: 'start', area: 'C区'),
      (input: '暂停一下', command: 'pause', area: null),
      (input: '先停一下', command: 'pause', area: null),
      (input: '暂停当前任务', command: 'pause', area: null),
      (input: '继续清扫', command: 'resume', area: null),
      (input: '继续刚才的任务', command: 'resume', area: null),
      (input: '恢复清扫', command: 'resume', area: null),
      (input: '停止清扫', command: 'stop', area: null),
      (input: '结束当前任务', command: 'stop', area: null),
      (input: '去充电', command: 'charge', area: null),
      (input: '回去充电', command: 'charge', area: null),
      (input: '返回充电桩', command: 'charge', area: null),
      (input: '紧急停止', command: 'emergencyStop', area: null),
      (input: '马上急停', command: 'emergencyStop', area: null),
      (input: '立即停止设备', command: 'emergencyStop', area: null),
      (input: '恢复设备', command: 'reset', area: null),
      (input: '解除急停', command: 'reset', area: null),
    ];

    for (final testCase in cases) {
      test('${testCase.input} -> ${testCase.command}', () {
        final result = parser.parse(testCase.input);

        expect(result.recognized, isTrue);
        expect(result.command, testCase.command);
        expect(result.area, testCase.area);
      });
    }
  });

  group('V1 安全语句拦截', () {
    test('否定句不要开始清扫仍然不执行', () {
      final result = parser.parse('不要开始清扫');

      expect(result.recognized, isFalse);
      expect(result.shouldExecute, isFalse);
      expect(result.message, VoiceCommandParser.unclearInstructionMessage);
    });

    test('询问句可以开始清扫吗仍然不执行', () {
      final result = parser.parse('可以开始清扫吗');

      expect(result.recognized, isFalse);
      expect(result.shouldExecute, isFalse);
      expect(result.message, VoiceCommandParser.unclearInstructionMessage);
    });

    test('描述句机器人正在开始清扫不执行', () {
      final result = parser.parse('机器人正在开始清扫');

      expect(result.recognized, isFalse);
      expect(result.shouldExecute, isFalse);
    });

    test('A B C 区冲突仍然拒绝', () {
      final result = parser.parse('开始A区B区C区清扫');

      expect(result.recognized, isFalse);
      expect(result.message, VoiceCommandParser.multipleAreasMessage);
    });
  });

  group('V1 短命令与 Controller 联动', () {
    RobotController createController({RobotState state = RobotState.idle}) {
      return RobotController(
        autoProgress: false,
        initialStatus: RobotStatus(
          robotId: 'R-V1',
          robotName: '语音测试车',
          online: true,
          battery: 80,
          state: state,
          area: 'A区',
          progress: state == RobotState.idle ? 0 : 20,
        ),
      );
    }

    test('暂停 继续 停止短命令均经过 VoiceControlService', () {
      final controller = createController(state: RobotState.cleaning);
      final service = VoiceControlService(controller: controller);
      addTearDown(controller.dispose);

      expect(service.execute('暂停').success, isTrue);
      expect(controller.currentStatus.state, RobotState.paused);
      expect(service.execute('继续').success, isTrue);
      expect(controller.currentStatus.state, RobotState.cleaning);
      expect(service.execute('停止').success, isTrue);
      expect(controller.currentStatus.state, RobotState.idle);
    });

    test('复位短命令只有在急停后成功', () {
      final controller = createController();
      final service = VoiceControlService(controller: controller);
      addTearDown(controller.dispose);

      expect(controller.emergencyStop().success, isTrue);
      expect(service.execute('复位').success, isTrue);
      expect(controller.currentStatus.state, RobotState.idle);
    });

    test('急停状态语音开始不能绕过 RobotController', () {
      final controller = createController();
      final service = VoiceControlService(controller: controller);
      addTearDown(controller.dispose);

      expect(service.execute('紧急停止').success, isTrue);
      final result = service.execute('开始');

      expect(result.recognized, isTrue);
      expect(result.success, isFalse);
      expect(controller.currentStatus.state, RobotState.emergency);
    });
  });
}
