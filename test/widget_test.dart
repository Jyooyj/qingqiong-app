import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/controllers/robot_controller.dart';
import 'package:robot_cleaner/main.dart';
import 'package:robot_cleaner/models/robot_status.dart';

void main() {
  late RobotController controller;

  setUp(() {
    controller = RobotController(autoProgress: false);
  });

  tearDown(() => controller.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(QingQiongApp(controller: controller));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  testWidgets('QingQiong app smoke test', (tester) async {
    await pumpApp(tester);

    expect(find.text('清穹无人清扫车'), findsOneWidget);
  });

  testWidgets('清穹首页展示统一机器人状态', (tester) async {
    await pumpApp(tester);

    expect(find.text('清穹无人清扫车'), findsOneWidget);
    expect(find.text('机器人名称'), findsOneWidget);
    expect(find.textContaining('当前任务状态'), findsOneWidget);
    expect(find.text('A区'), findsWidgets);
    expect(find.byKey(const Key('start-button')), findsOneWidget);
    expect(find.byKey(const Key('voice-button')), findsOneWidget);
  });

  testWidgets('按钮开始暂停继续停止真实驱动 Controller', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pump();
    expect(controller.currentStatus.state, RobotState.cleaning);
    expect(find.text('清扫中'), findsWidgets);

    await tester.tap(find.byKey(const Key('pause-button')));
    await tester.pump();
    expect(controller.currentStatus.state, RobotState.paused);

    await tester.tap(find.byKey(const Key('resume-button')));
    await tester.pump();
    expect(controller.currentStatus.state, RobotState.cleaning);

    await tester.tap(find.byKey(const Key('stop-button')));
    await tester.pump();
    expect(controller.currentStatus.state, RobotState.idle);
    expect(controller.currentStatus.progress, 0);
  });

  testWidgets('待机暂停和继续按钮禁用', (tester) async {
    await pumpApp(tester);

    final pause = tester.widget<FilledButton>(
      find.byKey(const Key('pause-button')),
    );
    final resume = tester.widget<FilledButton>(
      find.byKey(const Key('resume-button')),
    );

    expect(pause.onPressed, isNull);
    expect(resume.onPressed, isNull);
  });

  testWidgets('急停显示 WARN-004 和锁定文案，复位后解除', (tester) async {
    await pumpApp(tester);

    await tapVisible(tester, find.byKey(const Key('emergency-button')));
    await tester.pump();

    expect(controller.currentStatus.state, RobotState.emergency);
    expect(find.text('WARN-004'), findsOneWidget);
    expect(find.text('紧急停止已锁定，请先复位'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('reset-button')));
    await tester.pump();

    expect(controller.currentStatus.state, RobotState.idle);
    expect(find.text('WARN-004'), findsNothing);
  });

  testWidgets('语音控制面板显示解析与执行结果', (tester) async {
    await pumpApp(tester);

    await tapVisible(tester, find.byKey(const Key('voice-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('voice-command-input')),
      '开始清扫C区',
    );
    await tester.tap(find.byKey(const Key('execute-voice-command-button')));
    await tester.pump();

    expect(find.text('解析结果：start / C区'), findsOneWidget);
    expect(find.textContaining('执行成功'), findsOneWidget);
    expect(controller.currentStatus.area, 'C区');
    expect(controller.currentStatus.state, RobotState.cleaning);
  });

  testWidgets('Demo 低电量经 WarningService 显示 WARN-002', (tester) async {
    await pumpApp(tester);

    await tapVisible(tester, find.byKey(const Key('demo-fault-panel')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('fault-低电量')));
    await tester.pump();

    expect(controller.currentStatus.battery, 9);
    expect(find.text('WARN-002'), findsOneWidget);
    expect(find.text('电量过低，禁止开始任务'), findsOneWidget);
  });

  testWidgets('360x800 无布局异常且核心按钮可滚动访问', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('voice-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('emergency-button')), findsOneWidget);
    expect(find.byKey(const Key('voice-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
