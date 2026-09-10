import 'speech_input_adapter.dart';

/// Web 麦克风占位边界。
///
/// V1 未引入浏览器语音识别依赖，因此不会伪报麦克风可用；调用方应使用
/// [TextFallbackAdapter]。后续实现可在不改变业务链路的情况下替换本类。
class BrowserSpeechAdapter extends SpeechInputAdapter {
  BrowserSpeechAdapter({required super.voiceControlService});

  @override
  bool get isAvailable => false;

  @override
  String get statusMessage => '浏览器麦克风识别尚未接入，请使用文字输入';

  @override
  Future<String> capture({String? fallbackText}) {
    throw UnsupportedError(statusMessage);
  }
}
