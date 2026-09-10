import 'package:flutter/material.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({
    super.key,
    required this.version,
    this.onAboutTap,
    this.description = '智能清扫机器人解决方案，覆盖任务调度、路径规划与安全告警展示。',
  });

  final String version;
  final VoidCallback? onAboutTap;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '清穹无人清扫车',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text('当前版本：$version', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              key: const Key('profile-about'),
              onPressed: onAboutTap ?? () => _showAboutDialog(context),
              icon: const Icon(Icons.info_outline_rounded),
              label: const Text('关于清穹'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于清穹'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('清穹无人清扫车'),
              SizedBox(height: 8),
              Text('面向室内巡检与清扫场景的智能机器人方案。'),
              SizedBox(height: 8),
              Text('支持任务调度、路径规划、状态监控与告警展示。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
