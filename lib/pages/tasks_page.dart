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
    this.onSelectCampusArea,
  });

  final List<TaskViewData>? tasks;
  final void Function(TaskViewData)? onCreate;
  final void Function(TaskViewData)? onExecute;
  final void Function(TaskViewData)? onPause;
  final void Function(TaskViewData)? onResume;
  final void Function(TaskViewData)? onStop;
  final VoidCallback? onSelectCampusArea;

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

  Future<void> _openNew() async {
    setState(() {
      _showNewForm = false;
      _selected = null;
    });
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: NewTaskForm(
            onSave: widget.onCreate,
            onExecute: widget.onExecute,
          ),
        ),
      ),
    );
  }

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
      floatingActionButton: FloatingActionButton(
        key: const Key('open-new-task'),
        onPressed: widget.onSelectCampusArea ?? _openNew,
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
        onExecute: widget.onExecute,
        onPause: widget.onPause,
        onResume: widget.onResume,
        onStop: widget.onStop,
      );
    }
    return Column(children: _buildSideColumnWidgets());
  }

  List<Widget> _buildSideColumnWidgets() {
    if (_filtered.isEmpty) {
      final emptyLabel = switch (_filter) {
        'pending' => '暂无待执行的任务',
        'running' => '暂无执行中的任务',
        'paused' => '暂无已暂停的任务',
        'cancelled' => '暂无已停止的任务',
        'completed' => '暂无已完成的任务',
        'failed' => '暂无失败的任务',
        _ => '暂无任务',
      };
      return [
        const SizedBox(height: 28),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emptyLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '切换筛选条件查看其他任务',
                style: TextStyle(fontSize: 13, color: Color(0xFF64727D)),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      const SizedBox(height: 12),
      const Center(
        child: Text('选择任务查看详情', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ];
  }
}
