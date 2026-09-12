import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/controllers/robot_controller.dart';
import 'package:robot_cleaner/controllers/task_controller.dart';
import 'package:robot_cleaner/models/robot_status.dart';
import 'package:robot_cleaner/services/demo_simulation_engine.dart';
import 'package:robot_cleaner/services/product_session.dart';

void main() {
  test('冷启动必须为 idle、无任务、0进度、无激活告警', () {
    final robot = RobotController(
      autoProgress: false,
      initialStatus: const RobotStatus(
        robotId: 'QQ-COLD-START',
        robotName: '清穹冷启动测试车',
        online: true,
        battery: 80,
        state: RobotState.idle,
        area: 'A区',
        progress: 0,
      ),
    );

    final tasks = TaskController(robotController: robot);

    final simulation = DemoSimulationEngine(
      taskController: tasks,
      robotController: robot,
      tickInterval: const Duration(days: 1),
      progressPerTick: 25,
      cleanedAreaPerTick: 4,
    );

    final session = ProductSession(
      robotController: robot,
      taskController: tasks,
      simulationEngine: simulation,
    );

    expect(robot.currentStatus.state, RobotState.idle);
    expect(robot.currentStatus.progress, 0);
    expect(session.currentTask, isNull);
    expect(robot.warningResult.primaryWarningCode, isNull);

    session.dispose();
    robot.dispose();
  });
}
