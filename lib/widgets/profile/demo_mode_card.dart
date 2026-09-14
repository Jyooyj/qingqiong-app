import 'package:flutter/material.dart';

class DemoModeCard extends StatelessWidget {
  const DemoModeCard({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: const Key('profile-demo-mode'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '演示模式',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    enabled ? '当前状态：已开启' : '当前状态：已关闭',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '使用演示数据展示任务、轨迹与告警',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              key: const Key('profile-demo-mode-switch'),
              activeTrackColor: theme.colorScheme.primary,
              trackColor: WidgetStateProperty.resolveWith(
                (states) => enabled ? theme.colorScheme.primary : null,
              ),
              value: enabled,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
