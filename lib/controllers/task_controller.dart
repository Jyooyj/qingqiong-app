import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cleaning_task.dart';
import '../models/robot_status.dart';
import '../repositories/task_repository.dart';
import '../services/safety/safety_decision.dart';
import 'robot_controller.dart';

class TaskController extends ChangeNotifier implements TaskSafetyDecisionSink {
  TaskController({required this.robotController, this.repository});

  final RobotController robotController;
  final TaskRepository? repository;

  final List<CleaningTask> _tasks = <CleaningTask>[];
  ControlResult? _lastControlResult;

  List<CleaningTask> get tasks => List<CleaningTask>.unmodifiable(_tasks);

  CleaningTask? get activeTask {
    for (final task in _tasks.reversed) {
      if (task.status == CleaningTaskStatus.running ||
          task.status == CleaningTaskStatus.paused) {
        return task;
      }
    }
    return null;
  }

  ControlResult? get lastControlResult => _lastControlResult;

  CleaningTask? getTaskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) {
        return task;
      }
    }
    return null;
  }

  CleaningTask createTask({
    required String id,
    required String name,
    required String area,
    required String mode,
    DateTime? plannedAt,
  }) {
    final existing = getTaskById(id);
    if (existing != null) {
      return existing;
    }

    final task = CleaningTask(
      id: id,
      name: name,
      area: area,
      mode: mode,
      status: CleaningTaskStatus.pending,
      progress: 0,
      createdAt: DateTime.now(),
      plannedAt: plannedAt,
      startedAt: null,
      completedAt: null,
      cleanedArea: 0,
      elapsed: Duration.zero,
    );

    _tasks.add(task);
    _persist(task);
    notifyListeners();
    return task;
  }

  bool startTask(String taskId) {
    final index = _findTaskIndex(taskId);

    if (index == -1) return false;

    final task = _tasks[index];

    if (task.status != CleaningTaskStatus.pending &&
        task.status != CleaningTaskStatus.paused) {
      _lastControlResult = const ControlResult(
        action: RobotAction.start,
        success: false,
        message: '只有待执行或已暂停任务可以开始',
      );
      return false;
    }

    final otherActiveTask = activeTask;
    if (otherActiveTask != null && otherActiveTask.id != task.id) {
      _lastControlResult = const ControlResult(
        action: RobotAction.start,
        success: false,
        message: '已有任务正在运行或暂停',
      );
      return false;
    }

    final controlResult =
        task.status == CleaningTaskStatus.paused &&
            robotController.currentStatus.state == RobotState.paused
        ? robotController.resume()
        : robotController.start(area: task.area);
    _lastControlResult = controlResult;

    if (!controlResult.success ||
        robotController.currentStatus.state != RobotState.cleaning) {
      return false;
    }

    _replaceTask(
      index,
      task.copyWith(
        status: CleaningTaskStatus.running,
        startedAt: task.startedAt ?? DateTime.now(),
      ),
    );

    return true;
  }

  bool pauseTask(String taskId) {
    final index = _findTaskIndex(taskId);

    if (index == -1) return false;

    final task = _tasks[index];

    if (task.status != CleaningTaskStatus.running) {
      _lastControlResult = const ControlResult(
        action: RobotAction.pause,
        success: false,
        message: '只有运行中的任务可以暂停',
      );
      return false;
    }

    final controlResult = robotController.pause();
    _lastControlResult = controlResult;

    if (!controlResult.success ||
        robotController.currentStatus.state != RobotState.paused) {
      return false;
    }

    _replaceTask(index, task.copyWith(status: CleaningTaskStatus.paused));

    return true;
  }

  bool resumeTask(String taskId) {
    final index = _findTaskIndex(taskId);

    if (index == -1) return false;

    final task = _tasks[index];

    if (task.status != CleaningTaskStatus.paused) {
      _lastControlResult = const ControlResult(
        action: RobotAction.resume,
        success: false,
        message: '只有已暂停任务可以继续',
      );
      return false;
    }

    final controlResult = robotController.currentStatus.state == RobotState.idle
        ? robotController.start(area: task.area)
        : robotController.resume();
    _lastControlResult = controlResult;

    if (!controlResult.success ||
        robotController.currentStatus.state != RobotState.cleaning) {
      return false;
    }

    _replaceTask(index, task.copyWith(status: CleaningTaskStatus.running));

    return true;
  }

  bool cancelTask(String taskId) {
    final index = _findTaskIndex(taskId);

    if (index == -1) return false;

    final task = _tasks[index];

    if (task.status == CleaningTaskStatus.completed ||
        task.status == CleaningTaskStatus.cancelled) {
      _lastControlResult = const ControlResult(
        action: RobotAction.stop,
        success: false,
        message: '任务已经结束',
      );
      return false;
    }

    if (task.status == CleaningTaskStatus.running ||
        task.status == CleaningTaskStatus.paused) {
      final controlResult = robotController.stop();
      _lastControlResult = controlResult;
      if (!controlResult.success) {
        return false;
      }
    }

    _replaceTask(index, task.copyWith(status: CleaningTaskStatus.cancelled));

    return true;
  }

  bool completeTask(
    String taskId, {
    double cleanedArea = 0,
    Duration? elapsed,
  }) {
    final index = _findTaskIndex(taskId);

    if (index == -1) return false;

    final task = _tasks[index];

    if (task.status != CleaningTaskStatus.running &&
        task.status != CleaningTaskStatus.paused) {
      return false;
    }

    _replaceTask(
      index,
      task.copyWith(
        status: CleaningTaskStatus.completed,
        progress: 100,
        completedAt: DateTime.now(),
        cleanedArea: cleanedArea,
        elapsed: elapsed ?? task.elapsed,
      ),
    );

    return true;
  }

  bool updateTaskProgress(
    String taskId, {
    required double progress,
    required double cleanedArea,
    required Duration elapsed,
  }) {
    final index = _findTaskIndex(taskId);

    if (index == -1) return false;

    final task = _tasks[index];

    if (task.status != CleaningTaskStatus.running) {
      return false;
    }

    final safeProgress = progress.clamp(0, 100).toDouble();

    _replaceTask(
      index,
      task.copyWith(
        progress: safeProgress,
        cleanedArea: cleanedArea,
        elapsed: elapsed,
      ),
    );

    return true;
  }

  int _findTaskIndex(String taskId) {
    return _tasks.indexWhere((task) => task.id == taskId);
  }

  @override
  void applySafetyDecision(SafetyDecision decision) {
    final task = activeTask;
    if (task == null) {
      return;
    }
    final index = _findTaskIndex(task.id);

    switch (decision.directive) {
      case SafetyDirective.none:
        return;
      case SafetyDirective.pause:
      case SafetyDirective.emergencyStop:
        if (task.status == CleaningTaskStatus.running) {
          _replaceTask(index, task.copyWith(status: CleaningTaskStatus.paused));
        }
        return;
      case SafetyDirective.stop:
        _replaceTask(
          index,
          task.copyWith(
            status: CleaningTaskStatus.failed,
            completedAt: DateTime.now(),
          ),
        );
    }
  }

  void _replaceTask(int index, CleaningTask task) {
    _tasks[index] = task;
    _persist(task);
    notifyListeners();
  }

  void _persist(CleaningTask task) {
    final target = repository;
    if (target != null) {
      unawaited(target.save(task));
    }
  }
}
