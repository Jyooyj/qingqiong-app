import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/adapters/speech/browser_speech_adapter.dart';
import 'package:robot_cleaner/adapters/speech/native_speech_adapter.dart';
import 'package:robot_cleaner/adapters/speech/text_fallback_adapter.dart';
import 'package:robot_cleaner/controllers/robot_controller.dart';
import 'package:robot_cleaner/models/robot_status.dart';
import 'package:robot_cleaner/services/voice_control_service.dart';

void main() {
  RobotController createController() => RobotController(
    autoProgress: false,
    initialStatus: const RobotStatus(
      robotId: 'R-SPEECH',
      robotName: '输入测试车',
      online: true,
      battery: 80,
      state: RobotState.idle,
      area: 'B区',
      progress: 0,
    ),
  );

  test('TextFallbackAdapter 将文字交给 VoiceControlService', () async {
    final controller = createController();
    final adapter = TextFallbackAdapter(
      voiceControlService: VoiceControlService(controller: controller),
    );
    addTearDown(controller.dispose);

    final result = await adapter.execute(fallbackText: '去C区打扫');

    expect(adapter.isAvailable, isTrue);
    expect(result.success, isTrue);
    expect(controller.currentStatus.state, RobotState.cleaning);
    expect(controller.currentStatus.area, 'C区');
  });

  test('浏览器与原生占位不伪报麦克风可用', () {
    final controller = createController();
    final service = VoiceControlService(controller: controller);
    final browser = BrowserSpeechAdapter(voiceControlService: service);
    final native = NativeSpeechAdapter(voiceControlService: service);
    addTearDown(controller.dispose);

    expect(browser.isAvailable, isFalse);
    expect(native.isAvailable, isFalse);
    expect(() => browser.capture(), throwsA(isA<UnsupportedError>()));
    expect(() => native.capture(), throwsA(isA<UnsupportedError>()));
  });
}
