import '../../services/task_statistics_formatter.dart';
import 'package:flutter/material.dart';
import 'task_view_data.dart';

class TaskDetailView extends StatelessWidget {
  const TaskDetailView({
    super.key,
    required this.task,
    this.onExecute,
    this.onPause,
    this.onResume,
    this.onStop,
  });

  final TaskViewData task;
  final void Function(TaskViewData task)? onExecute;
  final void Function(TaskViewData task)? onPause;
  final void Function(TaskViewData task)? onResume;
  final void Function(TaskViewData task)? onStop;

  @override
  Widget build(BuildContext context) {
    final isRunning = task.status == 'running';
    final isPaused = task.status == 'paused';
    final isPending = task.status == 'pending';
    final isCompleted = task.status == 'completed';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('区域: ${task.presentationArea}'),
            const SizedBox(height: 4),
            Text('状态: ${task.statusText}'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (task.progress / 100).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 4),
            Text('进度: ${task.progress}%'),
            const SizedBox(height: 8),
            Text('已清扫面积: ${TaskStatisticsFormatter.area(task.cleanedArea)}'),
            const SizedBox(height: 4),
            Text('耗时: ${task.durationText}'),
            if (task.cleanedDistance > 0)
              Text('清扫距离: ${task.cleanedDistance.toStringAsFixed(1)} m'),
            const SizedBox(height: 4),
            Text('开始时间: ${task.startTimeText ?? '-'}'),
            if (task.endTimeText != null) ...[
              const SizedBox(height: 4),
              Text('结束时间: ${task.endTimeText}'),
            ],
            const SizedBox(height: 12),
            if (isPending) ...[
              FilledButton(
                key: const Key('detail-start'),
                onPressed: onExecute == null ? null : () => onExecute!(task),
                child: const Text('开始任务'),
              ),
            ] else if (isRunning) ...[
              Row(
                children: [
                  FilledButton(
                    key: const Key('detail-pause'),
                    onPressed: onPause == null ? null : () => onPause!(task),
                    child: const Text('暂停'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: const Key('detail-stop'),
                    onPressed: onStop == null ? null : () => onStop!(task),
                    child: const Text('停止'),
                  ),
                ],
              ),
            ] else if (isPaused) ...[
              Row(
                children: [
                  FilledButton(
                    key: const Key('detail-resume'),
                    onPressed: onResume == null ? null : () => onResume!(task),
                    child: const Text('继续'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: const Key('detail-stop'),
                    onPressed: onStop == null ? null : () => onStop!(task),
                    child: const Text('停止'),
                  ),
                ],
              ),
            ] else if (isCompleted) ...[
              const Text('任务已完成'),
            ],
            if ((isRunning || isPaused) &&
                onPause == null &&
                onResume == null &&
                onStop == null) ...[
              const SizedBox(height: 8),
              const Text('等待TaskController接入', key: Key('detail-waiting')),
            ],
          ],
        ),
      ),
    );
  }
}
