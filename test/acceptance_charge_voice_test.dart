import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/main.dart';
import 'package:robot_cleaner/data/campus/campus_map_data.dart';
import 'package:robot_cleaner/data/campus_geo/campus_geo_map_data.dart';
import 'package:robot_cleaner/models/robot_status.dart';
import 'package:robot_cleaner/services/product_session.dart';

void main() {
  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    testWidgets('feedback stays above navigation at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = ProductSession();
      s.startOrCreateTask();
      await tester.pumpWidget(QingQiongApp(session: s));
      for (final key in ['pause-button', 'stop-button']) {
        final button = find.byKey(Key(key));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump(const Duration(milliseconds: 300));
        final bar = find.byType(SnackBar);
        expect(bar, findsOneWidget);
        expect(
          tester.getRect(bar).bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(NavigationBar)).top),
        );
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      s.dispose();
    });
  }
  testWidgets('return route moves, arrives, charges and finishes at 100', (
    tester,
  ) async {
    final s = ProductSession();
    addTearDown(s.dispose);
    final c = s.campusCoordinator;
    c.startCampusCleaning('canteen_1');
    expect(c.selectedZoneId, 'canteen_1');
    expect(c.geoPlannedPath, isNotEmpty);
    expect(c.plannedPath, isNotEmpty);
    await tester.pump(const Duration(seconds: 10));
    c.stop();
    final start = c.geoRobotPosition;
    final trail = c.geoCleanedPath;
    final battery = s.robotController.currentStatus.battery;
    expect(s.returnToCharge().success, isTrue);
    expect(c.selectedZoneId, isNull);
    expect(c.plannedPath, isEmpty);
    expect(s.robotController.currentStatus.state, RobotState.returningToCharge);
    expect(s.robotController.currentStatus.stateText, '返回充电中');
    await tester.pump();
    for (var i = 0; i < 9; i++) {
      await tester.pump(const Duration(seconds: 10));
      expect(c.geoRobotPosition, isNot(start));
      expect(
        s.robotController.currentStatus.state,
        RobotState.returningToCharge,
      );
      expect(s.robotController.currentStatus.battery, battery);
      expect(c.geoCleanedPath, trail);
    }
    await tester.pump(const Duration(seconds: 10));
    expect(s.robotController.currentStatus.state, RobotState.charging);
    expect(c.geoPlannedPath, isEmpty);
    expect(c.selectedZoneId, isNull);
    final station = CampusGeoMapData.chargingStation.position;
    expect(c.geoRobotPosition.latitude, station.latitude);
    expect(c.geoRobotPosition.longitude, station.longitude);
    await tester.pump(const Duration(seconds: 1));
    expect(s.robotController.currentStatus.battery, greaterThan(battery));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(seconds: 1));
      expect(s.robotController.currentStatus.battery, inInclusiveRange(0, 100));
    }
    expect(s.robotController.currentStatus.battery, 100);
    expect(s.robotController.currentStatus.state, RobotState.idle);
    expect(c.geoPlannedPath, isEmpty);
    expect(c.selectedZoneId, isNull);
    expect(s.taskController.tasks, hasLength(1));
  });

  testWidgets('emergency interrupts return without automatic restart', (
    tester,
  ) async {
    final s = ProductSession();
    addTearDown(s.dispose);
    final c = s.campusCoordinator;
    c.startCampusCleaning('lab_building');
    c.stop();
    s.returnToCharge();
    await tester.pump(const Duration(seconds: 10));
    s.emergencyStop();
    final position = c.geoRobotPosition;
    expect(s.resumeCurrentTask().success, isFalse);
    s.resetEmergency();
    await tester.pump(const Duration(seconds: 30));
    expect(c.geoRobotPosition, position);
    expect(s.robotController.currentStatus.state, RobotState.idle);
  });

  for (final zone in CampusMapData.zones) {
    final aliases = {
      zone.name,
      ...zone.aliases,
      ...?CampusGeoMapData.findZoneById(zone.id)?.aliases,
    };
    for (final alias in aliases) {
      test('campus alias $alias resolves to ${zone.id}', () {
        final s = ProductSession();
        addTearDown(s.dispose);
        final parsed = s.campusCoordinator.interpretVoiceText('去$alias清扫');
        expect(parsed.shouldExecute, isTrue);
        expect(parsed.command, 'start');
        expect(parsed.zoneId, zone.id);
      });
    }
  }
  for (final alias in ['第一食堂', '一餐', '第二教学楼', '二教', '实验楼']) {
    test('dispatcher starts requested $alias in idle session', () {
      final s = ProductSession();
      addTearDown(s.dispose);
      final result = s.voiceControlService.execute('去$alias清扫');
      final expected = alias == '实验楼'
          ? 'lab_building'
          : ['第一食堂', '一餐'].contains(alias)
          ? 'canteen_1'
          : 'teaching_2';
      expect(result.success, isTrue);
      expect(result.command, 'start');
      expect(result.area, expected);
      expect(s.campusCoordinator.selectedZoneId, expected);
      expect(s.robotController.currentStatus.state, RobotState.cleaning);
    });
    test(
      'dispatcher reports requested $alias while busy without creating task',
      () {
        final s = ProductSession();
        addTearDown(s.dispose);
        s.campusCoordinator.startCampusCleaning('lab_building');
        final result = s.voiceControlService.execute('去$alias清扫');
        expect(
          result.area,
          alias == '实验楼'
              ? 'lab_building'
              : ['第一食堂', '一餐'].contains(alias)
              ? 'canteen_1'
              : 'teaching_2',
        );
        expect(result.command, 'start');
        expect(result.success, isFalse);
        expect(s.taskController.tasks, hasLength(1));
        expect(s.campusCoordinator.selectedZoneId, 'lab_building');
      },
    );
  }
  for (final text in ['不要去实验楼清扫', '可以去实验楼清扫吗', '去一餐还是二教清扫']) {
    test('dispatcher rejects $text', () {
      final s = ProductSession();
      addTearDown(s.dispose);
      final result = s.voiceControlService.execute(text);
      expect(result.parseResult.shouldExecute, isFalse);
      expect(result.success, isFalse);
      expect(s.taskController.tasks, isEmpty);
    });
  }
}
