import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../adapters/geo_location/demo_geo_location_adapter.dart';
import '../adapters/geo_location/geo_location_adapter.dart';
import '../data/campus_geo/campus_geo_map_data.dart';
import '../models/campus_geo/campus_geo_point.dart';

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
/// The caller owns [session] and injected adapters. Adapters created here are
/// disposed with the coordinator; injected adapters remain caller-owned.
class CampusDemoCoordinator extends ChangeNotifier {
  CampusDemoCoordinator({
    required this.session,
    DemoLocationAdapter? locationAdapter,
    GeoLocationAdapter? geoLocationAdapter,
    CampusVoiceCommandInterpreter? interpreter,
    this.mapper = const CampusVoiceActionMapper(),
  }) : locationAdapter = locationAdapter ?? DemoLocationAdapter(),
       geoLocationAdapter = geoLocationAdapter ?? DemoGeoLocationAdapter(),
       _ownsLocationAdapter = locationAdapter == null,
       _ownsGeoLocationAdapter = geoLocationAdapter == null,
       _interpreter =
           interpreter ??
           CampusVoiceCommandInterpreter(
             CampusZoneResolver(
               CampusMapData.zones
                   .map(
                     (zone) => CampusZoneAliasEntry(
                       id: zone.id,
                       name: zone.name,
                       aliases: {
                         ...zone.aliases,
                         ...?CampusGeoMapData.findZoneById(zone.id)?.aliases,
                       }.toList(),
                     ),
                   )
                   .toList(),
             ),
           ) {
    _robotPosition = this.locationAdapter.currentPosition;
    session.addListener(_onSessionChanged);
    _positionSubscription = this.locationAdapter.watchRobotPosition().listen(
      _onPosition,
    );
    _geoRobotPosition = _latLng(
      this.geoLocationAdapter.currentPosition ??
          CampusGeoMapData.chargingStation.position,
    );
    _geoPositionSubscription = this.geoLocationAdapter
        .watchRobotPosition()
        .listen(_onGeoPosition);
    _synchronizeLocation();
  }

  final ProductSession session;
  final DemoLocationAdapter locationAdapter;
  final GeoLocationAdapter geoLocationAdapter;
  final bool _ownsLocationAdapter, _ownsGeoLocationAdapter;
  late final StreamSubscription<CampusGeoPoint> _geoPositionSubscription;
  late LatLng _geoRobotPosition;
  List<LatLng> _geoPlannedPath = const [];
  final List<LatLng> _geoCleanedPath = [];
  bool _geoMoving = false;

  LatLng get geoRobotPosition => _geoRobotPosition;
  List<LatLng> get geoPlannedPath => _geoPlannedPath;
  List<LatLng> get geoCleanedPath => List.unmodifiable(_geoCleanedPath);

  /// Display-only completed segments; the initial point contributes no progress.
  /// Does not update task progress or status.
  double get geoProgress {
    final plannedLength = geoPlannedPath.length;
    if (plannedLength <= 1) return 0.0;
    return ((geoCleanedPath.length - 1) / (plannedLength - 1)).clamp(0.0, 1.0);
  }

  static LatLng _latLng(CampusGeoPoint p) => LatLng(p.latitude, p.longitude);
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
    if ((_locationTask?.status == CleaningTaskStatus.running ||
            _locationTask?.status == CleaningTaskStatus.paused) &&
        zoneId != selectedZoneId) {
      return false;
    }
    _selectedZone = zone;
    _plannedPath = List.unmodifiable(
      CampusMapData.routeForZone(zone.id).plannedPath,
    );
    if (_campusTaskId == null ||
        _locationTask?.status != CleaningTaskStatus.running &&
            _locationTask?.status != CleaningTaskStatus.paused) {
      _geoPlannedPath = List.unmodifiable(
        CampusGeoMapData.routeForZone(zoneId)?.plannedPath.map(_latLng) ??
            <LatLng>[],
      );
    }
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

    final geoRoute = CampusGeoMapData.routeForZone(zoneId);
    if (geoRoute == null || geoRoute.plannedPath.isEmpty) {
      return _record(
        const ControlResult(
          action: RobotAction.start,
          success: false,
          message: '该地点暂无真实地图路线',
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

    session.useExternalTaskProgress(task.id);
    _campusTaskId = task.id;
    _geoPlannedPath = List.unmodifiable(geoRoute.plannedPath.map(_latLng));
    _geoCleanedPath.clear();
    geoLocationAdapter.loadPath(geoRoute.plannedPath);
    _geoRobotPosition = _geoPlannedPath.first;
    _geoMoving = true;
    geoLocationAdapter.start();
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
    if (result.success) {
      locationAdapter.resume();
      session.simulationEngine.stop();
      _geoMoving = true;
      geoLocationAdapter.resume();
    }
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
    if (_campusTaskId != null &&
        _locationTask?.status == CleaningTaskStatus.running &&
        session.robotController.currentStatus.state == RobotState.cleaning &&
        !_geoMoving) {
      _geoMoving = true;
      geoLocationAdapter.resume();
    }
    notifyListeners();
  }

  void _synchronizeLocation() {
    final status = _locationTask?.status;
    final state = session.robotController.currentStatus.state;
    if (status != CleaningTaskStatus.running || state != RobotState.cleaning) {
      _geoMoving = false;
      geoLocationAdapter.pause();
    }
    if (status == CleaningTaskStatus.cancelled ||
        status == CleaningTaskStatus.completed ||
        status == CleaningTaskStatus.failed) {
      locationAdapter.stop();
      _geoMoving = false;
      geoLocationAdapter.stop();
    } else if (status == CleaningTaskStatus.paused ||
        state == RobotState.paused ||
        state == RobotState.emergency) {
      locationAdapter.pause();
      _geoMoving = false;
      geoLocationAdapter.pause();
    }
  }

  void _onGeoPosition(CampusGeoPoint point) {
    if (_disposed ||
        !_geoMoving ||
        _campusTaskId == null ||
        _locationTask?.status != CleaningTaskStatus.running ||
        session.robotController.currentStatus.state != RobotState.cleaning ||
        point != geoLocationAdapter.currentPosition) {
      return;
    }
    _geoRobotPosition = _latLng(point);
    if (_geoCleanedPath.isEmpty || _geoCleanedPath.last != _geoRobotPosition) {
      _geoCleanedPath.add(_geoRobotPosition);
    }
    if (_geoRobotPosition == _geoPlannedPath.last) {
      session.robotController.stop();
      session.taskController.completeTask(_campusTaskId!);
    }
    notifyListeners();
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
    unawaited(_geoPositionSubscription.cancel());
    if (_ownsGeoLocationAdapter) geoLocationAdapter.dispose();
    if (_ownsLocationAdapter) locationAdapter.dispose();
    super.dispose();
  }
}
