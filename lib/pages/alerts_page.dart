import 'package:flutter/material.dart';

import '../widgets/alerts/alert_detail_panel.dart';
import '../widgets/alerts/alert_list_card.dart';
import '../widgets/alerts/alert_summary.dart';
import '../widgets/alerts/alert_view_data.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({
    super.key,
    this.currentAlertCount = 1,
    this.highestLevelText = '高',
    this.currentAlerts = const [
      AlertViewData(
        code: 'WARN-007',
        title: '路径阻塞',
        levelText: '中',
        occurredAtText: '刚刚',
        handleStatusText: '待处理',
        reason: '前方清扫路径被障碍物遮挡，机器人无法继续推进。',
        impact: '清扫任务将暂停，作业效率降低。',
        recommendation: '请确认前方路径是否清理干净后重试。',
        relatedTaskText: '任务 T-204 / A区清扫',
        isCurrent: true,
      ),
    ],
    this.historyAlerts = const [
      AlertViewData(
        code: 'WARN-002',
        title: '电量过低',
        levelText: '高',
        occurredAtText: '今天 08:20',
        handleStatusText: '已处理',
        reason: '机器人电量低于安全阈值。',
        impact: '任务已自动返回充电区。',
        recommendation: '已安排充电并恢复任务。',
        relatedTaskText: '任务 T-183 / 充电回收',
        isCurrent: false,
      ),
    ],
    this.onViewDetail,
    this.onHandle,
    this.onResumeRequest,
  });

  final int currentAlertCount;
  final String highestLevelText;
  final List<AlertViewData> currentAlerts;
  final List<AlertViewData> historyAlerts;
  final ValueChanged<AlertViewData>? onViewDetail;
  final ValueChanged<AlertViewData>? onHandle;
  final ValueChanged<AlertViewData>? onResumeRequest;

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _selectedAlertCode;
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _lastTabIndex = _tabController.index;
    _selectedAlertCode = _getCurrentAlerts().isNotEmpty
        ? _getCurrentAlerts().first.code
        : null;
  }

  @override
  void didUpdateWidget(covariant AlertsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activeAlerts = _getActiveAlerts();
    if (_selectedAlertCode != null &&
        !activeAlerts.any((alert) => alert.code == _selectedAlertCode)) {
      _selectedAlertCode = null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange(int index) {
    if (index == _lastTabIndex) {
      return;
    }
    _lastTabIndex = index;
    setState(() => _selectedAlertCode = null);
  }

  List<AlertViewData> _getCurrentAlerts() => widget.currentAlerts;

  List<AlertViewData> _getHistoryAlerts() => widget.historyAlerts;

  List<AlertViewData> _getActiveAlerts() =>
      _tabController.index == 0 ? _getCurrentAlerts() : _getHistoryAlerts();

  AlertViewData? _selectedAlert() {
    if (_selectedAlertCode == null) return null;
    return _getActiveAlerts()
        .where((alert) => alert.code == _selectedAlertCode)
        .firstOrNull();
  }

  @override
  Widget build(BuildContext context) {
    final summary = AlertsSummary(
      currentAlertCount: widget.currentAlertCount,
      highestLevelText: widget.highestLevelText,
    );

    final tabBar = TabBar(
      controller: _tabController,
      onTap: _handleTabChange,
      tabs: [
        Tab(key: const ValueKey('alerts-current-tab'), text: '当前告警'),
        Tab(key: const ValueKey('alerts-history-tab'), text: '历史告警'),
      ],
    );

    final activeAlerts = _getActiveAlerts();
    final selectedAlert = _selectedAlert();

    return Scaffold(
      appBar: AppBar(title: const Text('告警中心')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 760;
            final listView = Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: activeAlerts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final alert = activeAlerts[index];
                  final isSelected = selectedAlert?.code == alert.code;
                  return AlertListCard(
                    alert: alert,
                    selected: isSelected,
                    onViewDetail: () {
                      widget.onViewDetail?.call(alert);
                      setState(() => _selectedAlertCode = alert.code);
                    },
                  );
                },
              ),
            );

            final detailView = Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: selectedAlert == null
                    ? const Center(
                        child: Text(
                          '选择一条告警查看详情',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : AlertDetailPanel(
                        alert: selectedAlert,
                        onHandle: widget.onHandle == null
                            ? null
                            : () => widget.onHandle!(selectedAlert),
                        onResumeRequest: widget.onResumeRequest == null
                            ? null
                            : () => widget.onResumeRequest!(selectedAlert),
                      ),
              ),
            );

            return Column(
              children: [
                Padding(padding: const EdgeInsets.all(12), child: summary),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: tabBar,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [listView, detailView],
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                itemCount: activeAlerts.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final alert = activeAlerts[index];
                                  final isSelected =
                                      selectedAlert?.code == alert.code;
                                  return AlertListCard(
                                    alert: alert,
                                    selected: isSelected,
                                    onViewDetail: () {
                                      widget.onViewDetail?.call(alert);
                                      setState(
                                        () => _selectedAlertCode = alert.code,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            if (selectedAlert != null)
                              SizedBox(
                                height: 260,
                                child: AlertDetailPanel(
                                  alert: selectedAlert,
                                  onHandle: widget.onHandle == null
                                      ? null
                                      : () => widget.onHandle!(selectedAlert),
                                  onResumeRequest:
                                      widget.onResumeRequest == null
                                      ? null
                                      : () => widget.onResumeRequest!(
                                          selectedAlert,
                                        ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

extension on Iterable<AlertViewData> {
  AlertViewData? firstOrNull() => isEmpty ? null : first;
}
