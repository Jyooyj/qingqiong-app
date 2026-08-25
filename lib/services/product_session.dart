import 'dart:async';

import 'package:flutter/foundation.dart';

import '../controllers/robot_controller.dart';
import '../controllers/task_controller.dart';
import '../models/cleaning_task.dart';
import '../models/dashboard_stats.dart';
import '../models/robot_status.dart';
import '../repositories/task_repository.dart';
import '../utils/voice_command_parser.dart';
import 'dashboard_stats_service.dart';
import 'demo_simulation_engine.dart';
import 'safety/safety_decision.dart';
import 'voice_control_service.dart';
import 'warning/warning_history_service.dart';
import 'warning/warning_record.dart';

/// 清穹 V1 的应用级组合根。
///
/// 页面只观察本会话；任务、语音和安全操作最终都通过同一个
/// [RobotController]，避免 UI、任务和机器人各自维护状态。
class ProductSession extends ChangeNotifier {
  ProductSession({
    RobotController? robotController,
    TaskController? taskController,
    TaskRepository? taskRepository,
    DemoSimulationEngine? simulationEngine,
    WarningHistoryService? warningHistory,
    this.safetyDecisionService = const SafetyDecisionService(),
    DashboardStatsService? dashboardStatsService,
    bool disposeRobotController = false,
  }) : robotController =
           robotController ?? RobotController(autoProgress: false),
       warningHistory = warningHistory ?? WarningHistoryService(),
       dashboardStatsService = dashboardStatsService ?? DashboardStatsService(),
       _ownsRobotController =
           robotController == null || disposeRobotController {
    this.taskController =
        taskController ??
        TaskController(
          robotController: this.robotController,
          repository: taskRepository ?? InMemoryTaskRepository(),
        );
    this.simulationEngine =
        simulationEngine ??
        DemoSimulationEngine(
          taskController: this.taskController,
          robotController: this.robotController,
        );
    voiceControlService = VoiceControlService(
      controller: this.robotController,
      dispatcher: _dispatchVoiceCommand,
    );

    this.robotController.addListener(_onRobotChanged);
    this.taskController.addListener(_onTaskChanged);
    _mapSubscription = this.simulationEngine.mapStateStream.listen(
      (_) => notifyListeners(),
    );
    _synchronizeWarningAndSafety();
  }

  final RobotController robotController;
  late final TaskController taskController;
  late final DemoSimulationEngine simulationEngine;
  late final VoiceControlService voiceControlService;
  final WarningHistoryService warningHistory;
  final SafetyDecisionService safetyDecisionService;
  final DashboardStatsService dashboardStatsService;
  final bool _ownsRobotController;

  late final StreamSubscription<Object?> _mapSubscription;
  int _taskSequence = 0;
  bool _disposed = false;

  DashboardStats get dashboardStats =>
      dashboardStatsService.calculate(taskController.tasks);

  CleaningTask? get currentTask {
    final active = taskController.activeTask;
    if (active != null) {
      return active;
    }
    for (final task in taskController.tasks.reversed) {
      if (task.status == CleaningTaskStatus.pending) {
        return task;
      }
    }
    return taskController.tasks.isEmpty ? null : taskController.tasks.last;
  }

  SafetyDecision get safetyDecision =>
      safetyDecisionService.decide(robotController.warningResult);

  bool get canStartTask =>
      taskController.activeTask == null && robotController.canStart;

  bool get canPauseTask =>
      taskController.activeTask?.status == CleaningTaskStatus.running &&
      robotController.canPause;

  bool get canResumeTask {
    if (taskController.activeTask?.status != CleaningTaskStatus.paused) {
      return false;
    }
    return robotController.canResume ||
        (robotController.currentStatus.state == RobotState.idle &&
            robotController.warningResult.canStart);
  }

  bool get canStopTask =>
      taskController.activeTask != null && robotController.canStop;

  CleaningTask createTask({
    required String name,
    required String area,
    required String mode,
    String? id,
    DateTime? plannedAt,
  }) {
    return taskController.createTask(
      id: id ?? _nextTaskId(),
      name: name,
      area: area,
      mode: mode,
      plannedAt: plannedAt,
    );
  }

  bool startTask(String taskId) {
    final started = taskController.startTask(taskId);
    if (started) {
      simulationEngine.start(taskId);
    }
    return started;
  }

