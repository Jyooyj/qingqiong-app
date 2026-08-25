import 'speech_input_adapter.dart';

/// 始终可用的文字输入方案，也是麦克风不可用时的稳定降级路径。
class TextFallbackAdapter extends SpeechInputAdapter {
  TextFallbackAdapter({required super.voiceControlService});

  @override
  bool get isAvailable => true;

  @override
  String get statusMessage => '文字输入可用';

  @override
  Future<String> capture({String? fallbackText}) async {
    if (fallbackText == null) {
      throw ArgumentError.notNull('fallbackText');
    }
    return fallbackText;
  }
}
