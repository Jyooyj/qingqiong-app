import 'package:flutter/material.dart';

import '../controllers/robot_controller.dart';
import '../models/robot_status.dart';
import '../services/warning_service.dart';

class DemoFaultPanel extends StatelessWidget {
  const DemoFaultPanel({super.key, required this.controller});

  final RobotController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.currentStatus;
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        key: const Key('demo-fault-panel'),
        leading: const Icon(Icons.science_outlined),
        title: const Text(
          '异常模拟',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text('模拟低电量、离线、定位异常、路径阻塞与设备故障'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _faultChip(
                  label: '低电量',
                  selected: controller.warningResult.activeWarningCodes
                      .contains('WARN-001'),
                  onSelected: (value) => controller.setBattery(
                    value
                        ? (WarningService.criticalBatteryThreshold +
                                  WarningService.lowBatteryThreshold) ~/
                              2
                        : 82,
                  ),
                ),
                _faultChip(
                  label: '严重低电量',
                  selected: controller.warningResult.activeWarningCodes
                      .contains('WARN-002'),
                  onSelected: (value) => controller.setBattery(
                    value ? WarningService.criticalBatteryThreshold - 1 : 82,
                  ),
                ),
                _faultChip(
                  label: '离线',
                  selected: !status.online,
                  onSelected: (value) => controller.setOnline(!value),
                ),
                _faultChip(
                  label: '定位失败',
                  selected: status.locationFailed,
                  onSelected: controller.setLocationFailed,
                ),
                _faultChip(
                  label: '路径阻塞',
                  selected: status.pathBlocked,
                  onSelected: controller.setPathBlocked,
                ),
                _faultChip(
                  label: '设备故障',
                  selected: status.deviceError,
                  onSelected: controller.setDeviceError,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('clear-demo-faults-button'),
              onPressed: controller.clearDemoFaults,
              icon: const Icon(Icons.cleaning_services_outlined),
              label: const Text('清除全部异常'),
            ),
          ),
          if (_hasSafetyFault(status))
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('异常已生效，控制权限已实时更新。'),
            ),
        ],
      ),
    );
  }

  Widget _faultChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      key: Key('fault-$label'),
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }

  bool _hasSafetyFault(RobotStatus status) {
    return !status.online ||
        status.battery < WarningService.lowBatteryThreshold ||
        status.locationFailed ||
        status.pathBlocked ||
        status.deviceError;
  }
}
