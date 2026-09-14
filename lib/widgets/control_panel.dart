import 'package:flutter/material.dart';
import '../theme/app_design.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({
    super.key,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onCharge,
    required this.onEmergency,
    required this.onReset,
    required this.onVoice,
  });

  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onCharge;
  final VoidCallback? onEmergency;
  final VoidCallback? onReset;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('control-panel'),
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '核心控制',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 10.0;
                final width = (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    _ControlButton(
                      width: width,
                      buttonKey: const Key('start-button'),
                      label: '开始清扫',
                      icon: Icons.play_arrow_rounded,
                      onPressed: onStart,
                      backgroundColor: AppDesign.primarySoft,
                      foregroundColor: AppDesign.primary,
                    ),
                    _ControlButton(
                      width: width,
                      buttonKey: const Key('pause-button'),
                      label: '暂停',
                      icon: Icons.pause_rounded,
                      onPressed: onPause,
                      backgroundColor: AppDesign.primarySoft,
                      foregroundColor: AppDesign.primary,
                    ),
                    _ControlButton(
                      width: width,
                      buttonKey: const Key('resume-button'),
                      label: '继续',
                      icon: Icons.play_circle_outline,
                      onPressed: onResume,
                      backgroundColor: AppDesign.primarySoft,
                      foregroundColor: AppDesign.primary,
                    ),
                    _ControlButton(
                      width: width,
                      buttonKey: const Key('stop-button'),
                      label: '停止',
                      icon: Icons.stop_rounded,
                      onPressed: onStop,
                      backgroundColor: AppDesign.primarySoft,
                      foregroundColor: AppDesign.primary,
                    ),
                    _ControlButton(
                      width: width,
                      buttonKey: const Key('charge-button'),
                      label: '返回充电',
                      icon: Icons.battery_charging_full,
                      onPressed: onCharge,
                      backgroundColor: AppDesign.primarySoft,
                      foregroundColor: AppDesign.primary,
                    ),
                    _ControlButton(
                      width: width,
                      buttonKey: const Key('reset-button'),
                      label: '复位',
                      icon: Icons.restart_alt_rounded,
                      onPressed: onReset,
                      backgroundColor: AppDesign.primarySoft,
                      foregroundColor: AppDesign.primary,
                    ),
                    _ControlButton(
                      width: constraints.maxWidth,
                      buttonKey: const Key('emergency-button'),
                      label: '紧急停止',
                      icon: Icons.warning_amber_rounded,
                      onPressed: onEmergency,
                      backgroundColor: AppDesign.danger,
                      foregroundColor: Colors.white,
                    ),
                    _ControlButton(
                      width: constraints.maxWidth,
                      buttonKey: const Key('voice-button'),
                      label: '自然语言控制',
                      icon: Icons.mic_rounded,
                      onPressed: onVoice,
                      backgroundColor: AppDesign.success,
                      foregroundColor: Colors.white,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.width,
    required this.buttonKey,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  final double width;
  final Key buttonKey;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 48,
      child: FilledButton.icon(
        key: buttonKey,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor?.withValues(alpha: 0.28),
          disabledForegroundColor: foregroundColor?.withValues(alpha: 0.65),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 21),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
