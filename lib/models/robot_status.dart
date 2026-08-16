enum RobotState { idle, cleaning, paused, charging, emergency }

class RobotStatus {
  final String robotId;
  final String robotName;
  final bool online;
  final int battery;
  final RobotState state;
  final String area;
  final int progress;
  final bool batterySensorError;
  final bool deviceError;
  final bool locationFailed;
  final bool pathBlocked;
  final bool taskFailed;
  final String? customWarning;

  const RobotStatus({
    required this.robotId,
    required this.robotName,
    required this.online,
    required this.battery,
    required this.state,
    required this.area,
    required this.progress,
    this.batterySensorError = false,
    this.deviceError = false,
    this.locationFailed = false,
    this.pathBlocked = false,
    this.taskFailed = false,
    this.customWarning,
  });

  RobotStatus copyWith({
    String? robotId,
    String? robotName,
    bool? online,
    int? battery,
    RobotState? state,
    String? area,
    int? progress,
    bool? batterySensorError,
    bool? deviceError,
    bool? locationFailed,
    bool? pathBlocked,
    bool? taskFailed,
    String? customWarning,
    bool clearCustomWarning = false,
  }) {
    return RobotStatus(
      robotId: robotId ?? this.robotId,
      robotName: robotName ?? this.robotName,
      online: online ?? this.online,
      battery: battery ?? this.battery,
      state: state ?? this.state,
      area: area ?? this.area,
      progress: progress ?? this.progress,
      batterySensorError: batterySensorError ?? this.batterySensorError,
      deviceError: deviceError ?? this.deviceError,
      locationFailed: locationFailed ?? this.locationFailed,
      pathBlocked: pathBlocked ?? this.pathBlocked,
      taskFailed: taskFailed ?? this.taskFailed,
      customWarning: clearCustomWarning
          ? null
          : customWarning ?? this.customWarning,
    );
  }

  bool get emergency => state == RobotState.emergency;

  String get stateText {
    switch (state) {
      case RobotState.idle:
        return progress == 100 ? '任务完成' : '待机';
      case RobotState.cleaning:
        return '清扫中';
      case RobotState.paused:
        return '已暂停';
      case RobotState.charging:
        return '充电中';
      case RobotState.emergency:
        return '紧急停止';
    }
  }
}
