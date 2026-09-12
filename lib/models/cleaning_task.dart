enum CleaningTaskStatus {
  pending,
  running,
  paused,
  completed,
  failed,
  cancelled,
}

class CleaningTask {
  final String id;
  final String name;
  final String area;
  final String mode;

  /// Stable campus target metadata. Legacy [area] remains for core compatibility.
  final String? campusZoneId;
  final String? displayArea;
  final String? displayTaskName;
  final CleaningTaskStatus status;
  final double progress;
  final DateTime createdAt;
  final DateTime? plannedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double cleanedArea;

  /// Demo route distance in metres.
  final double cleanedDistance;
  final Duration elapsed;

  const CleaningTask({
    required this.id,
    required this.name,
    required this.area,
    required this.mode,
    this.campusZoneId,
    this.displayArea,
    this.displayTaskName,
    required this.status,
    required this.progress,
    required this.createdAt,
    this.plannedAt,
    this.startedAt,
    this.completedAt,
    required this.cleanedArea,
    required this.elapsed,
    this.cleanedDistance = 0,
  });

  CleaningTask copyWith({
    String? id,
    String? name,
    String? area,
    String? mode,
    String? campusZoneId,
    String? displayArea,
    String? displayTaskName,
    CleaningTaskStatus? status,
    double? progress,
    DateTime? createdAt,
    DateTime? plannedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    double? cleanedArea,
    Duration? elapsed,
    double? cleanedDistance,
  }) {
    return CleaningTask(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      mode: mode ?? this.mode,
      campusZoneId: campusZoneId ?? this.campusZoneId,
      displayArea: displayArea ?? this.displayArea,
      displayTaskName: displayTaskName ?? this.displayTaskName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      plannedAt: plannedAt ?? this.plannedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cleanedArea: cleanedArea ?? this.cleanedArea,
      elapsed: elapsed ?? this.elapsed,
      cleanedDistance: cleanedDistance ?? this.cleanedDistance,
    );
  }
}
