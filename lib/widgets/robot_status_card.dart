import 'package:flutter/material.dart';

import '../models/robot_status.dart';

class RobotStatusCard extends StatelessWidget {
  const RobotStatusCard({super.key, required this.status});

  final RobotStatus status;

  Color _statusColor(BuildContext context) {
    switch (status.state) {
      case RobotState.cleaning:
        return Colors.green.shade700;
      case RobotState.paused:
        return Colors.orange.shade800;
      case RobotState.charging:
        return Colors.blue.shade700;
      case RobotState.emergency:
        return Colors.red.shade800;
      case RobotState.idle:
        return status.progress == 100
            ? Colors.teal.shade700
            : Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    return Card(
      key: const Key('robot-status-card'),
      elevation: 1,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: const Icon(Icons.smart_toy_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '机器人名称',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        status.robotName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: Text(
                      status.stateText,
                      key: const Key('task-state-text'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth >= 520
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _InfoItem(
                      width: itemWidth,
                      icon: status.online ? Icons.wifi : Icons.wifi_off,
                      label: '在线状态',
                      value: status.online ? '在线' : '离线',
                      valueColor: status.online
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                    _InfoItem(
                      width: itemWidth,
                      icon: Icons.battery_5_bar,
                      label: '电量',
                      value: '${status.battery}%',
                    ),
                    _InfoItem(
                      width: itemWidth,
                      icon: Icons.location_on_outlined,
                      label: '当前区域',
                      value: status.area,
                    ),
                    _InfoItem(
                      width: itemWidth,
                      icon: Icons.assignment_outlined,
                      label: '当前任务状态',
                      value: status.stateText,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  '任务进度',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text('${status.progress}%', key: const Key('progress-text')),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              key: const Key('task-progress'),
              value: status.progress / 100,
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label：', style: Theme.of(context).textTheme.bodyMedium),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
