import 'package:flutter/material.dart';

import '../services/warning_service.dart';

class WarningCard extends StatelessWidget {
  const WarningCard({super.key, required this.warning});

  final WarningResult warning;

  @override
  Widget build(BuildContext context) {
    if (!warning.hasWarning) {
      return const SizedBox.shrink();
    }

    final high = warning.severity == 'high';
    final color = high ? Colors.red.shade800 : Colors.orange.shade800;
    final background = high ? Colors.red.shade50 : Colors.orange.shade50;
    return Card(
      key: const Key('warning-card'),
      margin: EdgeInsets.zero,
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: high ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              high ? Icons.gpp_bad_rounded : Icons.warning_amber_rounded,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warning.primaryWarningCode ?? '安全提示',
                    key: const Key('primary-warning-code'),
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    warning.message ?? '',
                    key: const Key('primary-warning-message'),
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                  if (warning.activeWarningCodes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '活动预警：${warning.activeWarningCodes.join('、')}',
                      key: const Key('active-warning-codes'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (warning.requireReset) ...[
                    const SizedBox(height: 6),
                    const Text(
                      '紧急停止已锁定，请先复位',
                      key: Key('emergency-lock-message'),
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
