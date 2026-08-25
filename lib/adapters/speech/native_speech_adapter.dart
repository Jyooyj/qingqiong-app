import 'speech_input_adapter.dart';

/// 原生平台麦克风占位边界，V1 不伪造真实语音能力。
class NativeSpeechAdapter extends SpeechInputAdapter {
  NativeSpeechAdapter({required super.voiceControlService});

  @override
  bool get isAvailable => false;

  @override
  String get statusMessage => '原生麦克风识别尚未接入，请使用文字输入';

  @override
  Future<String> capture({String? fallbackText}) {
    throw UnsupportedError(statusMessage);
  }
}
