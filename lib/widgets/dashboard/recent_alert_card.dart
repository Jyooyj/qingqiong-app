import 'package:flutter/material.dart';
import '../../services/warning_service.dart';
import '../../services/warning/warning_record.dart';

class RecentAlertCard extends StatelessWidget {
  const RecentAlertCard({
    super.key,
    required this.warning,
    this.record,
    this.onTap,
    required this.occurredAtText,
  });
  final WarningResult warning;
  final WarningRecord? record;
  final VoidCallback? onTap;
  final String occurredAtText;

  @override
  Widget build(BuildContext context) {
    final entry = record;
    final active = entry == null
        ? warning.hasWarning
        : warning.activeWarningCodes.contains(entry.code) &&
              entry.resolvedAt == null;
    final high =
        entry?.level == WarningLevel.high ||
        (entry == null && warning.severity == 'high');
    final color = active && high
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final level = switch (entry?.level.name ?? warning.severity) {
      'high' => '高',
      'medium' => '中',
      'low' => '低',
      _ => '',
    };
    final state = switch (entry?.handleStatus) {
      WarningHandleStatus.resolved => '已解决',
      WarningHandleStatus.acknowledged => '已确认',
      _ => '待处理',
    };
    final time = entry == null
        ? occurredAtText
        : '${entry.occurredAt.hour.toString().padLeft(2, '0')}:${entry.occurredAt.minute.toString().padLeft(2, '0')}';
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '最近告警',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(onPressed: onTap, child: const Text('查看全部 ›')),
                  ],
                ),
                if (entry != null || warning.hasWarning) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        entry?.code ?? warning.primaryWarningCode ?? '安全提示',
                        key: const Key('primary-warning-code'),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        entry?.title ?? warning.message ?? '',
                        style: TextStyle(color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$level · $time · $state',
                    style: TextStyle(color: color),
                  ),
                  if (warning.requireReset)
                    Text('紧急停止已锁定，请先复位', style: TextStyle(color: color)),
                ] else
                  Text('暂无告警', style: TextStyle(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
