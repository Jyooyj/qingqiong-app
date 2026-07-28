enum RobotState {
  idle,
  cleaning,
  paused,
  charging,
  emergency,
  offline,
  error,
}


class RobotStatus {
  final String robotId;
  final String robotName;
  final bool online;
  final int battery;
  final RobotState state;
  final String area;
  final int progress;
  final String? warning;


  const RobotStatus({
    required this.robotId,
    required this.robotName,
    required this.online,
    required this.battery,
    required this.state,
    required this.area,
    required this.progress,
    this.warning,
  });


  RobotStatus copyWith({
    String? robotId,
    String? robotName,
    bool? online,
    int? battery,
    RobotState? state,
    String? area,
    int? progress,
    String? warning,
  }) {
    return RobotStatus(
      robotId: robotId ?? this.robotId,
      robotName: robotName ?? this.robotName,
      online: online ?? this.online,
      battery: battery ?? this.battery,
      state: state ?? this.state,
      area: area ?? this.area,
      progress: progress ?? this.progress,
      warning: warning ?? this.warning,
    );
  }


  String get stateText {

    switch (state) {

      case RobotState.idle:
        return "待机";

      case RobotState.cleaning:
        return "清扫中";

      case RobotState.paused:
        return "已暂停";

      case RobotState.charging:
        return "充电中";

      case RobotState.emergency:
        return "紧急停止";

      case RobotState.offline:
        return "离线";

      case RobotState.error:
        return "故障";
    }
  }
}