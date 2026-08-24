import 'package:flutter/material.dart';

import '../controllers/robot_controller.dart';
import '../services/voice_control_service.dart';
import '../widgets/control_panel.dart';
import '../widgets/demo_fault_panel.dart';
import '../widgets/robot_status_card.dart';
import '../widgets/dashboard/current_task_card.dart';
import '../widgets/dashboard/dashboard_stats_card.dart';
import '../widgets/dashboard/recent_alert_card.dart';
import '../widgets/voice_control_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.controller,
    this.onNavigateToTasks,
    this.onNavigateToAlerts,
  });

  final RobotController? controller;
  final VoidCallback? onNavigateToTasks;
  final VoidCallback? onNavigateToAlerts;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final RobotController _controller;
  late final VoiceControlService _voiceService;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? RobotController();
    _voiceService = VoiceControlService(controller: _controller);
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _run(ControlResult Function() operation) {
    final result = operation();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success
              ? Colors.green.shade700
              : Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _showVoiceControl() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => VoiceControlSheet(service: _voiceService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final status = _controller.currentStatus;
        final warning = _controller.warningResult;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              '清穹无人清扫车',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  avatar: Icon(
                    status.online ? Icons.cloud_done : Icons.cloud_off,
                    size: 18,
                    color: status.online
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  label: Text(status.online ? '在线' : '离线'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 900;
              final padding = desktop ? 20.0 : 12.0;
              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: desktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: [
                                    // Device overview (reuse RobotStatusCard)
                                    RobotStatusCard(
                                      status: _controller.currentStatus,
                                    ),
                                    const SizedBox(height: 12),
                                    // Area selector (desktop only) placed after status and before current task
                                    _AreaSelector(
                                      selectedArea: status.area,
                                      enabled: _controller.canSelectArea,
                                      onSelected: (area) => _run(
                                        () => _controller.selectArea(area),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Current task card
                                    CurrentTaskCard(
                                      key: const Key('dashboard-current-task'),
                                      title: '示例任务',
                                      area: _controller.currentStatus.area,
                                      statusText:
                                          _controller.currentStatus.stateText,
                                      progress:
                                          _controller.currentStatus.progress,
                                      eta: '约 12 分钟',
                                      onTap: widget.onNavigateToTasks,
                                    ),
                                    const SizedBox(height: 12),
                                    // Quick stats
                                    DashboardStatsCard(
                                      key: const Key('dashboard-stats'),
                                      tasksToday: 3,
                                      completed: 2,
                                      area: '45 m²',
                                      duration: '00:42:15',
                                    ),
                                    const SizedBox(height: 12),
                                    // Recent alert
                                    RecentAlertCard(
                                      key: const Key('dashboard-recent-alert'),
                                      warning: warning,
                                      occurredAtText: '刚刚',
                                      onTap: widget.onNavigateToAlerts,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 410,
                                child: Column(
                                  children: [
                                    _buildControlPanel(),
                                    const SizedBox(height: 12),
                                    DemoFaultPanel(controller: _controller),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              // Device overview
                              RobotStatusCard(status: status),
                              const SizedBox(height: 10),
                              // Place control panel early so core buttons stay visible
                              _buildControlPanel(),
                              const SizedBox(height: 10),
                              // Current task card
                              CurrentTaskCard(
                                key: const Key('dashboard-current-task'),
                                title: '示例任务',
                                area: status.area,
                                statusText: status.stateText,
                                progress: status.progress,
                                eta: '约 12 分钟',
                                onTap: widget.onNavigateToTasks,
                              ),
                              const SizedBox(height: 10),
                              // Recent alert or warning card
                              RecentAlertCard(
                                key: const Key('dashboard-recent-alert'),
                                warning: warning,
                                occurredAtText: '刚刚',
                                onTap: widget.onNavigateToAlerts,
                              ),
                              const SizedBox(height: 10),
                              _AreaSelector(
                                selectedArea: status.area,
                                enabled: _controller.canSelectArea,
                                onSelected: (area) =>
                                    _run(() => _controller.selectArea(area)),
                              ),
                              const SizedBox(height: 10),
                              DashboardStatsCard(
                                key: const Key('dashboard-stats'),
                                tasksToday: 3,
                                completed: 2,
                                area: '45 m²',
                                duration: '00:42:15',
                              ),
                              const SizedBox(height: 10),
                              DemoFaultPanel(controller: _controller),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  ControlPanel _buildControlPanel() {
    return ControlPanel(
      onStart: _controller.canStart ? () => _run(_controller.start) : null,
      onPause: _controller.canPause ? () => _run(_controller.pause) : null,
      onResume: _controller.canResume ? () => _run(_controller.resume) : null,
      onStop: _controller.canStop ? () => _run(_controller.stop) : null,
      onCharge: _controller.canCharge ? () => _run(_controller.charge) : null,
      onEmergency: _controller.canEmergencyStop
          ? () => _run(_controller.emergencyStop)
          : null,
      onReset: _controller.canReset ? () => _run(_controller.reset) : null,
      onVoice: _showVoiceControl,
    );
  }
}

// _OverviewColumn removed; dashboard widgets are integrated directly in HomePage.

class _AreaSelector extends StatelessWidget {
  const _AreaSelector({
    required this.selectedArea,
    required this.enabled,
    required this.onSelected,
  });

  final String selectedArea;
  final bool enabled;
  final ValueChanged<String> onSelected;

  static const List<String> _areas = <String>['A区', 'B区', 'C区'];

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('area-selector'),
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '清扫区域',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(enabled ? '待机时可选' : '任务中已锁定'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var index = 0; index < _areas.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _AreaButton(
                      area: _areas[index],
                      selected: selectedArea == _areas[index],
                      enabled: enabled,
                      onPressed: () => onSelected(_areas[index]),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaButton extends StatelessWidget {
  const _AreaButton({
    required this.area,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final String area;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: selected
          ? FilledButton(
              key: Key('area-$area'),
              onPressed: enabled ? onPressed : null,
              child: Text(area, maxLines: 1),
            )
          : OutlinedButton(
              key: Key('area-$area'),
              onPressed: enabled ? onPressed : null,
              child: Text(area, maxLines: 1),
            ),
    );
  }
}
