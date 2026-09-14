import 'package:flutter/material.dart';

class VoiceSettingsTile extends StatelessWidget {
  const VoiceSettingsTile({super.key, this.onTap, this.statusText = '可用'});

  final VoidCallback? onTap;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: const Key('profile-voice-settings'),
      child: ListTile(
        leading: const Icon(Icons.mic_rounded),
        title: const Text('交互模式'),
        subtitle: Text('自然语言指令 · 文字输入', style: theme.textTheme.bodyMedium),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
