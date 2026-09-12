import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/main.dart';
import 'package:robot_cleaner/services/product_session.dart';
import 'package:robot_cleaner/widgets/dashboard/recent_alert_card.dart';
import 'package:robot_cleaner/widgets/voice_control_sheet.dart';

void main() {
  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    testWidgets('home summary and expanded faults fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = ProductSession();
      await tester.pumpWidget(QingQiongApp(session: s));
      final card = find.byType(RecentAlertCard);
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      expect(tester.getSize(card).width, size.width - 24);
      expect(
        find.descendant(of: card, matching: find.text('暂无告警')),
        findsOneWidget,
      );
      expect(tester.getSize(card).height, lessThan(140));
      s.robotController.setPathBlocked(true);
      await tester.pump();
      expect(
        find.descendant(of: card, matching: find.text('WARN-007')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('路径阻塞')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.textContaining('待处理')),
        findsOneWidget,
      );
      s.acknowledgeWarning(s.warningHistory.currentWarnings.single.id);
      await tester.pump();
      expect(
        find.descendant(of: card, matching: find.textContaining('已确认')),
        findsOneWidget,
      );
      s.robotController.setPathBlocked(false);
      await tester.pump();
      expect(
        find.descendant(of: card, matching: find.textContaining('已解决')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.textContaining('待处理')),
        findsNothing,
      );
      final code = tester.widget<Text>(
        find.descendant(of: card, matching: find.text('WARN-007')),
      );
      expect(
        code.style!.color,
        isNot(Theme.of(tester.element(card)).colorScheme.error),
      );
      final time = s.warningHistory.allRecords.single.occurredAt;
      expect(
        find.textContaining(
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        ),
        findsWidgets,
      );
      final faults = find.byKey(const Key('demo-fault-panel'));
      await tester.ensureVisible(faults);
      await tester.tap(faults);
      await tester.pumpAndSettle();
      final clear = find.text('清除全部异常');
      await tester.ensureVisible(clear);
      expect(clear, findsOneWidget);
      expect(find.text('异常模拟'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        expect(text.data ?? '', isNot(contains('WarningService')));
        expect(text.data ?? '', isNot(contains('Demo 故障')));
      }
      await tester.ensureVisible(card);
      await tester.tap(
        find.descendant(of: card, matching: find.text('查看全部 ›')),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      s.dispose();
    });
  }
  testWidgets(
    'voice shows Chinese feedback and rejects unsafe or unknown destinations',
    (tester) async {
      final s = ProductSession();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceControlSheet(service: s.voiceControlService),
          ),
        ),
      );
      expect(find.text('自然语言控制'), findsOneWidget);
      expect(find.text('开始清扫A区'), findsNothing);
      final input = find.byKey(const Key('voice-command-input'));
      final execute = find.byKey(const Key('execute-voice-command-button'));
      await tester.enterText(input, '去第一食堂清扫');
      await tester.ensureVisible(execute);
      await tester.tap(execute);
      await tester.pump();
      expect(find.text('已识别：前往第一食堂清扫'), findsOneWidget);
      expect(find.textContaining('执行成功：'), findsOneWidget);
      s.stopCurrentTask();
      for (final text in ['不要去实验楼清扫', '可以去实验楼清扫吗', '去一餐还是二教清扫', '去未知地点清扫']) {
        await tester.enterText(input, text);
        await tester.ensureVisible(execute);
        await tester.tap(execute);
        await tester.pump();
        expect(find.textContaining('未执行，原因：'), findsOneWidget);
        expect(s.taskController.activeTask, isNull);
      }
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        expect(text.data ?? '', isNot(contains('lab_building')));
        expect(text.data ?? '', isNot(contains('canteen_1')));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      s.dispose();
    },
  );
}
