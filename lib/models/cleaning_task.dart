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
  final CleaningTaskStatus status;
  final double progress;
  final DateTime createdAt;
  final DateTime? plannedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double cleanedArea;
  final Duration elapsed;

  const CleaningTask({
    required this.id,
    required this.name,
    required this.area,
    required this.mode,
    required this.status,
    required this.progress,
    required this.createdAt,
    this.plannedAt,
    this.startedAt,
    this.completedAt,
    required this.cleanedArea,
    required this.elapsed,
  });

  CleaningTask copyWith({
    String? id,
    String? name,
    String? area,
    String? mode,
    CleaningTaskStatus? status,
    double? progress,
    DateTime? createdAt,
    DateTime? plannedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    double? cleanedArea,
    Duration? elapsed,
  }) {
    return CleaningTask(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      plannedAt: plannedAt ?? this.plannedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cleanedArea: cleanedArea ?? this.cleanedArea,
      elapsed: elapsed ?? this.elapsed,
    );
  }
}