import '../models/cleaning_task.dart';
import '../models/robot_status.dart';
import 'robot_controller.dart';

class TaskController {
  TaskController({
    required this.robotController,
  });

  final RobotController robotController;

  final List<CleaningTask> _tasks = [];

  List<CleaningTask> get tasks => List.unmodifiable(_tasks);

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
    return task;
  }

  bool startTask(String taskId) {
    final index = _findTaskIndex(taskId);

    if (index == -1) return false;

    final task = _tasks[index];

    if (task.status != CleaningTaskStatus.pending &&
        task.status != CleaningTaskStatus.paused) {
      return false;
    }

    robotController.selectArea(task.area);

    if (task.status == CleaningTaskStatus.paused) {
      robotController.resumeCleaning();
    } else {
      robotController.startCleaning();
    }

    if (robotController.currentStatus.state != RobotState.cleaning) {
      return false;
    }

    _tasks[index] = task.copyWith(
      status: CleaningTaskStatus.running,
      startedAt: task.startedAt ?? DateTime.now(),
    );

    return true;
  }

  bool pauseTask(String taskId) {
    final index = _findTaskIndex(taskId);

    if (index == -1) return false;

    final task = _tasks[index];

    if (task.status != CleaningTaskStatus.running) {
      return false;
    }

    robotController.pauseCleaning();

    if (robotController.currentStatus.state != RobotState.paused) {
      return false;
    }

    _tasks[index] = task.copyWith(
      status: CleaningTaskStatus.paused,
    );

    return true;
  }

  bool resumeTask(String taskId) {
    final index = _findTaskIndex(taskId);

    if (index == -1) return false;

    final task = _tasks[index];

    if (task.status != CleaningTaskStatus.paused) {
      return false;
    }

    robotController.resumeCleaning();

    if (robotController.currentStatus.state != RobotState.cleaning) {
      return false;
    }

    _tasks[index] = task.copyWith(
      status: CleaningTaskStatus.running,
    );

    return true;
  }

  bool cancelTask(String taskId) {
    final index = _findTaskIndex(taskId);

    if (index == -1) return false;

    final task = _tasks[index];

    if (task.status == CleaningTaskStatus.completed ||
        task.status == CleaningTaskStatus.cancelled) {
      return false;
    }

    if (task.status == CleaningTaskStatus.running ||
        task.status == CleaningTaskStatus.paused) {
      robotController.stopCleaning();
    }

    _tasks[index] = task.copyWith(
      status: CleaningTaskStatus.cancelled,
    );

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

    _tasks[index] = task.copyWith(
      status: CleaningTaskStatus.completed,
      progress: 100,
      completedAt: DateTime.now(),
      cleanedArea: cleanedArea,
      elapsed: elapsed ?? task.elapsed,
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

    _tasks[index] = task.copyWith(
      progress: safeProgress,
      cleanedArea: cleanedArea,
      elapsed: elapsed,
    );

    return true;
  }

  int _findTaskIndex(String taskId) {
    return _tasks.indexWhere((task) => task.id == taskId);
  }
}