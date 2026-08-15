import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/utils/voice_command_parser.dart';

class _ParserCase {
  final String name;
  final String input;
  final bool recognized;
  final String? command;
  final String? area;
  final String message;
  final bool shouldExecute;

  const _ParserCase({
    required this.name,
    required this.input,
    required this.recognized,
    required this.command,
    required this.area,
    required this.message,
    required this.shouldExecute,
  });
}

_ParserCase _valid(String name, String input, String command, {String? area}) {
  return _ParserCase(
    name: name,
    input: input,
    recognized: true,
    command: command,
    area: area,
    message: '已识别指令：$command',
    shouldExecute: true,
  );
}

_ParserCase _invalid(
  String name,
  String input,
  String message, {
  String? area,
}) {
  return _ParserCase(
    name: name,
    input: input,
    recognized: false,
    command: null,
    area: area,
    message: message,
    shouldExecute: false,
  );
}

void main() {
  final parser = VoiceCommandParser();
  final cases = <_ParserCase>[
    _valid('开始清扫', '开始清扫', 'start'),
    _valid('开始清扫 A 区', '开始清扫A区', 'start', area: 'A区'),
    _valid('清扫 B 区', '清扫B区', 'start', area: 'B区'),
    _valid('暂停任务', '暂停任务', 'pause'),
    _valid('先停一下', '先停一下', 'pause'),
    _valid('继续清扫', '继续清扫', 'resume'),
    _valid('停止任务', '停止任务', 'stop'),
    _valid('返回充电桩', '返回充电桩', 'charge'),
    _valid('紧急停止', '紧急停止', 'emergencyStop'),
    _valid('立即停止优先于普通停止', '请立即停止当前清扫任务', 'emergencyStop'),
    _valid('解除急停', '解除急停', 'reset'),
    _valid('解除急停后开始清扫', '解除急停后开始清扫', 'reset'),
    _valid('紧急停止后返回充电', '紧急停止后返回充电', 'emergencyStop'),
    _valid('多个普通命令只取最高优先级', '停止任务，暂停一下，然后继续清扫', 'stop'),
    _invalid(
      '今天天气怎么样',
      '今天天气怎么样',
      VoiceCommandParser.unclearInstructionMessage,
    ),
    _invalid('空字符串', '', VoiceCommandParser.invalidMessage),
    _invalid('不支持的 D 区', '开始清扫D区', VoiceCommandParser.unsupportedAreaMessage),
    _invalid('同一句出现多个区域', '开始清扫A区和B区', VoiceCommandParser.multipleAreasMessage),
    _invalid('纯空格', '   ', VoiceCommandParser.invalidMessage),
    _valid('C 区提取', '开始清扫C区', 'start', area: 'C区'),
    _valid('小写 a 区', '开始清扫a区', 'start', area: 'A区'),
    _valid('A 与区之间有空格', '开始清扫A 区', 'start', area: 'A区'),
    _invalid('不支持的 1 区', '开始清扫1区', VoiceCommandParser.unsupportedAreaMessage),
    _invalid('不支持的甲区', '开始清扫甲区', VoiceCommandParser.unsupportedAreaMessage),
    _invalid('不支持的东区', '开始清扫东区', VoiceCommandParser.unsupportedAreaMessage),
    _invalid(
      '不支持的教学楼一区',
      '开始清扫教学楼一区',
      VoiceCommandParser.unsupportedAreaMessage,
    ),
    _invalid('只有 A 区没有命令', 'A区', VoiceCommandParser.invalidMessage, area: 'A区'),
    _invalid(
      'B 区和 C 区同时出现',
      '继续清扫B区和C区',
      VoiceCommandParser.multipleAreasMessage,
    ),
    _invalid('否定开始命令', '不要开始清扫', VoiceCommandParser.unclearInstructionMessage),
    _invalid('否定暂停命令', '别暂停任务', VoiceCommandParser.unclearInstructionMessage),
    _invalid('否定返航命令', '不用返回充电', VoiceCommandParser.unclearInstructionMessage),
    _invalid('禁止继续命令', '禁止继续任务', VoiceCommandParser.unclearInstructionMessage),
    _invalid('询问是否开始', '可以开始清扫吗', VoiceCommandParser.unclearInstructionMessage),
    _invalid('能否开始清扫', '能否开始清扫', VoiceCommandParser.unclearInstructionMessage),
    _invalid('询问如何返航', '如何返回充电', VoiceCommandParser.unclearInstructionMessage),
    _invalid('询问如何暂停', '怎么暂停任务', VoiceCommandParser.unclearInstructionMessage),
    _invalid(
      '询问急停含义',
      '紧急停止是什么意思',
      VoiceCommandParser.unclearInstructionMessage,
    ),
    _invalid('询问复位按钮', '复位按钮在哪里', VoiceCommandParser.unclearInstructionMessage),
    _invalid('无关语句', '帮我开灯', VoiceCommandParser.invalidMessage),
    _invalid('否定复位', '不要复位', VoiceCommandParser.unclearInstructionMessage),
    _invalid('询问如何复位', '如何复位', VoiceCommandParser.unclearInstructionMessage),
    _invalid('询问是否复位', '可以复位吗', VoiceCommandParser.unclearInstructionMessage),
    _invalid('单独输入复位', '复位', VoiceCommandParser.invalidMessage),
    _valid('解除紧急状态', '解除紧急状态', 'reset'),
    _valid('执行复位', '执行复位', 'reset'),
    _valid('确认复位', '确认复位', 'reset'),
    _valid('立即停止任务', '立即停止任务', 'emergencyStop'),
    _invalid('连接词后缺少子句', '开始清扫后', VoiceCommandParser.unclearInstructionMessage),
    _invalid('并字后缺少子句', '停止任务并', VoiceCommandParser.unclearInstructionMessage),
    _invalid('连接词前缺少子句', '后执行复位', VoiceCommandParser.unclearInstructionMessage),
    _invalid('并字前缺少子句', '并开始清扫', VoiceCommandParser.unclearInstructionMessage),
    _invalid('然后后缺少子句', '开始清扫然后', VoiceCommandParser.unclearInstructionMessage),
    _invalid(
      '连续连接词',
      '开始清扫并然后停止任务',
      VoiceCommandParser.unclearInstructionMessage,
    ),
    _invalid(
      '否定句优先于不支持区域',
      '不要开始清扫D区',
      VoiceCommandParser.unclearInstructionMessage,
    ),
    _invalid(
      '同一区域重复但没有命令',
      'A区和A区',
      VoiceCommandParser.invalidMessage,
      area: 'A区',
    ),
    _invalid('普通词小区', '小区', VoiceCommandParser.invalidMessage),
    _invalid('普通词清扫区域', '清扫区域', VoiceCommandParser.invalidMessage),
    _invalid('无需停止任务', '无需停止任务', VoiceCommandParser.unclearInstructionMessage),
    _invalid('不能继续任务', '不能继续任务', VoiceCommandParser.unclearInstructionMessage),
  ];

  group('VoiceCommandParser', () {
    setUpAll(() {
      expect(VoiceCommandParser.commandPriority, <String>[
        'emergencyStop',
        'reset',
        'stop',
        'pause',
        'resume',
        'charge',
        'start',
      ], reason: '公开命令优先级必须与唯一有序规则表一致');
    });

    for (var index = 0; index < cases.length; index += 1) {
      final testCase = cases[index];
      final caseId = 'VC-${(index + 1).toString().padLeft(3, '0')}';

      test('$caseId ${testCase.name}', () {
        final result = parser.parse(testCase.input);

        expect(result.recognized, testCase.recognized);
        expect(result.command, testCase.command);
        expect(result.area, testCase.area);
        expect(result.message, testCase.message);
        expect(result.originalText, testCase.input);
        expect(result.shouldExecute, testCase.shouldExecute);
      });
    }
  });
}
