import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/services/campus_voice_action_mapper.dart';
import 'package:robot_cleaner/services/campus_voice_command_interpreter.dart';
import 'package:robot_cleaner/services/campus_zone_resolver.dart';

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
  const mapper = CampusVoiceActionMapper();

  CampusVoiceAction mapText(String text) {
    return mapper.map(interpreter.interpret(text));
  }

  void expectCampusStart(
    String text, {
    required String zoneId,
    required String zoneName,
  }) {
    final action = mapText(text);

    expect(action.type, CampusVoiceActionType.startCleaning);
    expect(action.executable, isTrue);
    expect(action.zoneId, zoneId);
    expect(action.zoneName, zoneName);
    expect(action.message, '已识别指令：start');
    expect(action.originalText, text);
  }

  void expectLegacyAction(String text, CampusVoiceActionType expectedType) {
    final action = mapText(text);

    expect(action.type, expectedType);
    expect(action.executable, isTrue);
    expect(action.zoneId, isNull);
    expect(action.zoneName, isNull);
    expect(action.originalText, text);
  }

  void expectRejected(String text) {
    final action = mapText(text);

    expect(action.type, CampusVoiceActionType.none);
    expect(action.executable, isFalse);
    expect(action.zoneId, isNull);
    expect(action.zoneName, isNull);
    expect(action.message, isNotEmpty);
    expect(action.originalText, text);
  }

  group('CampusVoiceActionMapper', () {
    test('去实验楼清扫映射为实验楼清扫动作', () {
      expectCampusStart('去实验楼清扫', zoneId: 'lab_building', zoneName: '实验楼');
    });

    test('去一餐附近清扫映射为第一食堂清扫动作', () {
      expectCampusStart('去一餐附近清扫', zoneId: 'canteen_1', zoneName: '第一食堂');
    });

    test('清扫二教周边映射为第二教学楼清扫动作', () {
      expectCampusStart('清扫二教周边', zoneId: 'teaching_2', zoneName: '第二教学楼');
    });

    test('去学生宿舍清扫映射为宿舍区清扫动作', () {
      expectCampusStart('去学生宿舍清扫', zoneId: 'dormitory', zoneName: '宿舍区');
    });

    test('暂停任务映射为 pause', () {
      expectLegacyAction('暂停任务', CampusVoiceActionType.pause);
    });

    test('继续清扫映射为 resume', () {
      expectLegacyAction('继续清扫', CampusVoiceActionType.resume);
    });

    test('停止任务映射为 stop', () {
      expectLegacyAction('停止任务', CampusVoiceActionType.stop);
    });

    test('返回充电桩映射为 charge', () {
      expectLegacyAction('返回充电桩', CampusVoiceActionType.charge);
    });

    test('紧急停止映射为 emergencyStop', () {
      expectLegacyAction('紧急停止', CampusVoiceActionType.emergencyStop);
    });

    test('解除急停映射为 reset', () {
      expectLegacyAction('解除急停', CampusVoiceActionType.reset);
    });

    test('不要去实验楼清扫映射为 none', () {
      expectRejected('不要去实验楼清扫');
    });

    test('可以去实验楼清扫吗映射为 none', () {
      expectRejected('可以去实验楼清扫吗');
    });

    test('去一餐还是二教映射为 none', () {
      expectRejected('去一餐还是二教');
    });

    test('无关文本映射为 none', () {
      expectRejected('帮我开灯');
    });

    test('开始清扫A区保持旧区域兼容映射', () {
      expectLegacyAction('开始清扫A区', CampusVoiceActionType.startCleaning);
    });
  });
}
