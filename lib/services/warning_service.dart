// 清穹 App 的纯 Dart 故障提示判断服务。
//
// 本服务不依赖 Flutter、网络、插件或 RobotController。它只读取状态并
// 返回判断结果，不直接修改机器人状态，也不控制 UI。

enum TaskSafetyAction { none, pause, stop }

class RobotWarningState {
  final bool online;
  final int battery;
  final bool batterySensorError;
  final bool emergency;
  final bool deviceError;
  final bool locationFailed;
  final bool pathBlocked;
  final bool taskFailed;
  final String? customWarning;

  const RobotWarningState({
    this.online = true,
    this.battery = 100,
    this.batterySensorError = false,
    this.emergency = false,
    this.deviceError = false,
    this.locationFailed = false,
    this.pathBlocked = false,
    this.taskFailed = false,
    this.customWarning,
  });

  @override
  String toString() {
    return 'RobotWarningState('
        'online: $online, '
        'battery: $battery, '
        'batterySensorError: $batterySensorError, '
        'emergency: $emergency, '
        'deviceError: $deviceError, '
        'locationFailed: $locationFailed, '
        'pathBlocked: $pathBlocked, '
        'taskFailed: $taskFailed, '
        'customWarning: $customWarning'
        ')';
  }
}

class WarningResult {
  final String? primaryWarningCode;
  final List<String> activeWarningCodes;
  final String? message;
  final String? severity;
  final bool hasWarning;
  final bool batteryValid;
  final TaskSafetyAction safetyAction;
  final bool canStart;
  final bool canPause;
  final bool canResume;
  final bool canStop;
  final bool canCharge;
  final bool canEmergencyStop;
  final bool canReset;
  final bool requireReset;

  WarningResult({
    required this.primaryWarningCode,
    required List<String> activeWarningCodes,
    required this.message,
    required this.severity,
    required this.hasWarning,
    required this.batteryValid,
    required this.safetyAction,
    required this.canStart,
    required this.canPause,
    required this.canResume,
    required this.canStop,
    required this.canCharge,
    required this.canEmergencyStop,
    required this.canReset,
    required this.requireReset,
  }) : activeWarningCodes = List<String>.unmodifiable(activeWarningCodes);

  /// 兼容旧调用方；新代码应使用 primaryWarningCode。
  String? get warningCode => primaryWarningCode;

  /// 兼容旧调用方；新代码应使用 canStart。
  bool get allowStart => canStart;

  /// 兼容旧调用方。该字段无法表达细分权限，新代码不得据此控制按钮。
  bool get allowControl =>
      canPause && canResume && canStop && canCharge && canEmergencyStop;

  /// 兼容旧调用方；最终动作必须以 safetyAction 为准。
  bool get shouldPauseTask => safetyAction == TaskSafetyAction.pause;

  @override
  String toString() {
    return 'WarningResult('
        'primaryWarningCode: $primaryWarningCode, '
        'activeWarningCodes: $activeWarningCodes, '
        'message: $message, '
        'severity: $severity, '
        'hasWarning: $hasWarning, '
        'batteryValid: $batteryValid, '
        'safetyAction: $safetyAction, '
        'canStart: $canStart, '
        'canPause: $canPause, '
        'canResume: $canResume, '
        'canStop: $canStop, '
        'canCharge: $canCharge, '
        'canEmergencyStop: $canEmergencyStop, '
        'canReset: $canReset, '
        'requireReset: $requireReset'
        ')';
  }
}

typedef _WarningPredicate =
    bool Function(
      RobotWarningState state,
      bool batteryInRange,
      bool batteryValid,
    );

class WarningService {
  /// 此列表同时定义标准故障匹配和主提示优先级。
  static final List<_WarningRule> _orderedRules = <_WarningRule>[
    _WarningRule(
      warningCode: 'WARN-004',
      message: '紧急停止已触发，请确认环境安全后复位',
      severity: 'high',
      matches: (state, batteryInRange, batteryValid) => state.emergency,
    ),
    _WarningRule(
      warningCode: 'WARN-003',
      message: '机器人离线，请检查设备连接',
      severity: 'high',
      matches: (state, batteryInRange, batteryValid) => !state.online,
    ),
    _WarningRule(
      warningCode: 'WARN-005',
      message: '设备故障，请检查机器人',
      severity: 'high',
      matches: (state, batteryInRange, batteryValid) => state.deviceError,
    ),
    _WarningRule(
      warningCode: 'DATA-001',
      message: '电量数据异常，请检查传感器',
      severity: 'high',
      matches: (state, batteryInRange, batteryValid) => !batteryValid,
    ),
    _WarningRule(
      warningCode: 'WARN-002',
      message: '电量过低，禁止开始任务',
      severity: 'high',
      matches: (state, batteryInRange, batteryValid) =>
          batteryInRange && state.battery < 10,
    ),
    _WarningRule(
      warningCode: 'WARN-006',
      message: '定位失败，请检查定位模块',
      severity: 'medium',
      matches: (state, batteryInRange, batteryValid) => state.locationFailed,
    ),
    _WarningRule(
      warningCode: 'WARN-007',
      message: '前方路径受阻，请重新规划任务',
      severity: 'medium',
      matches: (state, batteryInRange, batteryValid) => state.pathBlocked,
    ),
    _WarningRule(
      warningCode: 'WARN-001',
      message: '电量不足，建议返回充电',
      severity: 'medium',
      matches: (state, batteryInRange, batteryValid) =>
          batteryInRange && state.battery >= 10 && state.battery < 20,
    ),
    _WarningRule(
      warningCode: 'WARN-008',
      message: '任务执行失败，请重新尝试',
      severity: 'low',
      matches: (state, batteryInRange, batteryValid) => state.taskFailed,
    ),
  ];

