import 'package:flutter_test/flutter_test.dart';

import 'package:robot_cleaner/controllers/robot_controller.dart';
import 'package:robot_cleaner/controllers/task_controller.dart';
import 'package:robot_cleaner/models/cleaning_task.dart';
import 'package:robot_cleaner/models/robot_status.dart';

void main() {
  group('TaskController', () {
    late RobotController robotController;
    late TaskController taskController;

    setUp(() {
      robotController = RobotController(
        autoProgress: false,
      );

      taskController = TaskController(
        robotController: robotController,
      );
    });

    tearDown(() {
      robotController.dispose();
    });

    test('创建任务后默认状态为 pending', () {
      final task = taskController.createTask(
        id: 'task_001',
        name: 'A区标准清扫',
        area: 'A区',
        mode: 'standard',
      );

      expect(
        task.status,
        CleaningTaskStatus.pending,
      );

      expect(
        task.progress,
        0,
      );

      expect(
        task.area,
        'A区',
      );

      expect(
        taskController.tasks.length,
        1,
      );
    });

    test('pending任务开始成功后变为 running', () {
      taskController.createTask(
        id: 'task_001',
        name: 'A区标准清扫',
        area: 'A区',
        mode: 'standard',
      );

      final success = taskController.startTask('task_001');

      final task = taskController.getTaskById('task_001');

      expect(success, isTrue);

      expect(
        task?.status,
        CleaningTaskStatus.running,
      );

      expect(
        robotController.currentStatus.state,
        RobotState.cleaning,
      );

      expect(
        robotController.currentStatus.area,
        'A区',
      );

      expect(
        task?.startedAt,
        isNotNull,
      );
    });

    test('RobotController拒绝开始时任务不能变为 running', () {
      taskController.createTask(
        id: 'task_001',
        name: 'A区标准清扫',
        area: 'A区',
        mode: 'standard',
      );

      // 模拟严重低电量。
      robotController.setBattery(5);

      final success = taskController.startTask('task_001');

      final task = taskController.getTaskById('task_001');

      expect(success, isFalse);

      expect(
        task?.status,
        CleaningTaskStatus.pending,
      );

      expect(
        robotController.currentStatus.state,
        RobotState.idle,
      );
    });

    test('running任务可以暂停为 paused', () {
      taskController.createTask(
        id: 'task_001',
        name: 'A区标准清扫',
        area: 'A区',
        mode: 'standard',
      );

      taskController.startTask('task_001');

      final success = taskController.pauseTask('task_001');

      final task = taskController.getTaskById('task_001');

      expect(success, isTrue);

      expect(
        task?.status,
        CleaningTaskStatus.paused,
      );

      expect(
        robotController.currentStatus.state,
        RobotState.paused,
      );
    });

    test('paused任务可以继续并恢复为 running', () {
      taskController.createTask(
        id: 'task_001',
        name: 'A区标准清扫',
        area: 'A区',
        mode: 'standard',
      );

      taskController.startTask('task_001');
      taskController.pauseTask('task_001');

      final success = taskController.resumeTask('task_001');

      final task = taskController.getTaskById('task_001');

      expect(success, isTrue);

      expect(
        task?.status,
        CleaningTaskStatus.running,
      );

      expect(
        robotController.currentStatus.state,
        RobotState.cleaning,
      );
    });

    test('不存在的任务不能开始', () {
      final success = taskController.startTask(
        'not_exist',
      );

      expect(success, isFalse);
    });

    test('运行中的任务可以取消并进入 cancelled', () {
      taskController.createTask(
        id: 'task_001',
        name: 'A区标准清扫',
        area: 'A区',
        mode: 'standard',
      );

      taskController.startTask('task_001');

      final success = taskController.cancelTask(
        'task_001',
      );

      final task = taskController.getTaskById(
        'task_001',
      );

      expect(success, isTrue);

      expect(
        task?.status,
        CleaningTaskStatus.cancelled,
      );

      expect(
        robotController.currentStatus.state,
        RobotState.idle,
      );
    });

    test('任务完成后状态为 completed 且进度为100', () {
      taskController.createTask(
        id: 'task_001',
        name: 'A区标准清扫',
        area: 'A区',
        mode: 'standard',
      );

      taskController.startTask('task_001');

      final success = taskController.completeTask(
        'task_001',
        cleanedArea: 120.5,
        elapsed: const Duration(minutes: 15),
      );

      final task = taskController.getTaskById(
        'task_001',
      );

      expect(success, isTrue);

      expect(
        task?.status,
        CleaningTaskStatus.completed,
      );

      expect(
        task?.progress,
        100,
      );

      expect(
        task?.cleanedArea,
        120.5,
      );

      expect(
        task?.elapsed,
        const Duration(minutes: 15),
      );

      expect(
        task?.completedAt,
        isNotNull,
      );
    });

    test('只有running任务才能更新进度', () {
      taskController.createTask(
        id: 'task_001',
        name: 'A区标准清扫',
        area: 'A区',
        mode: 'standard',
      );

      final beforeStart = taskController.updateTaskProgress(
        'task_001',
        progress: 20,
        cleanedArea: 10,
        elapsed: const Duration(seconds: 10),
      );

      expect(beforeStart, isFalse);

      taskController.startTask('task_001');

      final afterStart = taskController.updateTaskProgress(
        'task_001',
        progress: 20,
        cleanedArea: 10,
        elapsed: const Duration(seconds: 10),
      );

      final task = taskController.getTaskById(
        'task_001',
      );

      expect(afterStart, isTrue);

      expect(
        task?.progress,
        20,
      );

      expect(
        task?.cleanedArea,
        10,
      );

      expect(
        task?.elapsed,
        const Duration(seconds: 10),
      );
    });

    test('任务进度不能超过100', () {
      taskController.createTask(
        id: 'task_001',
        name: 'A区标准清扫',
        area: 'A区',
        mode: 'standard',
      );

      taskController.startTask('task_001');

      taskController.updateTaskProgress(
        'task_001',
        progress: 150,
        cleanedArea: 20,
        elapsed: const Duration(seconds: 20),
      );

      final task = taskController.getTaskById(
        'task_001',
      );

      expect(
        task?.progress,
        100,
      );
    });
  });
}