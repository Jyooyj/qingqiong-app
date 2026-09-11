import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/controllers/robot_controller.dart';
import 'package:robot_cleaner/controllers/task_controller.dart';
import 'package:robot_cleaner/main.dart';
import 'package:robot_cleaner/models/cleaning_task.dart';
import 'package:robot_cleaner/models/robot_status.dart';
import 'package:robot_cleaner/services/demo_simulation_engine.dart';
import 'package:robot_cleaner/services/product_session.dart';

void main() {
  _Harness harness() {
    final robot = RobotController(
      autoProgress: false,
      initialStatus: const RobotStatus(
        robotId: 'QQ-INTEGRATION',
        robotName: '清穹集成测试车',
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
    addTearDown(() {
      session.dispose();
      robot.dispose();
    });
    return _Harness(robot: robot, session: session);
  }

  testWidgets('1. UI 创建任务进入真实 TaskController', (tester) async {
    final app = harness();
    await tester.pumpWidget(QingQiongApp(session: app.session));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.assignment).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-new-task')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('new-task-name')), 'A区比赛演示任务');
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pump();

    expect(app.session.taskController.tasks, hasLength(1));
    expect(app.session.taskController.tasks.single.name, 'A区比赛演示任务');
    expect(
      app.session.taskController.tasks.single.status,
      CleaningTaskStatus.pending,
    );
  });

  test('2. TaskController 启动机器人后任务才进入 running', () {
    final app = harness();
    final task = app.session.createTask(name: 'A区任务', area: 'A区', mode: '标准');

    expect(app.session.startTask(task.id), isTrue);
    expect(app.robot.currentStatus.state, RobotState.cleaning);
    expect(
      app.session.taskController.getTaskById(task.id)?.status,
      CleaningTaskStatus.running,
    );
  });

  test('3. RobotController 拒绝时任务不启动', () {
    final app = harness();
    final task = app.session.createTask(name: '低电量任务', area: 'A区', mode: '标准');
    app.robot.setBattery(5);

    expect(app.session.startTask(task.id), isFalse);
    expect(
      app.session.taskController.getTaskById(task.id)?.status,
      CleaningTaskStatus.pending,
    );
  });

  test('4. running 时 simulation 同步推进任务、位置、轨迹和电量时钟', () {
    final app = harness();
    final task = app.session.createTask(name: '模拟任务', area: 'B区', mode: '标准');
    app.session.startTask(task.id);

    app.session.simulationEngine.advanceOneTick();
    final advanced = app.session.taskController.getTaskById(task.id)!;

    expect(advanced.progress, 25);
    expect(advanced.cleanedArea, 4);
    expect(advanced.elapsed, const Duration(days: 1));
    expect(app.robot.currentStatus.progress, 25);
    expect(
      app.session.simulationEngine.currentMapState.cleanedPath,
      isNotEmpty,
    );
  });

  test('5. pause 后 simulation 全部冻结', () {
    final app = harness();
    final task = app.session.createTask(name: '暂停任务', area: 'A区', mode: '标准');
    app.session.startTask(task.id);
    app.session.simulationEngine.advanceOneTick();
    app.session.pauseCurrentTask();
    final before = app.session.taskController.getTaskById(task.id)!;

    app.session.simulationEngine.advanceOneTick();
    final after = app.session.taskController.getTaskById(task.id)!;

    expect(after.progress, before.progress);
    expect(after.cleanedArea, before.cleanedArea);
    expect(after.elapsed, before.elapsed);
  });

  test('6. resume 后 simulation 继续推进', () {
    final app = harness();
    final task = app.session.createTask(name: '继续任务', area: 'A区', mode: '标准');
    app.session.startTask(task.id);
    app.session.pauseCurrentTask();

    expect(app.session.resumeCurrentTask().success, isTrue);
    app.session.simulationEngine.advanceOneTick();
    expect(
      app.session.taskController.getTaskById(task.id)?.progress,
      greaterThan(0),
    );
  });

  test('7. Voice 开始 A 区创建真实任务并启动机器人', () {
    final app = harness();

    final result = app.session.voiceControlService.execute('开始清扫A区');

    expect(result.success, isTrue);
    expect(app.robot.currentStatus.area, 'A区');
    expect(
      app.session.taskController.activeTask?.status,
      CleaningTaskStatus.running,
    );
    expect(app.session.simulationEngine.activeTaskId, isNotNull);
  });

  test('8. Voice 暂停真正暂停当前任务', () {
    final app = harness();
    app.session.voiceControlService.execute('开始清扫A区');

    expect(app.session.voiceControlService.execute('暂停一下').success, isTrue);
    expect(app.robot.currentStatus.state, RobotState.paused);
    expect(
      app.session.taskController.activeTask?.status,
      CleaningTaskStatus.paused,
    );
  });

  test('9. Voice 继续真正恢复任务', () {
    final app = harness();
    app.session.voiceControlService.execute('开始清扫A区');
    app.session.voiceControlService.execute('暂停一下');

    expect(app.session.voiceControlService.execute('继续刚才的任务').success, isTrue);
    expect(app.robot.currentStatus.state, RobotState.cleaning);
    expect(
      app.session.taskController.activeTask?.status,
      CleaningTaskStatus.running,
    );
  });

  test('10. Voice 急停锁存机器人并冻结任务', () {
    final app = harness();
    app.session.voiceControlService.execute('开始清扫A区');

    expect(app.session.voiceControlService.execute('紧急停止').success, isTrue);
    expect(app.robot.currentStatus.state, RobotState.emergency);
    expect(
      app.session.taskController.activeTask?.status,
      CleaningTaskStatus.paused,
    );
    expect(app.robot.warningResult.primaryWarningCode, 'WARN-004');
  });

  test('11. 急停后 Voice start 被统一 Controller 拒绝', () {
    final app = harness();
    app.session.voiceControlService.execute('开始清扫A区');
    app.session.voiceControlService.execute('紧急停止');

    final result = app.session.voiceControlService.execute('开始清扫A区');

    expect(result.success, isFalse);
    expect(app.robot.currentStatus.state, RobotState.emergency);
  });

  test('12. reset 后 Voice 可以恢复原暂停任务', () {
    final app = harness();
    app.session.voiceControlService.execute('开始清扫A区');
    app.session.voiceControlService.execute('紧急停止');

    expect(app.session.voiceControlService.execute('复位').success, isTrue);
    expect(app.session.voiceControlService.execute('继续刚才的任务').success, isTrue);
    expect(app.robot.currentStatus.state, RobotState.cleaning);
  });

  test('13. WARN-007 自动暂停，清障并 resolve 后才能恢复', () {
    final app = harness();
    app.session.voiceControlService.execute('开始清扫A区');

    app.robot.setPathBlocked(true);
    final record = app.session.warningHistory.currentWarnings.single;
    expect(app.robot.currentStatus.state, RobotState.paused);
    expect(
      app.session.taskController.activeTask?.status,
      CleaningTaskStatus.paused,
    );
    expect(app.session.resumeCurrentTask().success, isFalse);

    app.robot.setPathBlocked(false);
    expect(app.session.resolveWarningAndResume(record.id), isTrue);
    expect(app.robot.currentStatus.state, RobotState.cleaning);
  });

  testWidgets('14. WARN-007 在真实地图显示障碍高亮', (tester) async {
    final app = harness();
    app.session.voiceControlService.execute('开始清扫A区');
    app.robot.setPathBlocked(true);
    await tester.pumpWidget(QingQiongApp(session: app.session));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.map).first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('geo-obstacle-WARN-007')), findsOneWidget);
    app.session.simulationEngine.stop();
  });

  test('15. WARN-005 停止机器人、失败任务并停止 simulation', () {
    final app = harness();
    app.session.voiceControlService.execute('开始清扫A区');

    app.robot.setDeviceError(true);

    expect(app.robot.currentStatus.state, RobotState.idle);
    expect(app.session.currentTask?.status, CleaningTaskStatus.failed);
    expect(app.session.simulationEngine.isRunning, isFalse);
  });

  test('16. WARN-002 禁止新任务启动并建议回充', () {
    final app = harness();
    app.robot.setBattery(9);

    final result = app.session.startOrCreateTask(area: 'A区');

    expect(result.success, isFalse);
    expect(app.session.safetyDecision.canStartNewTask, isFalse);
    expect(app.session.safetyDecision.recommendation, contains('返回充电'));
  });

  test('17. WARN-004 普通动作全部拒绝且只有 reset 可解除', () {
    final app = harness();
    app.session.voiceControlService.execute('开始清扫A区');
    app.session.emergencyStop();

    expect(app.robot.start().success, isFalse);
    expect(app.robot.pause().success, isFalse);
    expect(app.robot.resume().success, isFalse);
    expect(app.robot.charge().success, isFalse);
    expect(app.session.resetEmergency().success, isTrue);
    expect(app.robot.currentStatus.state, RobotState.idle);
  });

  test('18. DATA-001 标记不可信并禁止依赖异常电量启动', () {
    final app = harness();
    app.robot.setBattery(101);

    expect(app.session.safetyDecision.dataValid, isFalse);
    expect(app.session.safetyDecision.primaryWarningCode, 'DATA-001');
    expect(app.session.startOrCreateTask(area: 'A区').success, isFalse);
    expect(app.robot.currentStatus.state, RobotState.idle);
  });

  testWidgets('19. WarningHistory 在告警中心真实可见', (tester) async {
    final app = harness();
    app.session.voiceControlService.execute('开始清扫A区');
    app.robot.setPathBlocked(true);
    await tester.pumpWidget(QingQiongApp(session: app.session));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications).first);
    await tester.pumpAndSettle();

    expect(find.text('WARN-007'), findsWidgets);
    expect(find.text('路径阻塞'), findsWidgets);
    expect(find.text('待处理'), findsWidgets);
    app.session.simulationEngine.stop();
  });

  testWidgets('20. 任务完成后历史状态和 Dashboard Stats 更新', (tester) async {
    final app = harness();
    final task = app.session.createTask(name: '完成任务', area: 'C区', mode: '标准');
    app.session.startTask(task.id);
    for (var index = 0; index < 4; index++) {
      app.session.simulationEngine.advanceOneTick();
    }

    expect(
      app.session.taskController.getTaskById(task.id)?.status,
      CleaningTaskStatus.completed,
    );
    expect(app.session.dashboardStats.todayCompletedCount, 1);
    expect(app.session.dashboardStats.totalCleanedArea, 16);

    await tester.pumpWidget(QingQiongApp(session: app.session));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard-stats')), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget);
  });
}

class _Harness {
  const _Harness({required this.robot, required this.session});

  final RobotController robot;
  final ProductSession session;
}
