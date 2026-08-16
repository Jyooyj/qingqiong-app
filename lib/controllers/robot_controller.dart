import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/mock_robot_data.dart';
import '../models/robot_status.dart';
import '../services/warning_service.dart';

enum RobotAction {
  start,
  pause,
  resume,
  stop,
  charge,
  emergencyStop,
  reset,
  selectArea,
}

class ControlResult {
  final RobotAction action;
  final bool success;
  final String message;

  const ControlResult({
    required this.action,
    required this.success,
    required this.message,
  });
}

class RobotController extends ChangeNotifier {
  RobotController({
    RobotStatus initialStatus = mockRobotStatus,
    WarningService? warningService,
    this.autoProgress = true,
    this.progressInterval = const Duration(seconds: 1),
    this.progressStep = 1,
  }) : _status = initialStatus,
       _warningService = warningService ?? WarningService();

  final WarningService _warningService;
  final bool autoProgress;
  final Duration progressInterval;
  final int progressStep;

  RobotStatus _status;
  Timer? _progressTimer;

  RobotStatus get currentStatus => _status;

  WarningResult get warningResult => _warningService.evaluate(_warningState);

  RobotWarningState get _warningState => RobotWarningState(
    online: _status.online,
    battery: _status.battery,
    batterySensorError: _status.batterySensorError,
    emergency: _status.emergency,
    deviceError: _status.deviceError,
    locationFailed: _status.locationFailed,
    pathBlocked: _status.pathBlocked,
    taskFailed: _status.taskFailed,
    customWarning: _status.customWarning,
  );

  bool get canStart =>
      _status.state == RobotState.idle && warningResult.canStart;
  bool get canPause =>
      _status.state == RobotState.cleaning && warningResult.canPause;
  bool get canResume =>
      _status.state == RobotState.paused && warningResult.canResume;
  bool get canStop =>
      (_status.state == RobotState.cleaning ||
          _status.state == RobotState.paused ||
          _status.state == RobotState.charging) &&
      warningResult.canStop;
  bool get canCharge =>
      _status.state == RobotState.idle && warningResult.canCharge;
  bool get canEmergencyStop =>
      _status.state != RobotState.emergency && warningResult.canEmergencyStop;
  bool get canReset =>
      _status.state == RobotState.emergency && warningResult.canReset;
  bool get canSelectArea =>
      _status.state == RobotState.idle && !_status.emergency && _status.online;

  ControlResult start({String? area}) {
    if (!canStart) {
      return _rejected(RobotAction.start, _startRejectionReason());
    }
    if (area != null && !_isSupportedArea(area)) {
      return _rejected(RobotAction.start, '不支持的清扫区域：$area');
    }

    _updateStatus(
      _status.copyWith(
        state: RobotState.cleaning,
        area: area,
        progress: _status.progress == 100 ? 0 : _status.progress,
        taskFailed: false,
      ),
    );
    _startProgress();
    return _accepted(RobotAction.start, '已开始清扫${area ?? _status.area}');
  }

  ControlResult pause() {
    if (!canPause) {
      return _rejected(
        RobotAction.pause,
        _permissionOrStateReason('只有清扫中可以暂停'),
      );
    }
    _stopProgress();
    _updateStatus(_status.copyWith(state: RobotState.paused));
    return _accepted(RobotAction.pause, '清扫任务已暂停');
  }

  ControlResult resume() {
    if (!canResume) {
      return _rejected(
        RobotAction.resume,
        _permissionOrStateReason('只有已暂停任务可以继续'),
      );
    }
    _updateStatus(_status.copyWith(state: RobotState.cleaning));
    _startProgress();
    return _accepted(RobotAction.resume, '已继续清扫任务');
  }

  ControlResult stop() {
    if (!canStop) {
      return _rejected(
        RobotAction.stop,
        _status.emergency
            ? '紧急停止已锁定，请先复位'
            : _permissionOrStateReason('当前状态没有可停止的任务'),
      );
    }
    _stopProgress();
    _updateStatus(_status.copyWith(state: RobotState.idle, progress: 0));
    return _accepted(RobotAction.stop, '任务已停止，进度已重置');
  }

  ControlResult charge() {
    if (!canCharge) {
      return _rejected(
        RobotAction.charge,
        _status.emergency
            ? '紧急停止已锁定，请先复位'
            : _permissionOrStateReason('只有待机状态可以返回充电'),
      );
    }
    _stopProgress();
    _updateStatus(_status.copyWith(state: RobotState.charging, progress: 0));
    return _accepted(RobotAction.charge, '机器人正在返回充电');
  }

  ControlResult emergencyStop() {
    if (!canEmergencyStop) {
      return _rejected(
        RobotAction.emergencyStop,
        _status.emergency
            ? '紧急停止已处于锁定状态'
            : _permissionOrStateReason('当前无法执行紧急停止'),
      );
    }
    _stopProgress();
    _updateStatus(_status.copyWith(state: RobotState.emergency));
    return _accepted(RobotAction.emergencyStop, '紧急停止已触发并锁定');
  }

