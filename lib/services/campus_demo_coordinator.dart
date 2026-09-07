import 'dart:async';

import 'package:flutter/foundation.dart';

import '../adapters/location/demo_location_adapter.dart';
import '../controllers/robot_controller.dart';
import '../data/campus/campus_map_data.dart';
import '../models/campus/campus_map_objects.dart';
import '../models/campus/campus_point.dart';
import '../models/campus/campus_zone.dart';
import '../models/cleaning_task.dart';
import '../models/robot_status.dart';
import 'campus_voice_action_mapper.dart';
import 'campus_voice_command_interpreter.dart';
import 'campus_zone_resolver.dart';
import 'product_session.dart';

/// Connects campus commands and map state to the existing product session.
/// The caller owns [session] and [locationAdapter] and must dispose them after
/// this coordinator. Disposing this coordinator only removes its listeners.
class CampusDemoCoordinator extends ChangeNotifier {
  CampusDemoCoordinator({
    required this.session,
    required this.locationAdapter,
    CampusVoiceCommandInterpreter? interpreter,
    this.mapper = const CampusVoiceActionMapper(),
  }) : _interpreter =
           interpreter ??
           CampusVoiceCommandInterpreter(
             CampusZoneResolver(
               CampusMapData.zones
                   .map(
                     (zone) => CampusZoneAliasEntry(
                       id: zone.id,
                       name: zone.name,
                       aliases: zone.aliases,
                     ),
                   )
                   .toList(),
             ),
           ) {
    _robotPosition = locationAdapter.currentPosition;
    session.addListener(_onSessionChanged);
    _positionSubscription = locationAdapter.watchRobotPosition().listen(
      _onPosition,
    );
    _synchronizeLocation();
  }

  final ProductSession session;
  final DemoLocationAdapter locationAdapter;
  final CampusVoiceCommandInterpreter _interpreter;
  final CampusVoiceActionMapper mapper;
  late final StreamSubscription<CampusPoint> _positionSubscription;

  CampusZone? _selectedZone;
  CampusPoint? _robotPosition;
  List<CampusPoint> _plannedPath = const [];
  final List<CampusPoint> _cleanedPath = [];
  String? _campusTaskId;
  String? _lastMessage;
  bool _disposed = false;

  String? get selectedZoneId => _selectedZone?.id;
  CampusZone? get selectedZone => _selectedZone;
  String? get selectedZoneName => _selectedZone?.name;
  CampusPoint? get robotPosition => _robotPosition;
  List<CampusPoint> get plannedPath => _plannedPath;
  List<CampusPoint> get cleanedPath => List.unmodifiable(_cleanedPath);
  List<CampusObstacle> get visibleObstacles =>
      session.robotController.currentStatus.pathBlocked
      ? CampusMapData.obstacles
      : const [];
  CampusChargingStation get chargingStation => CampusMapData.chargingStation;
  CleaningTask? get currentTask => session.currentTask;
  String? get lastMessage => _lastMessage;
  bool get canPause => session.canPauseTask;
  bool get canResume => session.canResumeTask;
  bool get canEmergencyStop => session.robotController.canEmergencyStop;
  bool get canReset => session.robotController.canReset;

  bool selectZone(String zoneId) {
    final zone = CampusMapData.findZoneById(zoneId);
    if (zone == null) return false;
    _selectedZone = zone;
    _plannedPath = List.unmodifiable(
      CampusMapData.routeForZone(zone.id).plannedPath,
    );
    notifyListeners();
    return true;
  }

  ControlResult startCampusCleaning(String zoneId) {
    final zone = CampusMapData.findZoneById(zoneId);
    if (zone == null) {
      return _record(
        const ControlResult(
          action: RobotAction.start,
          success: false,
          message: '未找到校园地点',
        ),
      );
    }
    if (!session.canStartTask) {
      return _record(
        const ControlResult(
          action: RobotAction.start,
          success: false,
          message: '当前状态无法启动校园清扫任务',
        ),
      );
    }

    final route = CampusMapData.routeForZone(zone.id);
    final task = session.createTask(
      name: '${zone.name}清扫任务',
      // Legacy control-chain compatibility only; campus labels use zone.name.
      area: 'A区',
      mode: '校园标准清扫',
    );
    if (!session.startTask(task.id)) {
      return _record(
        ControlResult(
          action: RobotAction.start,
          success: false,
          message: '${zone.name}清扫任务启动失败',
        ),
      );
    }

    _campusTaskId = task.id;
    _selectedZone = zone;
    _plannedPath = List.unmodifiable(route.plannedPath);
    _cleanedPath.clear();
    locationAdapter.loadPath(route.plannedPath);
    _robotPosition = locationAdapter.currentPosition;
    locationAdapter.start();
    _synchronizeLocation();
    return _record(
      ControlResult(
        action: RobotAction.start,
        success: true,
        message: '已开始${zone.name}清扫任务',
      ),
    );
  }

