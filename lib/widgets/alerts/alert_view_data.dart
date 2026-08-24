import 'package:flutter/foundation.dart';

@immutable
class AlertViewData {
  const AlertViewData({
    required this.code,
    required this.title,
    required this.levelText,
    required this.occurredAtText,
    required this.handleStatusText,
    required this.reason,
    required this.impact,
    required this.recommendation,
    required this.relatedTaskText,
    this.isCurrent = true,
  });

  final String code;
  final String title;
  final String levelText;
  final String occurredAtText;
  final String handleStatusText;
  final String reason;
  final String impact;
  final String recommendation;
  final String relatedTaskText;
  final bool isCurrent;
}
