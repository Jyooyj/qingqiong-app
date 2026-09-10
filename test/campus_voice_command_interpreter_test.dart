import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/services/campus_voice_command_interpreter.dart';
import 'package:robot_cleaner/services/campus_zone_resolver.dart';
import 'package:robot_cleaner/utils/voice_command_parser.dart';

void main() {
  final resolver = CampusZoneResolver(const <CampusZoneAliasEntry>[
    CampusZoneAliasEntry(
      id: 'lab_building',
      name: '实验楼',
      aliases: <String>['实验楼', '实验大楼', '实验区'],
    ),
    CampusZoneAliasEntry(
      id: 'canteen_1',
      name: '第一食堂',
      aliases: <String>['一餐', '第一食堂', '一食堂'],
    ),
    CampusZoneAliasEntry(
      id: 'teaching_2',
      name: '第二教学楼',
      aliases: <String>['二教', '第二教学楼', '二号教学楼'],
    ),
    CampusZoneAliasEntry(
      id: 'dormitory',
      name: '宿舍区',
      aliases: <String>['宿舍区', '宿舍', '学生宿舍'],
    ),
  ]);
  final interpreter = CampusVoiceCommandInterpreter(resolver);

  void expectCampusStart(
    String text, {
    required String zoneId,
    required String zoneName,
  }) {
    final result = interpreter.interpret(text);

    expect(result.recognized, isTrue);
    expect(result.shouldExecute, isTrue);
    expect(result.command, 'start');
    expect(result.zoneId, zoneId);
    expect(result.zoneName, zoneName);
    expect(result.matchedAlias, isNotNull);
    expect(result.ambiguous, isFalse);
    expect(result.originalText, text);
    expect(result.legacyParseResult, isNotNull);
    expect(result.zoneResolution.resolved, isTrue);
  }

  void expectRejectedCampusCommand(String text, String zoneId) {
    final result = interpreter.interpret(text);

    expect(result.recognized, isFalse);
    expect(result.shouldExecute, isFalse);
    expect(result.command, isNull);
    expect(result.zoneId, zoneId);
    expect(result.ambiguous, isFalse);
    expect(result.message, VoiceCommandParser.unclearInstructionMessage);
    expect(result.originalText, text);
  }

  void expectLegacyResult(String text, {String? command}) {
    final expected = VoiceCommandParser().parse(text);
    final result = interpreter.interpret(text);

    expect(result.recognized, expected.recognized);
    expect(result.shouldExecute, expected.shouldExecute);
    expect(result.command, command ?? expected.command);
    expect(result.message, expected.message);
    expect(result.originalText, text);
    expect(result.zoneId, isNull);
    expect(result.zoneName, isNull);
    expect(result.matchedAlias, isNull);
    expect(result.ambiguous, isFalse);
    expect(result.zoneResolution.resolved, isFalse);
    expect(result.zoneResolution.ambiguous, isFalse);
    expect(result.legacyParseResult?.area, expected.area);
    expect(result.legacyParseResult?.originalText, expected.originalText);
  }

  group('CampusVoiceCommandInterpreter', () {
    test('去实验楼清扫', () {
      expectCampusStart('去实验楼清扫', zoneId: 'lab_building', zoneName: '实验楼');
    });

    test('去实验楼附近清扫', () {
      expectCampusStart('去实验楼附近清扫', zoneId: 'lab_building', zoneName: '实验楼');
    });

    test('清扫实验区', () {
      expectCampusStart('清扫实验区', zoneId: 'lab_building', zoneName: '实验楼');
    });

    test('去第一食堂清扫', () {
      expectCampusStart('去第一食堂清扫', zoneId: 'canteen_1', zoneName: '第一食堂');
    });

    test('去一餐附近清扫', () {
      expectCampusStart('去一餐附近清扫', zoneId: 'canteen_1', zoneName: '第一食堂');
    });

    test('清扫二教周边', () {
      expectCampusStart('清扫二教周边', zoneId: 'teaching_2', zoneName: '第二教学楼');
    });

    test('去学生宿舍清扫', () {
      expectCampusStart('去学生宿舍清扫', zoneId: 'dormitory', zoneName: '宿舍区');
    });

    test('开始清扫第二教学楼', () {
      expectCampusStart('开始清扫第二教学楼', zoneId: 'teaching_2', zoneName: '第二教学楼');
    });

    test('不要去实验楼清扫时拒绝', () {
      expectRejectedCampusCommand('不要去实验楼清扫', 'lab_building');
    });

    test('可以去实验楼清扫吗时拒绝', () {
      expectRejectedCampusCommand('可以去实验楼清扫吗', 'lab_building');
    });

    test('怎么去实验楼清扫时拒绝', () {
      expectRejectedCampusCommand('怎么去实验楼清扫', 'lab_building');
    });

    test('去一餐还是二教清扫时歧义并拒绝', () {
      final result = interpreter.interpret('去一餐还是二教清扫');

      expect(result.recognized, isFalse);
      expect(result.shouldExecute, isFalse);
      expect(result.command, isNull);
      expect(result.ambiguous, isTrue);
      expect(result.zoneId, isNull);
      expect(
        result.message,
        CampusVoiceCommandInterpreter.ambiguousZoneMessage,
      );
      expect(result.legacyParseResult, isNull);
      expect(result.zoneResolution.candidateZoneIds, <String>[
        'canteen_1',
        'teaching_2',
      ]);
    });

    test('实验楼和一餐都要清扫时歧义并拒绝', () {
      final result = interpreter.interpret('实验楼和一餐都要清扫');

      expect(result.recognized, isFalse);
      expect(result.shouldExecute, isFalse);
      expect(result.ambiguous, isTrue);
      expect(result.zoneResolution.candidateZoneIds, <String>[
        'lab_building',
        'canteen_1',
      ]);
    });

    test('开始清扫A区保持原解析成功', () {
      expectLegacyResult('开始清扫A区', command: 'start');
    });

    test('暂停任务保持原解析成功', () {
      expectLegacyResult('暂停任务', command: 'pause');
    });

    test('紧急停止保持原解析成功', () {
      expectLegacyResult('紧急停止', command: 'emergencyStop');
    });

    test('解除急停保持原解析成功', () {
      expectLegacyResult('解除急停', command: 'reset');
    });

    test('完全无关文本保持原 parser 拒绝', () {
      expectLegacyResult('帮我开灯');
    });
  });
}
