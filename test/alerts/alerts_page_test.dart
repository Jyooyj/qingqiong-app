import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/pages/alerts_page.dart';
import 'package:robot_cleaner/widgets/alerts/alert_detail_panel.dart';
import 'package:robot_cleaner/widgets/alerts/alert_view_data.dart';

void main() {
  final currentAlerts = [
    const AlertViewData(
      code: 'WARN-007',
      title: '路径阻塞',
      levelText: '中',
      occurredAtText: '刚刚',
      handleStatusText: '待处理',
      reason: '前方路径受阻。',
      impact: '清扫中断。',
      recommendation: '清理障碍后继续。',
      relatedTaskText: '任务 T-204 / A区清扫',
      isCurrent: true,
    ),
  ];

  final historyAlerts = [
    const AlertViewData(
      code: 'WARN-002',
      title: '电量过低',
      levelText: '高',
      occurredAtText: '今天 08:20',
      handleStatusText: '已处理',
      reason: '电量低于阈值。',
      impact: '已返回充电。',
      recommendation: '已完成补电。',
      relatedTaskText: '任务 T-183 / 充电回收',
      isCurrent: false,
    ),
  ];

  Future<void> pumpAlertsPage(
    WidgetTester tester, {
    List<AlertViewData>? current,
    List<AlertViewData>? history,
    ValueChanged<AlertViewData>? onViewDetail,
    ValueChanged<AlertViewData>? onHandle,
    ValueChanged<AlertViewData>? onResumeRequest,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AlertsPage(
          currentAlertCount: current?.length ?? currentAlerts.length,
          highestLevelText: '高',
          currentAlerts: current ?? currentAlerts,
          historyAlerts: history ?? historyAlerts,
          onViewDetail: onViewDetail,
          onHandle: onHandle,
          onResumeRequest: onResumeRequest,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('page title, summary, tabs and cards render', (tester) async {
    await pumpAlertsPage(tester);

    expect(find.text('告警中心'), findsOneWidget);
    expect(find.byKey(const Key('alerts-summary')), findsOneWidget);
    expect(find.byKey(const Key('alerts-summary-count')), findsOneWidget);
    expect(find.byKey(const Key('alerts-summary-level')), findsOneWidget);
    expect(find.byKey(const Key('alerts-current-tab')), findsOneWidget);
    expect(find.byKey(const Key('alerts-history-tab')), findsOneWidget);

    expect(find.text('WARN-007').at(0), findsOneWidget);
    expect(find.text('路径阻塞').at(0), findsOneWidget);
    expect(find.text('中'), findsWidgets);
    expect(find.text('刚刚').at(0), findsOneWidget);
    expect(find.text('待处理').at(0), findsOneWidget);
  });

  testWidgets('current detail displays when selected', (tester) async {
    await pumpAlertsPage(tester);

    await tester.ensureVisible(find.text('WARN-007').at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WARN-007').at(0));
    await tester.pumpAndSettle();

    expect(find.text('告警原因'), findsOneWidget);
    expect(find.text('前方路径受阻。'), findsOneWidget);
    expect(find.text('影响'), findsOneWidget);
    expect(find.text('清扫中断。'), findsOneWidget);
    expect(find.text('处理建议'), findsOneWidget);
    expect(find.text('清理障碍后继续。'), findsOneWidget);
    expect(find.text('关联任务'), findsOneWidget);
    expect(find.text('任务 T-204 / A区清扫'), findsOneWidget);
  });

  testWidgets(
    'tab switch clears stale detail immediately and does not auto-select first item',
    (tester) async {
      await pumpAlertsPage(tester);

      await tester.tap(find.text('WARN-007').at(0));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDetailPanel), findsOneWidget);

      await tester.tap(find.byKey(const Key('alerts-history-tab')));
      await tester.pumpAndSettle();

      expect(find.text('WARN-007'), findsNothing);
      expect(find.text('前方路径受阻。'), findsNothing);
      expect(find.text('选择一条告警查看详情'), findsOneWidget);

      await tester.tap(find.text('WARN-002').at(0));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDetailPanel), findsOneWidget);
      expect(find.text('电量低于阈值。'), findsOneWidget);

      await tester.tap(find.byKey(const Key('alerts-current-tab')));
      await tester.pumpAndSettle();

      expect(find.text('选择一条告警查看详情'), findsOneWidget);
      expect(find.text('电量低于阈值。'), findsNothing);
      expect(find.byType(AlertDetailPanel), findsNothing);
    },
  );

  testWidgets('tap handle callback only triggers callback', (tester) async {
    AlertViewData? lastHandled;

    await pumpAlertsPage(
      tester,
      onHandle: (alert) => lastHandled = alert,
      onResumeRequest: (alert) =>
          throw StateError('resume callback should not be called'),
    );

    await tester.tap(find.text('WARN-007').at(0));
    await tester.pumpAndSettle();

    final handleButton = find.widgetWithText(FilledButton, '处理');
    await tester.ensureVisible(handleButton);
    await tester.pumpAndSettle();
    await tester.tap(handleButton);
    await tester.pumpAndSettle();

    expect(lastHandled, isNotNull);
    expect(lastHandled!.code, 'WARN-007');
  });

  testWidgets('callback missing disables actions and shows waiting message', (
    tester,
  ) async {
    await pumpAlertsPage(tester, onHandle: null, onResumeRequest: null);

    await tester.tap(find.text('WARN-007').at(0));
    await tester.pumpAndSettle();

    expect(find.text('等待Safety接入：处理与恢复动作暂未接入，按钮已禁用。'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
  });

  testWidgets('responsive layouts for mobile and desktop no overflow', (
    tester,
  ) async {
    final sizes = [
      const Size(360, 800),
      const Size(390, 844),
      const Size(430, 932),
      const Size(1366, 768),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await pumpAlertsPage(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('WARN-007').at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('WARN-007').at(0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