  ControlResult reset() {
    if (!canReset) {
      return _rejected(
        RobotAction.reset,
        _status.state != RobotState.emergency
            ? '当前不需要复位'
            : _permissionOrStateReason('当前安全条件不允许复位'),
      );
    }
    _stopProgress();
    _updateStatus(_status.copyWith(state: RobotState.idle, progress: 0));
    return _accepted(RobotAction.reset, '紧急停止已复位，机器人恢复待机');
  }

  ControlResult selectArea(String area) {
    if (!_isSupportedArea(area)) {
      return _rejected(RobotAction.selectArea, '不支持的清扫区域：$area');
    }
    if (!canSelectArea) {
      return _rejected(
        RobotAction.selectArea,
        _status.emergency ? '紧急停止已锁定，请先复位' : '只能在在线待机状态选择区域',
      );
    }
    if (_status.area == area) {
      return _accepted(RobotAction.selectArea, '当前已选择$area');
    }
    _updateStatus(_status.copyWith(area: area));
    return _accepted(RobotAction.selectArea, '已选择$area');
  }

  void advanceProgress([int? amount]) {
    if (_status.state != RobotState.cleaning) {
      return;
    }
    final nextProgress = (_status.progress + (amount ?? progressStep)).clamp(
      0,
      100,
    );
    if (nextProgress >= 100) {
      _stopProgress();
      _updateStatus(_status.copyWith(state: RobotState.idle, progress: 100));
      return;
    }
    _updateStatus(_status.copyWith(progress: nextProgress));
  }

  void setBattery(int battery) {
    _updateStatus(_status.copyWith(battery: battery));
    _enforceWarningSafety();
  }

  void setOnline(bool online) {
    _updateStatus(_status.copyWith(online: online));
    _enforceWarningSafety();
  }

  void setBatterySensorError(bool value) {
    _updateStatus(_status.copyWith(batterySensorError: value));
    _enforceWarningSafety();
  }

  void setDeviceError(bool value) {
    _updateStatus(_status.copyWith(deviceError: value));
    _enforceWarningSafety();
  }

  void setLocationFailed(bool value) {
    _updateStatus(_status.copyWith(locationFailed: value));
    _enforceWarningSafety();
  }

  void setPathBlocked(bool value) {
    _updateStatus(_status.copyWith(pathBlocked: value));
    _enforceWarningSafety();
  }

  void setTaskFailed(bool value) {
    _updateStatus(_status.copyWith(taskFailed: value));
  }

  void clearDemoFaults() {
    _updateStatus(
      _status.copyWith(
        online: true,
        battery: 82,
        batterySensorError: false,
        deviceError: false,
        locationFailed: false,
        pathBlocked: false,
        taskFailed: false,
        clearCustomWarning: true,
      ),
    );
  }

  // 兼容旧状态引擎调用方。
  ControlResult startCleaning() => start();
  ControlResult pauseCleaning() => pause();
  ControlResult resumeCleaning() => resume();
  ControlResult stopCleaning() => stop();
  ControlResult returnToCharge() => charge();
  ControlResult resetEmergency() => reset();

  void _enforceWarningSafety() {
    final action = warningResult.safetyAction;
    if (action == TaskSafetyAction.stop &&
        (_status.state == RobotState.cleaning ||
            _status.state == RobotState.paused)) {
      _stopProgress();
      _updateStatus(_status.copyWith(state: RobotState.idle, progress: 0));
    } else if (action == TaskSafetyAction.pause &&
        _status.state == RobotState.cleaning) {
      _stopProgress();
      _updateStatus(_status.copyWith(state: RobotState.paused));
    }
  }

  String _startRejectionReason() {
    if (_status.emergency) {
      return '紧急停止已锁定，请先复位';
    }
    return _permissionOrStateReason('只有待机状态可以开始清扫');
  }

  String _permissionOrStateReason(String stateReason) {
    final warning = warningResult;
    if (warning.hasWarning && warning.message != null) {
      return warning.message!;
    }
    return stateReason;
  }

  bool _isSupportedArea(String area) =>
      const <String>{'A区', 'B区', 'C区'}.contains(area);

  ControlResult _accepted(RobotAction action, String message) =>
      ControlResult(action: action, success: true, message: message);

  ControlResult _rejected(RobotAction action, String message) =>
      ControlResult(action: action, success: false, message: message);

  void _startProgress() {
    _stopProgress();
    if (!autoProgress) {
      return;
    }
    _progressTimer = Timer.periodic(progressInterval, (_) => advanceProgress());
  }

  void _stopProgress() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void _updateStatus(RobotStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopProgress();
    super.dispose();
  }
}
