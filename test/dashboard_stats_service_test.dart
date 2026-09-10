import 'package:flutter_test/flutter_test.dart';

import 'package:robot_cleaner/models/cleaning_task.dart';
import 'package:robot_cleaner/services/dashboard_stats_service.dart';

void main() {
  group('DashboardStatsService', () {
    late DashboardStatsService service;

    setUp(() {
      service = DashboardStatsService();
    });

    CleaningTask createTask({
      required String id,
      required CleaningTaskStatus status,
      required DateTime createdAt,
      double cleanedArea = 0,
      Duration elapsed = Duration.zero,
    }) {
      return CleaningTask(
        id: id,
        name: '测试任务$id',
        area: 'A区',
        mode: 'standard',
        status: status,
        progress:
            status == CleaningTaskStatus.completed ? 100 : 0,
        createdAt: createdAt,
        plannedAt: null,
        startedAt: null,
        completedAt:
            status == CleaningTaskStatus.completed
                ? createdAt
                : null,
        cleanedArea: cleanedArea,
        elapsed: elapsed,
      );
    }

    test('可以正确统计今日任务数和今日完成数', () {
      final now = DateTime(2026, 8, 23, 12);

      final tasks = [
        createTask(
          id: '001',
          status: CleaningTaskStatus.completed,
          createdAt: DateTime(2026, 8, 23, 8),
        ),
        createTask(
          id: '002',
          status: CleaningTaskStatus.running,
          createdAt: DateTime(2026, 8, 23, 9),
        ),
        createTask(
          id: '003',
          status: CleaningTaskStatus.completed,
          createdAt: DateTime(2026, 8, 22, 9),
        ),
      ];

      final stats = service.calculate(
        tasks,
        now: now,
      );

      expect(stats.todayTaskCount, 2);
      expect(stats.todayCompletedCount, 1);
    });

    test('可以正确累计清扫面积和清扫时长', () {
      final now = DateTime(2026, 8, 23, 12);

      final tasks = [
        createTask(
          id: '001',
          status: CleaningTaskStatus.completed,
          createdAt: now,
          cleanedArea: 100,
          elapsed: const Duration(minutes: 10),
        ),
        createTask(
          id: '002',
          status: CleaningTaskStatus.running,
          createdAt: now,
          cleanedArea: 50,
          elapsed: const Duration(minutes: 5),
        ),
      ];

      final stats = service.calculate(
        tasks,
        now: now,
      );

      expect(stats.totalCleanedArea, 150);

      expect(
        stats.totalCleaningDuration,
        const Duration(minutes: 15),
      );
    });

    test('可以正确统计当前运行任务数', () {
      final now = DateTime(2026, 8, 23, 12);

      final tasks = [
        createTask(
          id: '001',
          status: CleaningTaskStatus.running,
          createdAt: now,
        ),
        createTask(
          id: '002',
          status: CleaningTaskStatus.running,
          createdAt: now,
        ),
        createTask(
          id: '003',
          status: CleaningTaskStatus.paused,
          createdAt: now,
        ),
      ];

      final stats = service.calculate(
        tasks,
        now: now,
      );

      expect(stats.runningTaskCount, 2);
    });

    test('没有已结束任务时成功率为0', () {
      final now = DateTime(2026, 8, 23, 12);

      final tasks = [
        createTask(
          id: '001',
          status: CleaningTaskStatus.running,
          createdAt: now,
        ),
      ];

      final stats = service.calculate(
        tasks,
        now: now,
      );

      expect(stats.successRate, 0);
    });

    test('completed和failed任务可以正确计算成功率', () {
      final now = DateTime(2026, 8, 23, 12);

      final tasks = [
        createTask(
          id: '001',
          status: CleaningTaskStatus.completed,
          createdAt: now,
        ),
        createTask(
          id: '002',
          status: CleaningTaskStatus.completed,
          createdAt: now,
        ),
        createTask(
          id: '003',
          status: CleaningTaskStatus.failed,
          createdAt: now,
        ),
      ];

      final stats = service.calculate(
        tasks,
        now: now,
      );

      expect(
        stats.successRate,
        closeTo(2 / 3, 0.001),
      );
    });
  });
}