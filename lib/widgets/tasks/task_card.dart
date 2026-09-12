import '../../services/task_statistics_formatter.dart';
import 'package:flutter/material.dart';
import 'task_view_data.dart';
import '../../theme/app_design.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onTap});

  final TaskViewData task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (task.status) {
      'completed' => AppDesign.success,
      'running' => AppDesign.primary,
      'paused' => AppDesign.warning,
      'failed' || 'cancelled' => AppDesign.danger,
      _ => AppDesign.textSecondary,
    };
    return Card(
      key: Key('task-card-${task.id}'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          task.presentationArea,
                          key: Key('task-area-${task.id}'),
                        ),
                        const SizedBox(width: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            child: Text(
                              task.statusText,
                              key: Key('task-status-${task.id}'),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(task.timeText, key: Key('task-time-${task.id}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (task.progress / 100).clamp(0.0, 1.0),
                      key: Key('task-progress-${task.id}'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${task.progress}%',
                      key: Key('task-progress-text-${task.id}'),
                    ),
                    if (task.status == 'completed' &&
                        task.cleanedDistance > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '已清扫面积：${TaskStatisticsFormatter.area(task.cleanedArea)}',
                      ),
                      Text('清扫距离：${task.cleanedDistance.toStringAsFixed(1)} m'),
                      Text('耗时：${task.durationText}'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
