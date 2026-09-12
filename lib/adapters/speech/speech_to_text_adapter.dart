import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'speech_input_adapter.dart';

enum SpeechCaptureState { idle, listening, unavailable, error }

/// Real microphone/ASR adapter. It only returns text; command execution stays
/// in VoiceControlService, preserving the existing safety and parser chain.
class SpeechToTextAdapter extends SpeechInputAdapter {
  SpeechToTextAdapter({
    required super.voiceControlService,
    stt.SpeechToText? engine,
  }) : _engine = engine ?? stt.SpeechToText();

  final stt.SpeechToText _engine;
  SpeechCaptureState _state = SpeechCaptureState.idle;
  String _recognizedText = '';
  String? _error;
  bool _initialized = false;

  SpeechCaptureState get state => _state;
  String get recognizedText => _recognizedText;
  String? get errorMessage => _error;
  bool get isListening => _state == SpeechCaptureState.listening;
  @override
  bool get isAvailable => _initialized && _engine.isAvailable;
  @override
  String get statusMessage {
    if (_state == SpeechCaptureState.listening) return '正在录音，请说出控制指令';
    if (_state == SpeechCaptureState.error) return _error ?? '语音识别失败，请使用文字输入';
    if (_state == SpeechCaptureState.unavailable) return '麦克风或语音识别不可用，请检查权限';
    return isAvailable ? '点击麦克风开始说话' : '点击麦克风请求权限';
  }

  Future<bool> initialize() async {
    try {
      _initialized = await _engine.initialize(
        onError: (error) {
          _error = error.errorMsg;
          _state = SpeechCaptureState.error;
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'notListening' &&
              _state == SpeechCaptureState.listening) {
            _state = SpeechCaptureState.idle;
            notifyListeners();
          }
        },
      );
      if (!_initialized || !_engine.isAvailable) {
        _state = SpeechCaptureState.unavailable;
      }
      notifyListeners();
      return isAvailable;
    } catch (error) {
      _error = '无法访问麦克风：$error';
      _state = SpeechCaptureState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggle({required ValueChanged<String> onResult}) async {
    if (isListening) {
      await _engine.stop();
      _state = SpeechCaptureState.idle;
      notifyListeners();
      return;
    }
    _error = null;
    if (!isAvailable && !await initialize()) return;
    _recognizedText = '';
    _state = SpeechCaptureState.listening;
    notifyListeners();
    try {
      await _engine.listen(
        listenOptions: stt.SpeechListenOptions(localeId: 'zh_CN'),
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          onResult(_recognizedText);
          notifyListeners();
          if (result.finalResult) {
            _state = SpeechCaptureState.idle;
            notifyListeners();
          }
        },
      );
    } catch (error) {
      _error = '无法开始录音：$error';
      _state = SpeechCaptureState.error;
      notifyListeners();
    }
  }

  @override
  Future<String> capture({String? fallbackText}) async {
    if (!isAvailable && !await initialize()) {
      throw UnsupportedError(statusMessage);
    }
    final done = Completer<String>();
    _state = SpeechCaptureState.listening;
    await _engine.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: 'zh_CN',
        listenFor: Duration(seconds: 8),
      ),
      onResult: (result) {
        _recognizedText = result.recognizedWords;
        if (result.finalResult && !done.isCompleted) {
          done.complete(_recognizedText);
        }
      },
    );
    final text = await done.future.timeout(
      const Duration(seconds: 9),
      onTimeout: () => _recognizedText,
    );
    await _engine.stop();
    _state = SpeechCaptureState.idle;
    notifyListeners();
    return text;
  }

  Future<void> disposeAdapter() async {
    await _engine.cancel();
    dispose();
  }
}
