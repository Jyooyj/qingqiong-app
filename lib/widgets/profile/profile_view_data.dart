import 'package:flutter/material.dart';

@immutable
class ProfileViewData {
  const ProfileViewData({
    required this.deviceName,
    required this.deviceId,
    required this.softwareVersion,
    required this.connectionStatusText,
    required this.demoModeEnabled,
    this.onDemoModeChanged,
    this.onVoiceSettingsTap,
    this.onAboutTap,
  });

  final String deviceName;
  final String deviceId;
  final String softwareVersion;
  final String connectionStatusText;
  final bool demoModeEnabled;
  final ValueChanged<bool>? onDemoModeChanged;
  final VoidCallback? onVoiceSettingsTap;
  final VoidCallback? onAboutTap;
}
