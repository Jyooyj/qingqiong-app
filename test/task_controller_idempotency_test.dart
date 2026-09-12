import 'package:flutter_test/flutter_test.dart';

import 'package:robot_cleaner/controllers/robot_controller.dart';
import 'package:robot_cleaner/controllers/task_controller.dart';

void main() {
  test('相同任务ID重复创建时只保留一条任务', () {
    final robotController = RobotController(autoProgress: false);
    final taskController = TaskController(robotController: robotController);

    final first = taskController.createTask(
      id: 'task_same_id',
      name: 'A区标准清扫',
      area: 'A区',
      mode: 'standard',
    );

    final second = taskController.createTask(
      id: 'task_same_id',
      name: 'A区标准清扫',
      area: 'A区',
      mode: 'standard',
    );

    expect(second.id, first.id);
    expect(taskController.tasks.length, 1);
    expect(taskController.tasks.single.id, 'task_same_id');

    robotController.dispose();
  });
}
