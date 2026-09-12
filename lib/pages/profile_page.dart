import 'package:flutter/material.dart';

import '../widgets/profile/about_section.dart';
import '../widgets/profile/demo_mode_card.dart';
import '../widgets/profile/device_info_card.dart';
import '../widgets/profile/voice_settings_tile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    this.deviceName = '清穹一号',
    this.deviceId = 'QQ-RC-001',
    this.softwareVersion = 'V1.0.0',
    this.connectionStatusText = '已连接',
    this.demoModeEnabled = true,
    this.voiceStatusText = '可用',
    this.onDemoModeChanged,
    this.onVoiceSettingsTap,
    this.onAboutTap,
  });

  final String deviceName;
  final String deviceId;
  final String softwareVersion;
  final String connectionStatusText;
  final bool demoModeEnabled;
  final String voiceStatusText;
  final ValueChanged<bool>? onDemoModeChanged;
  final VoidCallback? onVoiceSettingsTap;
  final VoidCallback? onAboutTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的 / 设置')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxContentWidth = constraints.maxWidth > 760
                ? 760.0
                : constraints.maxWidth;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DeviceInfoCard(
                        deviceName: deviceName,
                        deviceId: deviceId,
                        softwareVersion: softwareVersion,
                        connectionStatusText: connectionStatusText,
                      ),
                      const SizedBox(height: 16),
                      DemoModeCard(
                        enabled: demoModeEnabled,
                        onChanged: onDemoModeChanged,
                      ),
                      const SizedBox(height: 16),
                      VoiceSettingsTile(
                        onTap: onVoiceSettingsTap,
                        statusText: voiceStatusText,
                      ),
                      const SizedBox(height: 16),
                      AboutSection(
                        version: softwareVersion,
                        onAboutTap: onAboutTap,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
