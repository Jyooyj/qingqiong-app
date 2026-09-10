class DashboardStats {
  final int todayTaskCount;
  final int todayCompletedCount;
  final double totalCleanedArea;
  final Duration totalCleaningDuration;
  final double successRate;
  final int runningTaskCount;

  const DashboardStats({
    required this.todayTaskCount,
    required this.todayCompletedCount,
    required this.totalCleanedArea,
    required this.totalCleaningDuration,
    required this.successRate,
    required this.runningTaskCount,
  });
}