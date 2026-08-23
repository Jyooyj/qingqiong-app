import '../models/cleaning_task.dart';
import '../models/dashboard_stats.dart';

class DashboardStatsService {
  DashboardStats calculate(
    List<CleaningTask> tasks, {
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final todayTasks = tasks.where(
      (task) =>
          task.createdAt.year == currentTime.year &&
          task.createdAt.month == currentTime.month &&
          task.createdAt.day == currentTime.day,
    );

    final todayTaskList = todayTasks.toList();

    final completedTasks = todayTaskList
        .where(
          (task) => task.status == CleaningTaskStatus.completed,
        )
        .toList();

    final runningTasks = tasks
        .where(
          (task) => task.status == CleaningTaskStatus.running,
        )
        .length;

    double totalCleanedArea = 0;
    Duration totalCleaningDuration = Duration.zero;

    for (final task in tasks) {
      totalCleanedArea += task.cleanedArea;
      totalCleaningDuration += task.elapsed;
    }

    final finishedTasks = tasks.where(
      (task) =>
          task.status == CleaningTaskStatus.completed ||
          task.status == CleaningTaskStatus.failed,
    );

    final finishedTaskList = finishedTasks.toList();

    final successRate = finishedTaskList.isEmpty
        ? 0.0
        : completedTasks.length / finishedTaskList.length;

    return DashboardStats(
      todayTaskCount: todayTaskList.length,
      todayCompletedCount: completedTasks.length,
      totalCleanedArea: totalCleanedArea,
      totalCleaningDuration: totalCleaningDuration,
      successRate: successRate,
      runningTaskCount: runningTasks,
    );
  }
}