import '../services/task_statistics_formatter.dart';
import 'package:flutter/material.dart';

import '../controllers/robot_controller.dart';
import '../widgets/campus/quick_cleaning_card.dart';
import '../models/cleaning_task.dart';
import '../services/product_session.dart';
import '../services/voice_control_service.dart';
import '../widgets/control_panel.dart';
import '../widgets/demo_fault_panel.dart';
import '../widgets/robot_status_card.dart';
import '../widgets/dashboard/current_task_card.dart';
import '../widgets/dashboard/dashboard_stats_card.dart';
import '../widgets/dashboard/recent_alert_card.dart';
import '../widgets/voice_control_sheet.dart';
import '../services/task_statistics_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.controller,
    this.session,
    this.onNavigateToTasks,
    this.onNavigateToAlerts,
  });

  final RobotController? controller;
  final ProductSession? session;
  final VoidCallback? onNavigateToTasks;
  final VoidCallback? onNavigateToAlerts;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final RobotController _controller;
  late final VoiceControlService _voiceService;
  late final ProductSession _session;
  late final bool _ownsSession;

  @override
  void initState() {
    super.initState();
    _ownsSession = widget.session == null;
    _session =
        widget.session ?? ProductSession(robotController: widget.controller);
    _controller = _session.robotController;
    _voiceService = _session.voiceControlService;
  }

  @override
  void dispose() {
    if (_ownsSession) {
      _session.dispose();
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
          behavior: SnackBarBehavior.floating,
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
      animation: _session,
      builder: (context, _) {
        final status = _controller.currentStatus;
        final warning = _controller.warningResult;
        final records = _session.warningHistory;
        final recent =
            records.currentWarnings.lastOrNull ?? records.allRecords.lastOrNull;
        final task = _session.currentTask;
        final stats = _session.dashboardStats;
        final taskMetrics = task == null
            ? null
            : const TaskStatisticsService().forTask(
                task,
                customPolygon: task.campusZoneId == null
                    ? null
                    : _session.customCleaningAreas
                          .findById(task.campusZoneId!)
                          ?.polygon,
              );

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
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          status.online ? Icons.cloud_done : Icons.cloud_off,
                          size: 18,
                          color: status.online
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status.online ? '在线' : '离线',
                          softWrap: false,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
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
                                      displayArea: task?.displayArea,
                                    ),
                                    const SizedBox(height: 12),
                                    // Quick task entries are separate from the full area catalog.
                                    QuickCleaningCard(
                                      session: _session,
                                      onRun: _run,
                                    ),
                                    const SizedBox(height: 12),
                                    // Current task card
                                    CurrentTaskCard(
                                      key: const Key('dashboard-current-task'),
                                      title:
                                          task?.displayTaskName ??
                                          task?.name ??
                                          '暂无任务',
                                      area:
                                          task?.displayArea ??
                                          task?.area ??
                                          status.area,
                                      statusText: _taskStatus(task),
                                      progress:
                                          task?.progress.round() ??
                                          status.progress,
                                      eta: _taskEta(task),
                                      empty: task == null,
                                      onTap: widget.onNavigateToTasks,
                                      cleanedArea: taskMetrics?.area,
                                      cleanedDistance: taskMetrics?.distance,
                                      duration: taskMetrics == null
                                          ? null
                                          : _duration(taskMetrics.duration),
                                    ),
                                    const SizedBox(height: 12),
                                    // Quick stats
                                    DashboardStatsCard(
                                      key: const Key('dashboard-stats'),
                                      tasksToday: stats.todayTaskCount,
                                      completed: stats.todayCompletedCount,
                                      area: TaskStatisticsFormatter.area(
                                        stats.totalCleanedArea,
                                      ),
                                      duration: _duration(
                                        stats.totalCleaningDuration,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Recent alert
                                    RecentAlertCard(
                                      key: const Key('dashboard-recent-alert'),
                                      warning: warning,
                                      record: recent,
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
                              RobotStatusCard(
                                status: status,
                                displayArea: task?.displayArea,
                              ),
                              const SizedBox(height: 10),
                              // Place control panel early so core buttons stay visible
                              _buildControlPanel(),
                              const SizedBox(height: 10),
                              // Current task card
                              CurrentTaskCard(
                                key: const Key('dashboard-current-task'),
                                title:
                                    task?.displayTaskName ??
                                    task?.name ??
                                    '暂无任务',
                                area:
                                    task?.displayArea ??
                                    task?.area ??
                                    status.area,
                                statusText: _taskStatus(task),
                                progress:
                                    task?.progress.round() ?? status.progress,
                                eta: _taskEta(task),
                                empty: task == null,
                                onTap: widget.onNavigateToTasks,
                                cleanedArea: taskMetrics?.area,
                                cleanedDistance: taskMetrics?.distance,
                                duration: taskMetrics == null
                                    ? null
                                    : _duration(taskMetrics.duration),
                              ),
                              const SizedBox(height: 10),
                              // Recent alert or warning card
                              RecentAlertCard(
                                key: const Key('dashboard-recent-alert'),
                                warning: warning,
                                record: recent,
                                occurredAtText: '刚刚',
                                onTap: widget.onNavigateToAlerts,
                              ),
                              const SizedBox(height: 10),
                              QuickCleaningCard(session: _session, onRun: _run),
                              const SizedBox(height: 10),
                              DashboardStatsCard(
                                key: const Key('dashboard-stats'),
                                tasksToday: stats.todayTaskCount,
                                completed: stats.todayCompletedCount,
                                area: TaskStatisticsFormatter.area(
                                  stats.totalCleanedArea,
                                ),
                                duration: _duration(
                                  stats.totalCleaningDuration,
                                ),
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
    final session = _session;
    return ControlPanel(
      onStart: session.canStartTask
          ? () => _run(session.startOrCreateTask)
          : null,
      onPause: session.canPauseTask
          ? () => _run(session.pauseCurrentTask)
          : null,
      onResume: session.canResumeTask
          ? () => _run(session.resumeCurrentTask)
          : null,
      onStop: session.canStopTask ? () => _run(session.stopCurrentTask) : null,
      onCharge: _controller.canCharge
          ? () => _run(session.returnToCharge)
          : null,
      onEmergency: _controller.canEmergencyStop
          ? () => _run(session.emergencyStop)
          : null,
      onReset: _controller.canReset ? () => _run(session.resetEmergency) : null,
      onVoice: _showVoiceControl,
    );
  }

  String _taskStatus(CleaningTask? task) {
    if (task == null) {
      return '待创建';
    }
    return switch (task.status) {
      CleaningTaskStatus.pending => '待执行',
      CleaningTaskStatus.running => '清扫中',
      CleaningTaskStatus.paused => '已暂停',
      CleaningTaskStatus.completed => '已完成',
      CleaningTaskStatus.failed => '失败',
      CleaningTaskStatus.cancelled => '已停止',
    };
  }

  String _taskEta(CleaningTask? task) {
    if (task == null || task.status == CleaningTaskStatus.completed) {
      return '--';
    }
    final seconds = ((100 - task.progress) / 5).ceil().clamp(0, 999);
    return '约 $seconds 秒';
  }

  String _duration(Duration value) => TaskStatisticsFormatter.duration(value);
}