  static final List<String> warningPriority = List<String>.unmodifiable(
    _orderedRules.map((rule) => rule.warningCode),
  );

  /// 包含无标准编号 customWarning 的完整展示优先级。
  static final List<String> completeWarningPriority = List<String>.unmodifiable(
    <String>[...warningPriority, 'customWarning'],
  );

  WarningResult evaluate(RobotWarningState state) {
    final batteryInRange = state.battery >= 0 && state.battery <= 100;
    final batteryValid = batteryInRange && !state.batterySensorError;

    final activeRules = _orderedRules
        .where((rule) => rule.matches(state, batteryInRange, batteryValid))
        .toList(growable: false);
    final activeWarningCodes = activeRules
        .map((rule) => rule.warningCode)
        .toList(growable: false);

    final safetyAction = _resolveSafetyAction(state);
    final permissions = _resolvePermissions(state, batteryValid);

    if (activeRules.isNotEmpty) {
      final primaryRule = activeRules.first;
      return WarningResult(
        primaryWarningCode: primaryRule.warningCode,
        activeWarningCodes: activeWarningCodes,
        message: primaryRule.message,
        severity: primaryRule.severity,
        hasWarning: true,
        batteryValid: batteryValid,
        safetyAction: safetyAction,
        canStart: permissions.canStart,
        canPause: permissions.canPause,
        canResume: permissions.canResume,
        canStop: permissions.canStop,
        canCharge: permissions.canCharge,
        canEmergencyStop: permissions.canEmergencyStop,
        canReset: permissions.canReset,
        requireReset: state.emergency,
      );
    }

    final customMessage = state.customWarning?.trim();
    if (customMessage != null && customMessage.isNotEmpty) {
      return WarningResult(
        primaryWarningCode: null,
        activeWarningCodes: activeWarningCodes,
        message: customMessage,
        severity: 'low',
        hasWarning: true,
        batteryValid: batteryValid,
        safetyAction: safetyAction,
        canStart: permissions.canStart,
        canPause: permissions.canPause,
        canResume: permissions.canResume,
        canStop: permissions.canStop,
        canCharge: permissions.canCharge,
        canEmergencyStop: permissions.canEmergencyStop,
        canReset: permissions.canReset,
        requireReset: state.emergency,
      );
    }

    return WarningResult(
      primaryWarningCode: null,
      activeWarningCodes: activeWarningCodes,
      message: null,
      severity: null,
      hasWarning: false,
      batteryValid: batteryValid,
      safetyAction: safetyAction,
      canStart: permissions.canStart,
      canPause: permissions.canPause,
      canResume: permissions.canResume,
      canStop: permissions.canStop,
      canCharge: permissions.canCharge,
      canEmergencyStop: permissions.canEmergencyStop,
      canReset: permissions.canReset,
      requireReset: state.emergency,
    );
  }

  TaskSafetyAction _resolveSafetyAction(RobotWarningState state) {
    if (state.emergency || state.deviceError || state.locationFailed) {
      return TaskSafetyAction.stop;
    }
    if (state.pathBlocked) {
      return TaskSafetyAction.pause;
    }
    return TaskSafetyAction.none;
  }

  _ControlPermissions _resolvePermissions(
    RobotWarningState state,
    bool batteryValid,
  ) {
    final hasSevereLowBattery = batteryValid && state.battery < 10;

    return _ControlPermissions(
      canStart:
          state.online &&
          !state.emergency &&
          !state.deviceError &&
          batteryValid &&
          !hasSevereLowBattery &&
          !state.locationFailed &&
          !state.pathBlocked,
      canPause:
          state.online &&
          !state.emergency &&
          !state.deviceError &&
          !state.locationFailed,
      canResume:
          state.online &&
          !state.emergency &&
          !state.deviceError &&
          batteryValid &&
          !state.locationFailed &&
          !state.pathBlocked,
      canStop: state.online && !state.emergency,
      canCharge: state.online && !state.emergency && !state.deviceError,
      canEmergencyStop: state.online,
      canReset: state.online && state.emergency,
    );
  }
}

class _WarningRule {
  final String warningCode;
  final String message;
  final String severity;
  final _WarningPredicate matches;

  const _WarningRule({
    required this.warningCode,
    required this.message,
    required this.severity,
    required this.matches,
  });
}

class _ControlPermissions {
  final bool canStart;
  final bool canPause;
  final bool canResume;
  final bool canStop;
  final bool canCharge;
  final bool canEmergencyStop;
  final bool canReset;

  const _ControlPermissions({
    required this.canStart,
    required this.canPause,
    required this.canResume,
    required this.canStop,
    required this.canCharge,
    required this.canEmergencyStop,
    required this.canReset,
  });
}
