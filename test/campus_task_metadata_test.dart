import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/data/campus_geo/campus_geo_map_data.dart';
import 'package:robot_cleaner/services/product_session.dart';

void main() {
  const expected = <String, String>{
    'lab_building': '实验楼',
    'canteen_1': '第一食堂',
    'teaching_2': '第二教学楼',
  };

  for (final item in expected.entries) {
    test('${item.key} creates stable campus presentation metadata', () {
      final session = ProductSession();
      addTearDown(session.dispose);
      final result = session.campusCoordinator.startCampusCleaning(item.key);
      expect(result.success, isTrue);
      final task = session.currentTask!;
      expect(task.campusZoneId, item.key);
      expect(task.displayArea, item.value);
      expect(task.displayTaskName, '${item.value}清扫任务');
      expect(CampusGeoMapData.findZoneById(task.campusZoneId!), isNotNull);
      expect(CampusGeoMapData.routeForZone(task.campusZoneId!), isNotNull);
    });
  }

  test('campus display metadata survives task lifecycle transitions', () {
    final session = ProductSession();
    addTearDown(session.dispose);
    final coordinator = session.campusCoordinator;
    expect(coordinator.startCampusCleaning('lab_building').success, isTrue);
    final task = session.currentTask!;
    expect(task.displayArea, '实验楼');
    expect(task.displayTaskName, '实验楼清扫任务');
    session.pauseCurrentTask();
    expect(session.currentTask!.displayArea, '实验楼');
    session.resumeCurrentTask();
    expect(session.currentTask!.displayTaskName, '实验楼清扫任务');
    session.stopCurrentTask();
    expect(session.taskController.tasks.single.displayArea, '实验楼');
    expect(session.taskController.tasks.single.displayTaskName, '实验楼清扫任务');
  });
}
