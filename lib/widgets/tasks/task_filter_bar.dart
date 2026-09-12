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

  static const List<Map<String, String>> filters = [
    {'key': 'all', 'label': '\u5168\u90e8'},
    {'key': 'pending', 'label': '\u5f85\u6267\u884c'},
    {'key': 'running', 'label': '\u6267\u884c\u4e2d'},
    {'key': 'paused', 'label': '\u5df2\u6682\u505c'},
    {'key': 'cancelled', 'label': '\u5df2\u505c\u6b62'},
    {'key': 'completed', 'label': '\u5df2\u5b8c\u6210'},
    {'key': 'failed', 'label': '\u5931\u8d25'},
  ];
  static String labelFor(String key) => filters.firstWhere(
    (f) => f['key'] == key,
    orElse: () => filters.first,
  )['label']!;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: filters.map((filter) {
        final active = current == filter['key'];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _TaskFilterButton(
            key: Key("filter-${filter['key']}"),
            selected: active,
            label: filter['label']!,
            onTap: () => onChanged(filter['key']!),
          ),
        );
      }).toList(),
    ),
  );
}

class _TaskFilterButton extends StatelessWidget {
  const _TaskFilterButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? primary.withValues(alpha: .12) : Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected ? primary : const Color(0xFFD9E0E4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 16, color: primary),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? primary : const Color(0xFF64727D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
