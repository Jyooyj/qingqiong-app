import 'package:flutter/material.dart';

typedef TaskFilterChanged = void Function(String filter);

class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final String current;
  final TaskFilterChanged onChanged;

  static const List<Map<String, String>> _filters = [
    {'key': 'all', 'label': '全部'},
    {'key': 'pending', 'label': '待执行'},
    {'key': 'running', 'label': '执行中'},
    {'key': 'paused', 'label': '已暂停'},
    {'key': 'cancelled', 'label': '已停止'},
    {'key': 'completed', 'label': '已完成'},
    {'key': 'failed', 'label': '失败'},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _filters.map((f) {
        final active = current == f['key'];
        return ChoiceChip(
          key: Key('filter-${f['key']}'),
          label: Text(f['label']!),
          selected: active,
          onSelected: (_) => onChanged(f['key']!),
        );
      }).toList(),
    );
  }
}
