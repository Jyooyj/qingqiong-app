import 'package:flutter/material.dart';

import 'alert_view_data.dart';

class AlertDetailPanel extends StatelessWidget {
  const AlertDetailPanel({
    super.key,
    required this.alert,
    this.onHandle,
    this.onResumeRequest,
  });

  final AlertViewData alert;
  final VoidCallback? onHandle;
  final VoidCallback? onResumeRequest;

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(alert.levelText);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      alert.levelText,
                      style: TextStyle(
                        color: levelColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert.code,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _InfoRow(label: '发生时间', value: alert.occurredAtText),
              _InfoRow(label: '处理状态', value: alert.handleStatusText),
              const SizedBox(height: 16),
              _SectionTitle(title: '告警原因'),
              Text(alert.reason),
              const SizedBox(height: 12),
              _SectionTitle(title: '影响'),
              Text(alert.impact),
              const SizedBox(height: 12),
              _SectionTitle(title: '处理建议'),
              Text(alert.recommendation),
              const SizedBox(height: 12),
              _SectionTitle(title: '关联任务'),
              Text(alert.relatedTaskText),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onHandle,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('处理'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onResumeRequest,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('恢复任务'),
                    ),
                  ),
                ],
              ),
              if (onHandle == null || onResumeRequest == null) ...[
                const SizedBox(height: 10),
                Text(
                  '当前告警暂不支持在此操作，请检查设备状态。',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _levelColor(String levelText) {
    switch (levelText) {
      case '高':
        return Colors.red;
      case '中':
        return Colors.orange;
      case '低':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
