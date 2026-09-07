import 'package:flutter/material.dart';
import '../../data/campus/campus_map_data.dart';
import '../../models/cleaning_task.dart';
import '../../models/robot_status.dart';
import '../../services/campus_demo_coordinator.dart';
import 'campus_map_view.dart';
import 'current_task_map_card.dart';

class CampusDemoPage extends StatefulWidget {
  const CampusDemoPage({super.key, required this.coordinator});

  final CampusDemoCoordinator coordinator;
  @override
  State<CampusDemoPage> createState() => _CampusDemoPageState();
}

class _CampusDemoPageState extends State<CampusDemoPage> {
  final _commandController = TextEditingController();

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  void _executeCommand() {
    FocusScope.of(context).unfocus();
    final result = widget.coordinator.handleVoiceText(_commandController.text);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    // Rejected speech intentionally does not mutate coordinator.lastMessage.
    if (!result.success) {
      messenger.showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  CampusTaskViewData _taskData(CampusDemoCoordinator coordinator) {
    final task = coordinator.currentTask;
    final robot = coordinator.session.robotController;
    final warning = robot.warningResult;
    final status = robot.currentStatus.state == RobotState.emergency
        ? CampusTaskStatus.emergency
        : warning.hasWarning || task?.status == CleaningTaskStatus.failed
        ? CampusTaskStatus.fault
        : switch (task?.status) {
            null => CampusTaskStatus.preview,
            CleaningTaskStatus.pending => CampusTaskStatus.pending,
            CleaningTaskStatus.running => CampusTaskStatus.running,
            CleaningTaskStatus.paused => CampusTaskStatus.paused,
            CleaningTaskStatus.completed ||
            CleaningTaskStatus.cancelled => CampusTaskStatus.completed,
            CleaningTaskStatus.failed => CampusTaskStatus.fault,
          };
    return CampusTaskViewData(
      targetZoneName: coordinator.selectedZoneName,
      status: status,
      progress: task?.progress,
      cleanedArea: task?.cleanedArea,
      elapsed: task?.elapsed,
      message: warning.hasWarning
          ? '${warning.activeWarningCodes.join(' / ')}：${warning.message ?? ''}'
          : task?.status == CleaningTaskStatus.cancelled
          ? '任务已停止/取消'
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = widget.coordinator;
    return Scaffold(
      appBar: AppBar(title: const Text('校园智能清扫')),
      body: AnimatedBuilder(
        animation: coordinator,
        builder: (context, _) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '选择清扫区域',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('选择校园区域，或输入自然语言指令创建并控制清扫任务。'),
                    const SizedBox(height: 16),
                    CampusMapView(
                      zones: CampusMapData.zones,
                      taskData: _taskData(coordinator),
                      selectedZoneId: coordinator.selectedZoneId,
                      robotPosition: coordinator.robotPosition,
                      plannedPath: coordinator.plannedPath,
                      cleanedPath: coordinator.cleanedPath,
                      chargingStation: coordinator.chargingStation,
                      obstacles: coordinator.visibleObstacles,
                      onZoneTap: coordinator.selectZone,
                      onPause: coordinator.canPause
                          ? () => coordinator.pause()
                          : null,
                      onResume: coordinator.canResume
                          ? () => coordinator.resume()
                          : null,
                      onEmergencyStop: coordinator.canEmergencyStop
                          ? () => coordinator.emergencyStop()
                          : null,
                      onReset: coordinator.canReset
                          ? () => coordinator.reset()
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final item in CampusMapData.zones)
                          ChoiceChip(
                            key: Key('campus-choice-${item.id}'),
                            label: Text(item.name),
                            selected: item.id == coordinator.selectedZoneId,
                            onSelected: (_) => coordinator.selectZone(item.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('campus-start-selected'),
                      onPressed:
                          coordinator.selectedZoneId != null &&
                              coordinator.session.canStartTask
                          ? () => coordinator.startCampusCleaning(
                              coordinator.selectedZoneId!,
                            )
                          : null,
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: const Text('开始清扫选中区域'),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '自然语言指令',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('campus-command-input'),
                      controller: _commandController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _executeCommand(),
                      decoration: const InputDecoration(
                        hintText: '例如：去实验楼附近清扫',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      key: const Key('campus-execute-command'),
                      onPressed: _executeCommand,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('执行指令'),
                    ),
                    if (coordinator.lastMessage != null) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          coordinator.lastMessage!,
                          key: const Key('campus-command-message'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SwitchListTile(
                      key: const Key('campus-path-blocked'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('模拟路径阻塞（WARN-007）'),
                      value: coordinator
                          .session
                          .robotController
                          .currentStatus
                          .pathBlocked,
                      onChanged: coordinator.setDemoPathBlocked,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
