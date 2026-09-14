import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/pages/profile_page.dart';

void main() {
  Future<void> pumpProfilePage(
    WidgetTester tester, {
    bool demoModeEnabled = true,
    ValueChanged<bool>? onDemoModeChanged,
    VoidCallback? onVoiceSettingsTap,
    VoidCallback? onAboutTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          deviceName: '清穹一号',
          deviceId: 'QQ-RC-001',
          softwareVersion: 'V1.0.0',
          connectionStatusText: '已连接',
          demoModeEnabled: demoModeEnabled,
          onDemoModeChanged: onDemoModeChanged,
          onVoiceSettingsTap: onVoiceSettingsTap,
          onAboutTap: onAboutTap,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('displays profile title and device info', (tester) async {
    await pumpProfilePage(tester);

    expect(find.text('我的 / 设置'), findsOneWidget);
    expect(find.text('清穹一号'), findsOneWidget);
    expect(find.textContaining('QQ-RC-001'), findsOneWidget);
    expect(find.text('V1.0.0'), findsOneWidget);
    expect(find.text('已连接'), findsOneWidget);
  });

  testWidgets('displays demo mode card and description', (tester) async {
    await pumpProfilePage(tester);

    expect(find.text('演示模式'), findsOneWidget);
    expect(find.text('当前状态：已开启'), findsOneWidget);
    expect(find.text('使用演示数据展示任务、轨迹与告警'), findsOneWidget);
    expect(find.byKey(const Key('profile-demo-mode')), findsOneWidget);
    expect(find.byKey(const Key('profile-demo-mode-switch')), findsOneWidget);
  });

  testWidgets('demo mode switch fires callback with bool', (tester) async {
    bool? lastValue;

    await pumpProfilePage(
      tester,
      demoModeEnabled: false,
      onDemoModeChanged: (value) => lastValue = value,
    );

    final switchFinder = find.byKey(const Key('profile-demo-mode-switch'));
    await tester.ensureVisible(switchFinder);
    await tester.pumpAndSettle();
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(lastValue, isTrue);
  });

  testWidgets('demo mode switch is disabled when callback is missing', (
    tester,
  ) async {
    await pumpProfilePage(tester, onDemoModeChanged: null);

    final switchFinder = find.byKey(const Key('profile-demo-mode-switch'));
    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.onChanged, isNull);
  });

  testWidgets('voice settings tap triggers callback', (tester) async {
    bool didTap = false;
    await pumpProfilePage(tester, onVoiceSettingsTap: () => didTap = true);

    expect(find.textContaining('自然语言指令'), findsOneWidget);
    expect(find.textContaining('文字输入'), findsOneWidget);

    final voiceTile = find.byKey(const Key('profile-voice-settings'));
    await tester.ensureVisible(voiceTile);
    await tester.pumpAndSettle();
    await tester.tap(voiceTile);
    await tester.pumpAndSettle();

    expect(didTap, isTrue);
  });

  testWidgets('about tap triggers callback or dialog fallback', (tester) async {
    bool didTap = false;
    await pumpProfilePage(tester, onAboutTap: () => didTap = true);

    final aboutButton = find.byKey(const Key('profile-about'));
    await tester.ensureVisible(aboutButton);
    await tester.pumpAndSettle();
    await tester.tap(aboutButton);
    await tester.pumpAndSettle();

    expect(didTap, isTrue);

    await pumpProfilePage(tester, onAboutTap: null);
    await tester.ensureVisible(find.byKey(const Key('profile-about')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-about')));
    await tester.pumpAndSettle();

    final dialogFinder = find.byType(AlertDialog);
    expect(dialogFinder, findsOneWidget);

    final titleFinder = find.descendant(
      of: dialogFinder,
      matching: find.text('关于清穹'),
    );
    expect(titleFinder, findsOneWidget);

    final productFinder = find.descendant(
      of: dialogFinder,
      matching: find.text('清穹无人清扫车'),
    );
    expect(productFinder, findsWidgets);
  });

  testWidgets('responsive layout stays stable on common sizes', (tester) async {
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

      await pumpProfilePage(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final headerBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
      final deviceTop = tester
          .getTopLeft(find.byKey(const Key('profile-device-info')))
          .dy;
      expect(
        deviceTop - headerBottom,
        inInclusiveRange(16, 24),
        reason: 'Device card should sit directly below the header at $size',
      );

      await tester.ensureVisible(find.byKey(const Key('profile-demo-mode')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('profile-voice-settings')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('profile-about')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
