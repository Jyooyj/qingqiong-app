import 'package:flutter/foundation.dart';

import '../../services/voice_control_service.dart';

/// 可替换的语音输入边界。
///
/// Adapter 只负责取得识别文本，所有命令解析、权限检查和状态变更仍由
/// [VoiceControlService] 及其下游完成。
abstract class SpeechInputAdapter extends ChangeNotifier {
  SpeechInputAdapter({required this.voiceControlService});

  final VoiceControlService voiceControlService;

  bool get isAvailable;

  String get statusMessage;

  Future<String> capture({String? fallbackText});

  Future<VoiceExecutionResult> execute({String? fallbackText}) async {
    final text = await capture(fallbackText: fallbackText);
    return voiceControlService.execute(text);
  }
}
