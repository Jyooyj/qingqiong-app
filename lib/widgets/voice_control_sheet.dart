import 'package:flutter/material.dart';

import '../services/voice_control_service.dart';
import '../adapters/speech/speech_input_adapter.dart';
import '../adapters/speech/speech_to_text_adapter.dart';
import '../data/campus/campus_map_data.dart';
import '../data/campus_geo/campus_geo_map_data.dart';

class VoiceControlSheet extends StatefulWidget {
  const VoiceControlSheet({
    super.key,
    required this.service,
    this.speechAdapter,
  });

  final VoiceControlService service;
  final SpeechInputAdapter? speechAdapter;

  @override
  State<VoiceControlSheet> createState() => _VoiceControlSheetState();
}

class _VoiceControlSheetState extends State<VoiceControlSheet> {
  final TextEditingController _textController = TextEditingController();
  VoiceExecutionResult? _result;
  late final SpeechInputAdapter _speech;
  SpeechToTextAdapter? get _speechToText => switch (_speech) {
    SpeechToTextAdapter value => value,
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    _speech =
        widget.speechAdapter ??
        SpeechToTextAdapter(voiceControlService: widget.service);
  }

  static const List<String> _examples = <String>[
    '去实验楼清扫',
    '开始',
    '暂停',
    '继续',
    '返回充电',
    '紧急停止',
    '复位',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _speechToText?.disposeAdapter();
    super.dispose();
  }

  void _execute() {
    final result = widget.service.execute(_textController.text);
    setState(() => _result = result);
  }

  Future<void> _toggleMicrophone() async {
    final speech = _speechToText;
    if (speech != null) {
      await speech.toggle(
        onResult: (text) {
          _textController.text = text;
          _textController.selection = TextSelection.collapsed(
            offset: text.length,
          );
        },
      );
    } else {
      try {
        final text = await _speech.capture();
        if (text.isNotEmpty) _textController.text = text;
      } catch (_) {
        // The adapter owns permission/platform error state; text input remains available.
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.mic_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '自然语言控制',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '支持自然语言控制，系统会识别任务意图并经过安全校验后执行。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _speech,
              builder: (context, _) {
                final listening = _speechToText?.isListening == true;
                return TextField(
                  key: const Key('voice-command-input'),
                  controller: _textController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _execute(),
                  decoration: InputDecoration(
                    labelText: '输入任务指令',
                    hintText: '例如：去实验楼清扫',
                    prefixIcon: Icon(Icons.record_voice_over_outlined),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.35),
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: IconButton(
                      key: const Key('microphone-input-button'),
                      tooltip: listening ? '停止录音' : '使用麦克风输入',
                      onPressed: _toggleMicrophone,
                      icon: Icon(
                        listening
                            ? Icons.stop_circle_outlined
                            : Icons.mic_none_rounded,
                      ),
                    ),
                  ),
                );
              },
            ),
            /*
            if (false)
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  key: const Key('microphone-input-button-visible'),
                  onPressed: _toggleMicrophone,
                  icon: Icon(
                    _speechToText?.isListening == true
                        ? Icons.stop_circle_outlined
                        : Icons.mic_none_rounded,
                  ),
                  label: Text(
                    _speechToText?.isListening == true ? '停止录音' : '录音输入',
                  ),
                ),
              ),
            if (false && _speechToText != null)
              AnimatedBuilder(
                animation: _speechToText!,
                builder: (context, _) {
                  final speech = _speechToText!;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(
                          speech.isListening ? Icons.mic : Icons.mic_none,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            speech.statusMessage,
                            key: const Key('microphone-status'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            */
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _examples
                  .asMap()
                  .entries
                  .map(
                    (entry) => ActionChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: entry.key == 5
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: entry.key == 5
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      label: Text(entry.value),
                      onPressed: () {
                        _textController.text = entry.value;
                        _textController.selection = TextSelection.collapsed(
                          offset: entry.value.length,
                        );
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                key: const Key('execute-voice-command-button'),
                onPressed: _execute,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.send_rounded),
                label: const Text('执行命令'),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 14),
              _VoiceResultCard(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _VoiceResultCard extends StatelessWidget {
  const _VoiceResultCard({required this.result});

  final VoiceExecutionResult result;

  String get _description {
    final area = result.area;
    final name = area == null
        ? null
        : CampusGeoMapData.findZoneById(area)?.name ??
              CampusMapData.findZoneById(area)?.name ??
              (const ['A区', 'B区', 'C区'].contains(area) ? area : null);
    return switch (result.command) {
      'start' => name == null ? '开始清扫' : '前往$name清扫',
      'pause' => '暂停任务',
      'resume' => '继续任务',
      'stop' => '停止任务',
      'charge' => '返回充电',
      'emergencyStop' => '紧急停止',
      'reset' => '解除急停',
      _ => '任务指令',
    };
  }

  @override
  Widget build(BuildContext context) {
    final success = result.success;
    final recognized = result.recognized;
    final color = success
        ? Colors.green.shade800
        : recognized
        ? Colors.orange.shade900
        : Colors.red.shade800;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '输入文本：${result.inputText}',
              key: const Key('voice-input-result'),
            ),
            const SizedBox(height: 5),
            Text(
              recognized ? '已识别：$_description' : '未执行',
              key: const Key('voice-parse-result'),
            ),
            const SizedBox(height: 5),
            Text(
              '${success ? '执行成功' : '未执行，原因'}：${result.resultMessage}',
              key: const Key('voice-execution-result'),
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
