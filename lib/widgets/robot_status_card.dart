import 'package:flutter/material.dart';

class RobotStatusCard extends StatelessWidget {
  final String robotName;
  final bool online;
  final int battery;
  final String area;
  final String status;
  final int progress;

  const RobotStatusCard({
    super.key,
    required this.robotName,
    required this.online,
    required this.battery,
    required this.area,
    required this.status,
    required this.progress,
  });

  Color _statusColor() {
    switch (status) {
      case "清扫中":
        return Colors.green;
      case "已暂停":
        return Colors.orange;
      case "充电中":
        return Colors.blue;
      case "紧急停止":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "机器人状态",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            _buildInfoRow(Icons.smart_toy, "设备", robotName),

            _buildInfoRow(Icons.wifi, "连接状态", online ? "在线" : "离线"),

            _buildInfoRow(Icons.battery_full, "电量", "$battery%"),

            _buildInfoRow(Icons.location_on, "当前区域", area),

            Row(
              children: [
                const Icon(Icons.settings),
                const SizedBox(width: 10),
                const Text(
                  "当前状态",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Chip(
                  backgroundColor: _statusColor(),
                  label: Text(
                    status,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Text("任务进度", style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            LinearProgressIndicator(
              value: progress / 100,
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
            ),

            const SizedBox(height: 8),

            Align(alignment: Alignment.centerRight, child: Text("$progress%")),
          ],
        ),
      ),
    );
  }
}
