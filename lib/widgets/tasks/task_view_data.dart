class TaskViewData {
  final String id;
  final String name;
  final String area;
  final String status; // e.g., pending, running, paused, completed, failed
  final int progress; // 0-100
  final String timeText; // planned or start time for display
  final double cleanedArea;
  final String durationText;
  final String? startTimeText;
  final String mode; // '标准','深度','快速' for UI display

  TaskViewData({
    required this.id,
    required this.name,
    required this.area,
    required this.status,
    required this.progress,
    required this.timeText,
    this.cleanedArea = 0.0,
    this.durationText = '00:00:00',
    this.startTimeText,
    this.mode = '标准',
  });
}