  ControlResult handleVoiceText(String text) {
    final action = mapper.map(_interpreter.interpret(text));
    if (!action.executable || action.type == CampusVoiceActionType.none) {
      // Rejected speech must leave even selection and feedback state untouched.
      return ControlResult(
        action: RobotAction.start,
        success: false,
        message: _campusMessage(action.message),
      );
    }
    switch (action.type) {
      case CampusVoiceActionType.startCleaning:
        final zoneId = action.zoneId;
        if (zoneId == null) {
          return _record(
            const ControlResult(
              action: RobotAction.start,
              success: false,
              message: '请指定校园清扫地点',
            ),
          );
        }
        return startCampusCleaning(zoneId);
      case CampusVoiceActionType.pause:
        return pause();
      case CampusVoiceActionType.resume:
        return resume();
      case CampusVoiceActionType.stop:
        return stop();
      case CampusVoiceActionType.charge:
        return _record(session.returnToCharge());
      case CampusVoiceActionType.emergencyStop:
        return emergencyStop();
      case CampusVoiceActionType.reset:
        return reset();
      case CampusVoiceActionType.none:
        throw StateError('Non-executable action was already handled');
    }
  }

  ControlResult pause() {
    final result = session.pauseCurrentTask();
    if (result.success) locationAdapter.pause();
    return _record(result);
  }

  ControlResult resume() {
    final result = session.resumeCurrentTask();
    if (result.success) locationAdapter.resume();
    return _record(result);
  }

  ControlResult stop() {
    final result = session.stopCurrentTask();
    if (result.success) locationAdapter.stop();
    return _record(result);
  }

  ControlResult emergencyStop() {
    final result = session.emergencyStop();
    if (result.success) locationAdapter.pause();
    return _record(result);
  }

  ControlResult reset() {
    final result = session.resetEmergency();
    if (result.success) locationAdapter.pause();
    return _record(result);
  }

  void setDemoPathBlocked(bool value) {
    session.robotController.setPathBlocked(value);
  }

  CleaningTask? get _locationTask => _campusTaskId == null
      ? currentTask
      : session.taskController.getTaskById(_campusTaskId!);

  void _onSessionChanged() {
    if (_disposed) return;
    _synchronizeLocation();
    notifyListeners();
  }

  void _synchronizeLocation() {
    final status = _locationTask?.status;
    final state = session.robotController.currentStatus.state;
    if (status == CleaningTaskStatus.cancelled ||
        status == CleaningTaskStatus.completed ||
        status == CleaningTaskStatus.failed) {
      locationAdapter.stop();
    } else if (status == CleaningTaskStatus.paused ||
        state == RobotState.paused ||
        state == RobotState.emergency) {
      locationAdapter.pause();
    }
  }

  void _onPosition(CampusPoint point) {
    // Broadcast events queued before a pause/stop must not extend the trail.
    if (_disposed ||
        _locationTask?.status != CleaningTaskStatus.running ||
        session.robotController.currentStatus.state != RobotState.cleaning ||
        locationAdapter.isPaused) {
      return;
    }
    _robotPosition = point;
    if (_cleanedPath.isEmpty || _cleanedPath.last != point) {
      _cleanedPath.add(point);
    }
    notifyListeners();
  }

  String _campusMessage(String message) =>
      message.replaceAll('A区', selectedZoneName ?? '校园区域');

  ControlResult _record(ControlResult result) {
    final feedback = ControlResult(
      action: result.action,
      success: result.success,
      message: _campusMessage(result.message),
    );
    _lastMessage = feedback.message;
    notifyListeners();
    return feedback;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    session.removeListener(_onSessionChanged);
    unawaited(_positionSubscription.cancel());
    super.dispose();
  }
}
