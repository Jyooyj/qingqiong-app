import '../controllers/robot_controller.dart';
import '../utils/voice_command_parser.dart';

class VoiceExecutionResult {
  final String inputText;
  final VoiceCommandResult parseResult;
  final ControlResult? controlResult;

  const VoiceExecutionResult({
    required this.inputText,
    required this.parseResult,
    required this.controlResult,
  });

  bool get recognized => parseResult.recognized;
  bool get success => controlResult?.success ?? false;
  String? get command => parseResult.command;
  String? get area => parseResult.area;

  String get resultMessage {
    if (!recognized) {
      return parseResult.message;
    }
    return controlResult?.message ?? '指令未执行';
  }
}

class VoiceControlService {
  VoiceControlService({required this.controller, VoiceCommandParser? parser})
    : _parser = parser ?? VoiceCommandParser();

  final RobotController controller;
  final VoiceCommandParser _parser;

  static const Map<String, String> _shortCommandAliases = <String, String>{
    '开始': '开始清扫',
    '暂停': '暂停任务',
    '继续': '继续清扫',
    '停止': '停止任务',
    '充电': '返回充电',
    '复位': '执行复位',
  };

  VoiceExecutionResult execute(String inputText) {
    final normalizedInput = inputText.trim();
    final parserInput =
        _shortCommandAliases[normalizedInput] ?? normalizedInput;
    final parseResult = _parser.parse(parserInput);

    if (!parseResult.shouldExecute) {
      return VoiceExecutionResult(
        inputText: inputText,
        parseResult: parseResult,
        controlResult: null,
      );
    }

    final controlResult = _dispatch(parseResult);
    return VoiceExecutionResult(
      inputText: inputText,
      parseResult: parseResult,
      controlResult: controlResult,
    );
  }

  ControlResult _dispatch(VoiceCommandResult result) {
    switch (result.command) {
      case 'start':
        return controller.start(area: result.area);
      case 'pause':
        return controller.pause();
      case 'resume':
        return controller.resume();
      case 'stop':
        return controller.stop();
      case 'charge':
        return controller.charge();
      case 'emergencyStop':
        return controller.emergencyStop();
      case 'reset':
        return controller.reset();
      default:
        return const ControlResult(
          action: RobotAction.stop,
          success: false,
          message: '暂不支持该控制指令',
        );
    }
  }
}
