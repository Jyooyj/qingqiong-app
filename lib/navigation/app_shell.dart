import '../services/task_statistics_formatter.dart';
import 'package:flutter/material.dart';

import '../controllers/robot_controller.dart';
import '../pages/alerts_page.dart';
import '../pages/home_page.dart';
import '../widgets/campus/cleaning_area_sheet.dart';
import '../widgets/geo_map/campus_geo_preview_page.dart';
import '../pages/profile_page.dart';
import '../pages/tasks_page.dart';
import '../models/cleaning_task.dart';
import '../services/product_session.dart';
import '../services/warning/warning_record.dart';
import '../widgets/alerts/alert_view_data.dart';
import '../widgets/tasks/task_view_data.dart';
import '../services/task_statistics_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.controller, this.session})
    : assert(controller == null || session == null);

  final RobotController? controller;
  final ProductSession? session;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final ProductSession _session;
  late final bool _ownsSession;

  @override
  void initState() {
    super.initState();
    _ownsSession = widget.session == null;
    _session =
        widget.session ?? ProductSession(robotController: widget.controller);
  }

  @override
  void dispose() {
    if (_ownsSession) {
      _session.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        final children = <Widget>[
          HomePage(
            session: _session,
            onNavigateToTasks: () => setState(() => _index = 1),
            onNavigateToAlerts: () => setState(() => _index = 3),
          ),
          TasksPage(
            onSelectCampusArea: _selectCampusArea,
            tasks: _session.taskController.tasks.map(_taskView).toList(),
            onCreate: _createTask,
            onExecute: _executeTask,
            onPause: (task) => _session.taskController.pauseTask(task.id),
            onResume: (task) => _session.resumeCurrentTask(),
            onStop: (task) => _session.stopCurrentTask(),
          ),
          _buildMapPage(),
          _buildAlertsPage(),
          ProfilePage(
            deviceName: _session.robotController.currentStatus.robotName,
            deviceId: _session.robotController.currentStatus.robotId,
            connectionStatusText: _session.robotController.currentStatus.online
                ? '已连接'
                : '离线',
            voiceStatusText: '文字指令可用 · 麦克风语音可用（需授权）',
          ),
        ];

        return Scaffold(
          body: SafeArea(
            child: IndexedStack(index: _index, children: children),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: '首页'),
              NavigationDestination(icon: Icon(Icons.assignment), label: '任务'),
              NavigationDestination(icon: Icon(Icons.map), label: '地图'),
              NavigationDestination(
                icon: Icon(Icons.notifications),
                label: '告警',
              ),
              NavigationDestination(icon: Icon(Icons.person), label: '我的'),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectCampusArea() async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CleaningAreaSheet(session: _session),
    );
    if (id == null || !mounted) return;
    final result = _session.campusCoordinator.startCampusCleaning(id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  void _createTask(TaskViewData view) {
    _session.createTask(
      id: view.id,
      name: view.name,
      area: view.area,
      mode: view.mode,
    );
  }

  void _executeTask(TaskViewData view) {
    final task =
        _session.taskController.getTaskById(view.id) ??
        _session.createTask(
          id: view.id,
          name: view.name,
          area: view.area,
          mode: view.mode,
        );
    _session.startTask(task.id);
  }

  TaskViewData _taskView(CleaningTask task) {
    final metrics = const TaskStatisticsService().forTask(
      task,
      customPolygon: task.campusZoneId == null
          ? null
          : _session.customCleaningAreas.findById(task.campusZoneId!)?.polygon,
    );
    return TaskViewData(
      id: task.id,
      name: task.displayTaskName ?? task.name,
      area: task.displayArea ?? task.area,
      status: task.status.name,
      progress: task.progress.round(),
      timeText: task.startedAt == null
          ? '创建: ${_time(task.createdAt)}'
          : '开始: ${_time(task.startedAt!)}',
      cleanedArea: metrics.area,
      cleanedDistance: metrics.distance,
      durationText: _duration(metrics.duration),
      startTimeText: metrics.startedAt == null
          ? null
          : _time(metrics.startedAt!),
      endTimeText: metrics.completedAt != null
          ? _time(metrics.completedAt!)
          : null,
      mode: task.mode,
      campusZoneId: task.campusZoneId,
      displayArea: task.displayArea,
      displayTaskName: task.displayTaskName,
    );
  }

  CampusGeoPreviewPage _buildMapPage() =>
      CampusGeoPreviewPage(coordinator: _session.campusCoordinator);

  AlertsPage _buildAlertsPage() {
    final current = _session.warningHistory.currentWarnings;
    final history = _session.warningHistory.historyWarnings;
    return AlertsPage(
      currentAlertCount: current.length,
      highestLevelText: _highestLevel(current),
      currentAlerts: current.map((record) => _alertView(record, true)).toList(),
      historyAlerts: history
          .map((record) => _alertView(record, false))
          .toList(),
      onHandle: (alert) {
        final id = alert.recordId;
        if (id != null) {
          _session.acknowledgeWarning(id);
        }
      },
      onResumeRequest: (alert) {
        final id = alert.recordId;
        if (id != null) {
          _session.resolveWarningAndResume(id);
        }
      },
    );
  }

  AlertViewData _alertView(WarningRecord record, bool isCurrent) {
    return AlertViewData(
      recordId: record.id,
      code: record.code,
      title: record.title,
      levelText: _level(record.level),
      occurredAtText: _time(record.occurredAt),
      handleStatusText: switch (record.handleStatus) {
        WarningHandleStatus.unhandled => '待处理',
        WarningHandleStatus.acknowledged => '已确认',
        WarningHandleStatus.resolved => '已解决',
      },
      reason: record.message,
      impact: _warningImpact(record.code),
      recommendation: record.recommendation,
      relatedTaskText: record.taskId == null ? '未关联任务' : '任务 ${record.taskId}',
      isCurrent: isCurrent,
    );
  }

  String _highestLevel(List<WarningRecord> records) {
    if (records.any((record) => record.level == WarningLevel.high)) {
      return '高';
    }
    if (records.any((record) => record.level == WarningLevel.medium)) {
      return '中';
    }
    return records.isEmpty ? '无' : '低';
  }

  String _level(WarningLevel level) => switch (level) {
    WarningLevel.high => '高',
    WarningLevel.medium => '中',
    WarningLevel.low => '低',
  };

  String _warningImpact(String code) => switch (code) {
    'WARN-004' => '机器人与当前任务均被急停锁存，普通控制全部拒绝。',
    'WARN-005' => '机器人安全停止，当前任务标记失败。',
    'WARN-007' => '机器人与任务暂停，模拟位置、轨迹和进度冻结。',
    'WARN-002' => '禁止启动新任务，建议返回充电。',
    'DATA-001' => '电量数据不可信，依赖电量的启动与继续操作被禁止。',
    _ => '控制权限已按 WarningService 的安全规则更新。',
  };

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}:'
      '${value.second.toString().padLeft(2, '0')}';

  String _duration(Duration value) => TaskStatisticsFormatter.duration(value);
}
