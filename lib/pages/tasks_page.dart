import 'package:flutter/material.dart';

import '../widgets/tasks/task_view_data.dart';
import '../widgets/tasks/task_card.dart';
import '../widgets/tasks/task_filter_bar.dart';
import '../widgets/tasks/new_task_form.dart';
import '../widgets/tasks/task_detail_view.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({
    super.key,
    this.tasks,
    this.onCreate,
    this.onExecute,
    this.onPause,
    this.onResume,
    this.onStop,
  });

  final List<TaskViewData>? tasks;
  final void Function(TaskViewData)? onCreate;
  final void Function(TaskViewData)? onExecute;
  final void Function(TaskViewData)? onPause;
  final void Function(TaskViewData)? onResume;
  final void Function(TaskViewData)? onStop;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  String _filter = 'all';
  TaskViewData? _selected;
  bool _showNewForm = false;

  @override
  void didUpdateWidget(covariant TasksPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = _selected;
    if (selected == null || widget.tasks == null) {
      return;
    }
    for (final task in widget.tasks!) {
      if (task.id == selected.id) {
        _selected = task;
        return;
      }
    }
    _selected = null;
  }

  List<TaskViewData> get _source => widget.tasks ?? const <TaskViewData>[];

  List<TaskViewData> get _filtered {
    if (_filter == 'all') return _source;
    return _source.where((t) => t.status == _filter).toList();
  }

  void _onFilterChanged(String f) => setState(() {
    _filter = f;
    _selected = null;
    _showNewForm = false;
  });

  void _openDetail(TaskViewData t) => setState(() {
    _selected = t;
    _showNewForm = false;
  });

  void _openNew() => setState(() {
    _showNewForm = true;
    _selected = null;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务中心')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;
            final padding = desktop ? 20.0 : 12.0;
            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: desktop ? 1080 : double.infinity,
                ),
                child: desktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _buildListColumn(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(width: 380, child: _buildSideColumn()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ..._buildListColumn(),
                          const SizedBox(height: 12),
                          if (_showNewForm) ...[
                            NewTaskForm(
                              onSave: widget.onCreate,
                              onExecute: widget.onExecute,
                            ),
                          ] else if (_selected != null) ...[
                            TaskDetailView(
                              task: _selected!,
                              onExecute: widget.onExecute,
                              onPause: widget.onPause,
                              onResume: widget.onResume,
                              onStop: widget.onStop,
                            ),
                          ] else
                            ..._buildSideColumnWidgets(),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _showNewForm
          ? null
          : FloatingActionButton(
              key: const Key('open-new-task'),
              onPressed: _openNew,
              child: const Icon(Icons.add),
            ),
    );
  }

  List<Widget> _buildListColumn() {
    return [
      TaskFilterBar(current: _filter, onChanged: _onFilterChanged),
      const SizedBox(height: 12),
      if (_filtered.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            _source.isEmpty ? '暂无清扫任务，可通过自然语言控制或 + 创建任务' : '暂无符合筛选条件的任务',
          ),
        ),
      ..._filtered.map((t) => TaskCard(task: t, onTap: () => _openDetail(t))),
    ];
  }

  Widget _buildSideColumn() {
    if (_showNewForm) {
      return NewTaskForm(onSave: widget.onCreate, onExecute: widget.onExecute);
    }
    if (_selected != null) {
      return TaskDetailView(
        task: _selected!,
        onExecute: widget.onExecute,
        onPause: widget.onPause,
        onResume: widget.onResume,
        onStop: widget.onStop,
      );
    }
    return Column(children: _buildSideColumnWidgets());
  }

  List<Widget> _buildSideColumnWidgets() {
    return [
      const SizedBox(height: 12),
      const Text('选择任务查看详情', style: TextStyle(fontWeight: FontWeight.w700)),
    ];
  }
}
