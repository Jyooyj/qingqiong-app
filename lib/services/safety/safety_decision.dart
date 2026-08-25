import '../warning_service.dart';

enum SafetyDirective { none, pause, stop, emergencyStop }

class SafetyDecision {
  SafetyDecision({
    required this.directive,
    required this.primaryWarningCode,
    required List<String> activeWarningCodes,
    required this.canStartNewTask,
    required this.requiresReset,
    required this.dataValid,
    required this.recommendation,
  }) : activeWarningCodes = List<String>.unmodifiable(activeWarningCodes);

  final SafetyDirective directive;
  final String? primaryWarningCode;
  final List<String> activeWarningCodes;
  final bool canStartNewTask;
  final bool requiresReset;
  final bool dataValid;
  final String? recommendation;
}

class SafetyDecisionService {
  const SafetyDecisionService();

  SafetyDecision decide(WarningResult warning) {
    final directive = warning.activeWarningCodes.contains('WARN-004')
        ? SafetyDirective.emergencyStop
        : switch (warning.safetyAction) {
            TaskSafetyAction.none => SafetyDirective.none,
            TaskSafetyAction.pause => SafetyDirective.pause,
            TaskSafetyAction.stop => SafetyDirective.stop,
          };

    return SafetyDecision(
      directive: directive,
      primaryWarningCode: warning.primaryWarningCode,
      activeWarningCodes: warning.activeWarningCodes,
      canStartNewTask: warning.canStart,
      requiresReset: warning.requireReset,
      dataValid: warning.batteryValid,
      recommendation: _recommendationFor(warning.activeWarningCodes),
    );
  }

  String? _recommendationFor(List<String> codes) {
    if (codes.contains('WARN-004')) {
      return '确认现场安全后调用 RobotController.reset() 解除急停锁存';
    }
    if (codes.contains('WARN-005')) {
      return '安全停止并检查设备故障';
    }
    if (codes.contains('WARN-002')) {
      return '禁止启动新清扫，并建议返回充电';
    }
    if (codes.contains('WARN-007')) {
      return '安全暂停，清除障碍并重新评估后再继续';
    }
    if (codes.contains('DATA-001')) {
      return '检查数据源，在数据恢复可信前保持安全权限限制';
    }
    return null;
  }
}

/// 为尚未合并的 TaskController 预留的最小接入接口。
///
/// 当前 V1 不直接依赖 core-engine 分支；未来 TaskController 只需实现此接口，
/// 即可消费相同的 [SafetyDecision]，无需把规则复制到 Widget 中。
abstract interface class TaskSafetyDecisionSink {
  void applySafetyDecision(SafetyDecision decision);
}
