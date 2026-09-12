import 'package:flutter/material.dart';
import 'task_view_data.dart';

class NewTaskForm extends StatefulWidget {
  const NewTaskForm({super.key, this.onSave, this.onExecute});

  final void Function(TaskViewData)? onSave;
  final void Function(TaskViewData)? onExecute;

  @override
  State<NewTaskForm> createState() => _NewTaskFormState();
}

class _NewTaskFormState extends State<NewTaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  String _area = 'A区';
  String _mode = '标准';

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  TaskViewData _buildData() => TaskViewData(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: _nameCtl.text.trim().isEmpty ? '新任务' : _nameCtl.text.trim(),
    area: _area,
    status: 'pending',
    progress: 0,
    timeText: '计划: 现在',
    mode: _mode,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('新建任务', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('new-task-name'),
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: '任务名称'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('new-task-area'),
                      initialValue: _area,
                      items: const [
                        DropdownMenuItem(value: 'A区', child: Text('A区')),
                        DropdownMenuItem(value: 'B区', child: Text('B区')),
                        DropdownMenuItem(value: 'C区', child: Text('C区')),
                      ],
                      onChanged: (v) => setState(() => _area = v ?? 'A区'),
                      decoration: const InputDecoration(labelText: '区域'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('new-task-mode'),
                      initialValue: _mode,
                      items: const [
                        DropdownMenuItem(value: '标准', child: Text('标准')),
                        DropdownMenuItem(value: '深度', child: Text('深度')),
                        DropdownMenuItem(value: '快速', child: Text('快速')),
                      ],
                      onChanged: (v) => setState(() => _mode = v ?? '标准'),
                      decoration: const InputDecoration(labelText: '模式'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: const Key('save-task-button'),
                      onPressed: widget.onSave == null
                          ? null
                          : () {
                              final data = _buildData();
                              widget.onSave?.call(data);
                            },
                      child: const Text('保存任务'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('execute-task-button'),
                      onPressed: widget.onExecute == null
                          ? null
                          : () {
                              final data = _buildData();
                              widget.onExecute?.call(data);
                            },
                      child: const Text('立即执行'),
                    ),
                  ),
                ],
              ),
              if (widget.onSave == null && widget.onExecute == null) ...[
                const SizedBox(height: 8),
                const Text('等待TaskController接入', key: Key('task-form-waiting')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
