import '../../services/task_statistics_formatter.dart';
import 'package:flutter/material.dart';

class CurrentTaskCard extends StatelessWidget {
  const CurrentTaskCard({
    super.key,
    required this.title,
    required this.area,
    required this.statusText,
    required this.progress,
    required this.eta,
    this.empty = false,
    this.onTap,
    this.cleanedArea,
    this.cleanedDistance,
    this.duration,
  });

  final String title;
  final String area;
  final String statusText;
  final int progress;
  final String eta;
  final bool empty;
  final VoidCallback? onTap;
  final double? cleanedArea;
  final double? cleanedDistance;
  final String? duration;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '当前任务',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    statusText,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (empty) ...[
                const SizedBox(height: 10),
                const Text('暂无进行中的任务'),
                const SizedBox(height: 4),
                Text(
                  '选择区域或使用自然语言创建任务',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text(area),
                    const Spacer(),
                    Text('ETA: $eta'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress / 100, minHeight: 8),
                const SizedBox(height: 6),
                Text('$progress%'),
                if (cleanedArea != null &&
                    duration != null &&
                    progress >= 100) ...[
                  const SizedBox(height: 8),
                  Text(
                    '已清扫面积：${TaskStatisticsFormatter.area(cleanedArea!)} · 耗时：$duration',
                  ),
                  if ((cleanedDistance ?? 0) > 0)
                    Text('清扫距离：${cleanedDistance!.toStringAsFixed(1)} m'),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
