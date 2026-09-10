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
        title: const Text('语音设置'),
        subtitle: Text(
          '文本指令：$statusText\n麦克风语音：待接入',
          style: theme.textTheme.bodyMedium,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
