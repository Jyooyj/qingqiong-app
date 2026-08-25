enum WarningLevel { low, medium, high }

enum WarningHandleStatus { unhandled, acknowledged, resolved }

class WarningRecord {
  const WarningRecord({
    required this.id,
    required this.code,
    required this.title,
    required this.level,
    required this.occurredAt,
    required this.message,
    required this.recommendation,
    required this.handleStatus,
    this.taskId,
    this.resolvedAt,
  });

  final String id;
  final String code;
  final String title;
  final WarningLevel level;
  final DateTime occurredAt;
  final String message;
  final String recommendation;
  final String? taskId;
  final WarningHandleStatus handleStatus;
  final DateTime? resolvedAt;

  bool get isHandled => handleStatus != WarningHandleStatus.unhandled;

  WarningRecord copyWith({
    WarningHandleStatus? handleStatus,
    DateTime? resolvedAt,
  }) {
    return WarningRecord(
      id: id,
      code: code,
      title: title,
      level: level,
      occurredAt: occurredAt,
      message: message,
      recommendation: recommendation,
      taskId: taskId,
      handleStatus: handleStatus ?? this.handleStatus,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
