import 'package:flutter/material.dart';

import '../../services/warning_service.dart';

class RecentAlertCard extends StatelessWidget {
  const RecentAlertCard({
    super.key,
    required this.warning,
    this.onTap,
    required this.occurredAtText,
  });

  final WarningResult warning;
  final VoidCallback? onTap;
  final String occurredAtText;

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
              Text(
                '最近告警',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (warning.hasWarning) ...[
                Text(
                  warning.primaryWarningCode ?? '安全提示',
                  key: const Key('primary-warning-code'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                // Severity mapping: high->高, medium->中, low->低
                if (warning.severity != null) ...[
                  Text(
                    _mapSeverity(warning.severity!),
                    key: const Key('primary-warning-level'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  occurredAtText,
                  key: const Key('primary-warning-time'),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  warning.message ?? '',
                  key: const Key('primary-warning-message'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (warning.requireReset) ...[
                  const SizedBox(height: 6),
                  const Text(
                    '紧急停止已锁定，请先复位',
                    key: Key('emergency-lock-message'),
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ] else ...[
                const SizedBox(height: 6),
                const Text(
                  '暂无告警',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _mapSeverity(String s) {
  switch (s) {
    case 'high':
      return '高';
    case 'medium':
      return '中';
    case 'low':
      return '低';
    default:
      return s;
  }
}
