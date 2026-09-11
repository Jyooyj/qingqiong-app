import 'package:flutter/material.dart';
import 'task_view_data.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onTap});

  final TaskViewData task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('task-card-${task.id}'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(task.area, key: Key('task-area-${task.id}')),
                        const SizedBox(width: 8),
                        Text(
                          taskStatusLabel(task.status),
                          key: Key('task-status-${task.id}'),
                        ),
                        Text('模式：${task.mode}'),
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
