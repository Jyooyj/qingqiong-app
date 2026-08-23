import 'dart:async';

import '../controllers/robot_controller.dart';
import '../controllers/task_controller.dart';
import '../data/mock_map_data.dart';
import '../models/cleaning_task.dart';
import '../models/map_state.dart';
import '../models/robot_status.dart';

class DemoSimulationEngine {
  DemoSimulationEngine({
    required this.taskController,
    required this.robotController,
  });

  final TaskController taskController;
  final RobotController robotController;

  Timer? _timer;
  String? _activeTaskId;
  int _tickCount = 0;

  RobotMapState _mapState = MockMapData.initialMapState();

  final StreamController<RobotMapState> _mapStateController =
      StreamController<RobotMapState>.broadcast();

  RobotMapState get currentMapState => _mapState;

  Stream<RobotMapState> get mapStateStream => _mapStateController.stream;

  bool get isRunning => _timer?.isActive ?? false;

  String? get activeTaskId => _activeTaskId;

  void start(String taskId) {
    final task = taskController.getTaskById(taskId);

    if (task == null) {
      return;
    }

    if (task.status != CleaningTaskStatus.running) {
      return;
    }

    _timer?.cancel();

    _activeTaskId = taskId;
    _tickCount = 0;

    final plannedPath = MockMapData.pathForArea(task.area);

    _mapState = MockMapData.initialMapState().copyWith(
      plannedPath: plannedPath,
      cleanedPath: const [],
      robotPosition: plannedPath.isNotEmpty
          ? plannedPath.first
          : MockMapData.chargingStation.position,
    );

    _notifyMapState();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
  }

  void _tick() {
    final taskId = _activeTaskId;

    if (taskId == null) {
      stop();
      return;
    }

    final task = taskController.getTaskById(taskId);

    if (task == null) {
      stop();
      return;
    }

    // 只有任务 running 且机器人真正 cleaning 时才推进模拟数据。
    // paused、emergency、offline 等状态全部冻结。
    if (task.status != CleaningTaskStatus.running ||
        robotController.currentStatus.state != RobotState.cleaning) {
      return;
    }

    _tickCount++;

    final nextProgress = (task.progress + 5).clamp(0.0, 100.0).toDouble();

    final nextCleanedArea = task.cleanedArea + 2.5;

    final nextElapsed = task.elapsed + const Duration(seconds: 1);

    taskController.updateTaskProgress(
      taskId,
      progress: nextProgress,
      cleanedArea: nextCleanedArea,
      elapsed: nextElapsed,
    );

    _advanceMap(nextProgress);

    // 每 5 秒模拟下降 1% 电量。
    if (_tickCount % 5 == 0) {
      final currentBattery = robotController.currentStatus.battery;

      if (currentBattery > 0) {
        robotController.setBattery(currentBattery - 1);
      }
    }

    if (nextProgress >= 100) {
      robotController.stopCleaning();

      taskController.completeTask(
        taskId,
        cleanedArea: nextCleanedArea,
        elapsed: nextElapsed,
      );

      stop();
    }
  }

  void _advanceMap(double progress) {
    final path = _mapState.plannedPath;

    if (path.isEmpty) {
      return;
    }

    final normalizedProgress = (progress / 100).clamp(0.0, 1.0);

    final pathIndex =
        (normalizedProgress * (path.length - 1)).round().clamp(
              0,
              path.length - 1,
            );

    final nextPosition = path[pathIndex];

    final updatedCleanedPath = List<MapPoint>.from(
      _mapState.cleanedPath,
    );

    final shouldAddPoint = updatedCleanedPath.isEmpty ||
        updatedCleanedPath.last.x != nextPosition.x ||
        updatedCleanedPath.last.y != nextPosition.y;

    if (shouldAddPoint) {
      updatedCleanedPath.add(nextPosition);
    }

    _mapState = _mapState.copyWith(
      robotPosition: nextPosition,
      cleanedPath: updatedCleanedPath,
    );

    _notifyMapState();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _activeTaskId = null;
  }

  void resetMap() {
    stop();

    _mapState = MockMapData.initialMapState();

    _notifyMapState();
  }

  void _notifyMapState() {
    if (!_mapStateController.isClosed) {
      _mapStateController.add(_mapState);
    }
  }

  void dispose() {
    stop();
    _mapStateController.close();
  }
}