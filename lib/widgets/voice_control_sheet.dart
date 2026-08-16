import 'package:flutter/material.dart';

import '../services/voice_control_service.dart';

class VoiceControlSheet extends StatefulWidget {
  const VoiceControlSheet({super.key, required this.service});

  final VoiceControlService service;

  @override
  State<VoiceControlSheet> createState() => _VoiceControlSheetState();
}

class _VoiceControlSheetState extends State<VoiceControlSheet> {
  final TextEditingController _textController = TextEditingController();
  VoiceExecutionResult? _result;

  static const List<String> _examples = <String>[
    '开始清扫A区',
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
    super.dispose();
  }

  void _execute() {
    final result = widget.service.execute(_textController.text);
    setState(() => _result = result);
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
                const Icon(Icons.mic_rounded),
                const SizedBox(width: 8),
                Text(
                  '语音控制台',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '比赛现场稳定模式：输入识别文本，完整经过解析器、状态机与安全预警。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('voice-command-input'),
              controller: _textController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _execute(),
              decoration: const InputDecoration(
                labelText: '识别 / 输入文本',
                hintText: '例如：开始清扫A区',
                prefixIcon: Icon(Icons.record_voice_over_outlined),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _examples
                  .map(
                    (example) => ActionChip(
                      label: Text(example),
                      onPressed: () {
                        _textController.text = example;
                        _textController.selection = TextSelection.collapsed(
                          offset: example.length,
                        );
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                key: const Key('execute-voice-command-button'),
                onPressed: _execute,
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
              recognized
                  ? '解析结果：${result.command}${result.area == null ? '' : ' / ${result.area}'}'
                  : '解析结果：无法识别',
              key: const Key('voice-parse-result'),
            ),
            const SizedBox(height: 5),
            Text(
              '${success
                  ? '执行成功'
                  : recognized
                  ? '执行被拒绝'
                  : '未执行'}：${result.resultMessage}',
              key: const Key('voice-execution-result'),
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
