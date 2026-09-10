import 'package:flutter_test/flutter_test.dart';
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

  void expectResolved(String text, String zoneId, {String? matchedAlias}) {
    final result = resolver.resolve(text);

    expect(result.resolved, isTrue);
    expect(result.ambiguous, isFalse);
    expect(result.zoneId, zoneId);
    expect(result.zoneName, isNotNull);
    expect(result.candidateZoneIds, <String>[zoneId]);
    if (matchedAlias != null) {
      expect(result.matchedAlias, matchedAlias);
    }
  }

  group('CampusZoneResolver', () {
    test('去实验楼清扫', () {
      expectResolved('去实验楼清扫', 'lab_building');
    });

    test('去实验楼附近清扫', () {
      expectResolved('去实验楼附近清扫', 'lab_building');
    });

    test('清扫实验区', () {
      expectResolved('清扫实验区', 'lab_building');
    });

    test('去第一食堂清扫', () {
      expectResolved('去第一食堂清扫', 'canteen_1', matchedAlias: '第一食堂');
    });

    test('去一餐附近', () {
      expectResolved('去一餐附近', 'canteen_1');
    });

    test('清扫二教周边', () {
      expectResolved('清扫二教周边', 'teaching_2');
    });

    test('去学生宿舍清扫', () {
      expectResolved('去学生宿舍清扫', 'dormitory');
    });

    test('开始清扫时未解析到地点', () {
      final result = resolver.resolve('开始清扫');

      expect(result.resolved, isFalse);
      expect(result.ambiguous, isFalse);
      expect(result.zoneId, isNull);
      expect(result.zoneName, isNull);
      expect(result.matchedAlias, isNull);
      expect(result.candidateZoneIds, isEmpty);
    });

    test('去一餐还是二教时返回歧义', () {
      final result = resolver.resolve('去一餐还是二教');

      expect(result.resolved, isFalse);
      expect(result.ambiguous, isTrue);
      expect(result.zoneId, isNull);
      expect(result.zoneName, isNull);
      expect(result.matchedAlias, isNull);
      expect(result.candidateZoneIds, <String>['canteen_1', 'teaching_2']);
    });

    test('实验楼和一餐都要清扫时返回歧义', () {
      final result = resolver.resolve('实验楼和一餐都要清扫');

      expect(result.resolved, isFalse);
      expect(result.ambiguous, isTrue);
      expect(result.candidateZoneIds, <String>['lab_building', 'canteen_1']);
    });

    test('同一地点的 name 和 alias 同时出现仍只解析一个地点', () {
      expectResolved('实验楼和实验区都要清扫', 'lab_building', matchedAlias: '实验楼');
    });

    test('同一地点多个匹配词时返回最长的 matchedAlias', () {
      expectResolved('先去第一食堂，也叫一食堂', 'canteen_1', matchedAlias: '第一食堂');
    });

    test('解析时忽略半角和全角空格', () {
      expectResolved('去 实　验 楼 清扫', 'lab_building');
    });
  });
}
