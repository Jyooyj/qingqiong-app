import 'package:flutter/material.dart';

class AlertsSummary extends StatelessWidget {
  const AlertsSummary({
    super.key,
    required this.currentAlertCount,
    required this.highestLevelText,
  });

  final int currentAlertCount;
  final String highestLevelText;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('alerts-summary'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _SummaryMetric(
                keyName: const Key('alerts-summary-count'),
                label: '当前告警',
                value: currentAlertCount.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryMetric(
                keyName: const Key('alerts-summary-level'),
                label: '最高等级',
                value: highestLevelText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.keyName,
    required this.label,
    required this.value,
  });

  final Key keyName;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          key: keyName,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
