import 'package:flutter_test/flutter_test.dart';

import 'package:robot_cleaner/controllers/robot_controller.dart';
import 'package:robot_cleaner/controllers/task_controller.dart';
import 'package:robot_cleaner/models/cleaning_task.dart';
import 'package:robot_cleaner/models/robot_status.dart';
import 'package:robot_cleaner/services/demo_simulation_engine.dart';

void main() {
  group('DemoSimulationEngine', () {
    late RobotController robotController;
    late TaskController taskController;
    late DemoSimulationEngine engine;

    setUp(() {
      robotController = RobotController(
        autoProgress: false,
      );

      taskController = TaskController(
        robotController: robotController,
      );

      engine = DemoSimulationEngine(
        taskController: taskController,
        robotController: robotController,
      );
    });

    tearDown(() {
      engine.dispose();
      robotController.dispose();
    });

    test('running状态下模拟数据会持续推进', () async {
      taskController.createTask(
        id: 'task_001',
        name: 'A区标准清扫',
        area: 'A区',
        mode: 'standard',
      );

      final started = taskController.startTask('task_001');

      expect(started, isTrue);

      engine.start('task_001');

      final before =
          taskController.getTaskById('task_001')!;

      expect(before.progress, 0);

      await Future<void>.delayed(
        const Duration(milliseconds: 1200),
      );

      final after =
          taskController.getTaskById('task_001')!;

      expect(after.progress, greaterThan(0));
      expect(after.cleanedArea, greaterThan(0));
      expect(
        after.elapsed,
        greaterThan(Duration.zero),
      );

      expect(
        engine.currentMapState.cleanedPath,
        isNotEmpty,
      );
    });

    test('paused状态下模拟数据冻结', () async {
      taskController.createTask(
        id: 'task_001',
        name: 'A区标准清扫',
        area: 'A区',
        mode: 'standard',
      );

      taskController.startTask('task_001');
      engine.start('task_001');

      await Future<void>.delayed(
        const Duration(milliseconds: 1200),
      );

      final paused =
          taskController.pauseTask('task_001');

      expect(paused, isTrue);

      final before =
          taskController.getTaskById('task_001')!;

      final progressBefore = before.progress;
      final areaBefore = before.cleanedArea;
      final elapsedBefore = before.elapsed;

      await Future<void>.delayed(
        const Duration(milliseconds: 1200),
      );

      final after =
          taskController.getTaskById('task_001')!;

      expect(after.status, CleaningTaskStatus.paused);
      expect(after.progress, progressBefore);
      expect(after.cleanedArea, areaBefore);
      expect(after.elapsed, elapsedBefore);
    });

    test('paused后resume可以恢复模拟推进', () async {
      taskController.createTask(
        id: 'task_001',
        name: 'A区标准清扫',
        area: 'A区',
        mode: 'standard',
      );

      taskController.startTask('task_001');
      engine.start('task_001');

      await Future<void>.delayed(
        const Duration(milliseconds: 1200),
      );

      taskController.pauseTask('task_001');

      final pausedProgress =
          taskController.getTaskById('task_001')!.progress;

      await Future<void>.delayed(
        const Duration(milliseconds: 1100),
      );

      final resumed =
          taskController.resumeTask('task_001');

      expect(resumed, isTrue);

      await Future<void>.delayed(
        const Duration(milliseconds: 1200),
      );

      final after =
          taskController.getTaskById('task_001')!;

      expect(after.status, CleaningTaskStatus.running);
      expect(after.progress, greaterThan(pausedProgress));
    });

    test('紧急停止后模拟数据冻结', () async {
      taskController.createTask(
        id: 'task_001',
        name: 'A区标准清扫',
        area: 'A区',
        mode: 'standard',
      );

      taskController.startTask('task_001');
      engine.start('task_001');

      await Future<void>.delayed(
        const Duration(milliseconds: 1200),
      );

      final emergencyResult =
          robotController.emergencyStop();

      expect(emergencyResult.success, isTrue);

      expect(
        robotController.currentStatus.state,
        RobotState.emergency,
      );

      final before =
          taskController.getTaskById('task_001')!;

      final progressBefore = before.progress;
      final areaBefore = before.cleanedArea;
      final elapsedBefore = before.elapsed;

      await Future<void>.delayed(
        const Duration(milliseconds: 1200),
      );

      final after =
          taskController.getTaskById('task_001')!;

      expect(after.progress, progressBefore);
      expect(after.cleanedArea, areaBefore);
      expect(after.elapsed, elapsedBefore);
    });

    test('启动模拟后会加载对应区域规划路径', () {
      taskController.createTask(
        id: 'task_001',
        name: 'B区标准清扫',
        area: 'B区',
        mode: 'standard',
      );

      taskController.startTask('task_001');

      engine.start('task_001');

      expect(
        engine.currentMapState.plannedPath,
        isNotEmpty,
      );

      expect(
        engine.currentMapState.cleanedPath,
        isEmpty,
      );
    });

    test('pending任务不能直接启动模拟引擎', () {
      taskController.createTask(
        id: 'task_001',
        name: 'A区标准清扫',
        area: 'A区',
        mode: 'standard',
      );

      engine.start('task_001');

      expect(engine.isRunning, isFalse);

      final task =
          taskController.getTaskById('task_001')!;

      expect(
        task.status,
        CleaningTaskStatus.pending,
      );
    });
  });
}
