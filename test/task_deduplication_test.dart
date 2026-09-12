import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/services/product_session.dart';

void main() {
  test('repeated ProductSession create requests return one active task', () {
    final session = ProductSession();
    addTearDown(session.dispose);
    final first = session.createTask(
      name: '实验楼清扫任务',
      area: 'A区',
      mode: '校园标准清扫',
    );
    final second = session.createTask(
      name: '实验楼清扫任务',
      area: 'A区',
      mode: '校园标准清扫',
    );
    expect(second.id, first.id);
    expect(session.taskController.tasks, hasLength(1));
  });

  test('TaskController itself rejects rapid active duplicates', () {
    final session = ProductSession();
    addTearDown(session.dispose);
    final controller = session.taskController;
    final first = controller.createTask(
      id: 'one',
      name: '一餐清扫任务',
      area: 'A区',
      mode: '校园标准清扫',
    );
    final second = controller.createTask(
      id: 'two',
      name: '一餐清扫任务',
      area: 'A区',
      mode: '校园标准清扫',
    );
    expect(second.id, first.id);
    expect(controller.tasks, hasLength(1));
  });

  test(
    'active campus task rejects same and different campus requests without junk tasks',
    () {
      final session = ProductSession();
      addTearDown(session.dispose);
      final coordinator = session.campusCoordinator;
      expect(coordinator.startCampusCleaning('lab_building').success, isTrue);
      expect(coordinator.startCampusCleaning('lab_building').success, isFalse);
      expect(coordinator.startCampusCleaning('canteen_1').success, isFalse);
      expect(session.taskController.tasks, hasLength(1));
    },
  );
}
