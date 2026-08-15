import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onCharge;
  final VoidCallback onEmergency;
  final VoidCallback onVoice;

  const ControlPanel({
    super.key,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onCharge,
    required this.onEmergency,
    required this.onVoice,
  });

  Widget buildButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size.fromHeight(52),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildButton(title: "开始清扫", icon: Icons.play_arrow, onPressed: onStart),

        const SizedBox(height: 10),

        buildButton(title: "暂停", icon: Icons.pause, onPressed: onPause),

        const SizedBox(height: 10),

        buildButton(
          title: "继续",
          icon: Icons.play_circle_fill,
          onPressed: onResume,
        ),

        const SizedBox(height: 10),

        buildButton(title: "停止", icon: Icons.stop, onPressed: onStop),

        const SizedBox(height: 10),

        buildButton(
          title: "返回充电",
          icon: Icons.battery_charging_full,
          onPressed: onCharge,
        ),

        const SizedBox(height: 10),

        buildButton(
          title: "紧急停止",
          icon: Icons.warning,
          color: Colors.red,
          onPressed: onEmergency,
        ),

        const SizedBox(height: 10),

        buildButton(
          title: "语音控制",
          icon: Icons.mic,
          color: Colors.green,
          onPressed: onVoice,
        ),
      ],
    );
  }
}
