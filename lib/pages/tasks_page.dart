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

  List<TaskViewData> get _source => widget.tasks ?? _sampleData();

  List<TaskViewData> get _filtered {
    if (_filter == 'all') return _source;
    return _source.where((t) => t.status == _filter).toList();
  }

  List<TaskViewData> _sampleData() => [
    TaskViewData(
      id: '1',
      name: '入口走廊清扫',
      area: 'A区',
      status: 'pending',
      progress: 0,
      timeText: '计划: 今天 09:00',
      mode: '标准',
    ),
    TaskViewData(
      id: '2',
      name: '会议室深度清洁',
      area: 'B区',
      status: 'running',
      progress: 48,
      timeText: '开始: 08:23',
      mode: '深度',
      cleanedArea: 12.4,
      durationText: '00:21:12',
      startTimeText: '08:23',
    ),
    TaskViewData(
      id: '3',
      name: '储物间快速清扫',
      area: 'C区',
      status: 'completed',
      progress: 100,
      timeText: '开始: 07:00',
      mode: '快速',
      cleanedArea: 5.2,
      durationText: '00:12:34',
      startTimeText: '07:00',
    ),
    TaskViewData(
      id: '4',
      name: '库房问题处理',
      area: 'A区',
      status: 'failed',
      progress: 20,
      timeText: '计划: 今天 10:00',
      mode: '标准',
    ),
  ];

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
      floatingActionButton: FloatingActionButton(
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