  ControlResult startOrCreateTask({String? area, String? name}) {
    final targetArea = area ?? robotController.currentStatus.area;
    final active = taskController.activeTask;
    if (active != null) {
      if (active.status == CleaningTaskStatus.paused &&
          active.area == targetArea) {
        return _resumeTask(active.id);
      }
      return const ControlResult(
        action: RobotAction.start,
        success: false,
        message: '已有任务正在运行或暂停',
      );
    }

    CleaningTask? target;
    for (final task in taskController.tasks.reversed) {
      if (task.status == CleaningTaskStatus.pending &&
          task.area == targetArea) {
        target = task;
        break;
      }
    }
    target ??= createTask(
      name: name ?? '$targetArea清扫任务',
      area: targetArea,
      mode: '标准',
    );

    final success = startTask(target.id);
    return _taskControlResult(
      fallbackAction: RobotAction.start,
      success: success,
      successMessage: '已开始${target.name}',
    );
  }

  ControlResult pauseCurrentTask() {
    final task = taskController.activeTask;
    if (task == null) {
      return const ControlResult(
        action: RobotAction.pause,
        success: false,
        message: '当前没有运行中的任务',
      );
    }
    final success = taskController.pauseTask(task.id);
    return _taskControlResult(
      fallbackAction: RobotAction.pause,
      success: success,
      successMessage: '任务已暂停，模拟推进已冻结',
    );
  }

  ControlResult resumeCurrentTask() {
    final task = taskController.activeTask;
    if (task == null) {
      return const ControlResult(
        action: RobotAction.resume,
        success: false,
        message: '当前没有可继续的任务',
      );
    }
    return _resumeTask(task.id);
  }

  ControlResult stopCurrentTask() {
    final task = taskController.activeTask;
    if (task == null) {
      return const ControlResult(
        action: RobotAction.stop,
        success: false,
        message: '当前没有可停止的任务',
      );
    }
    final success = taskController.cancelTask(task.id);
    if (success) {
      simulationEngine.stop();
    }
    return _taskControlResult(
      fallbackAction: RobotAction.stop,
      success: success,
      successMessage: '任务已停止',
    );
  }

  ControlResult returnToCharge() => robotController.charge();

  ControlResult emergencyStop() => robotController.emergencyStop();

  ControlResult resetEmergency() => robotController.reset();

  WarningRecord acknowledgeWarning(String id) {
    final record = warningHistory.acknowledgeWarning(id);
    notifyListeners();
    return record;
  }

  bool resolveWarning(String id) {
    final resolved = warningHistory.resolveWarning(
      id,
      reevaluated: robotController.warningResult,
    );
    if (resolved) {
      notifyListeners();
    }
    return resolved;
  }

  bool resolveWarningAndResume(String id) {
    if (!resolveWarning(id)) {
      return false;
    }
    final task = taskController.activeTask;
    if (task?.status == CleaningTaskStatus.paused) {
      return resumeCurrentTask().success;
    }
    return true;
  }

  ControlResult _resumeTask(String taskId) {
    final success = taskController.resumeTask(taskId);
    if (success && !simulationEngine.isRunning) {
      simulationEngine.start(taskId);
    }
    return _taskControlResult(
      fallbackAction: RobotAction.resume,
      success: success,
      successMessage: '任务已继续',
    );
  }

  ControlResult _dispatchVoiceCommand(VoiceCommandResult command) {
    switch (command.command) {
      case 'start':
        return startOrCreateTask(area: command.area, name: '语音清扫任务');
      case 'pause':
        return pauseCurrentTask();
      case 'resume':
        return resumeCurrentTask();
      case 'stop':
        return stopCurrentTask();
      case 'charge':
        return returnToCharge();
      case 'emergencyStop':
        return emergencyStop();
      case 'reset':
        return resetEmergency();
      default:
        return const ControlResult(
          action: RobotAction.stop,
          success: false,
          message: '暂不支持该控制指令',
        );
    }
  }

  ControlResult _taskControlResult({
    required RobotAction fallbackAction,
    required bool success,
    required String successMessage,
  }) {
    final result = taskController.lastControlResult;
    if (!success && result != null) {
      return result;
    }
    return ControlResult(
      action: fallbackAction,
      success: success,
      message: success ? successMessage : '任务操作被拒绝',
    );
  }

  void _onRobotChanged() {
    _synchronizeWarningAndSafety();
    notifyListeners();
  }

  void _onTaskChanged() {
    notifyListeners();
  }

  void _synchronizeWarningAndSafety() {
    final warning = robotController.warningResult;
    warningHistory.synchronize(warning, taskId: taskController.activeTask?.id);
    final decision = safetyDecisionService.decide(warning);
    taskController.applySafetyDecision(decision);
    if (decision.directive == SafetyDirective.stop) {
      simulationEngine.stop();
    }
  }

  String _nextTaskId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'TASK-$timestamp-${_taskSequence++}';
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    robotController.removeListener(_onRobotChanged);
    taskController.removeListener(_onTaskChanged);
    _mapSubscription.cancel();
    simulationEngine.dispose();
    taskController.dispose();
    if (_ownsRobotController) {
      robotController.dispose();
    }
    super.dispose();
  }
}
