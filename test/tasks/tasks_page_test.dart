import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/widgets/tasks/task_view_data.dart';
import 'package:robot_cleaner/widgets/tasks/task_card.dart';
import 'package:robot_cleaner/widgets/tasks/task_detail_view.dart';
import 'package:robot_cleaner/pages/tasks_page.dart';

void main() {
  testWidgets('Task UI: filters exist and filter works', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TasksPage(
          tasks: [
            TaskViewData(
              id: '2',
              name: '测试',
              area: '实验楼',
              status: 'running',
              progress: 48,
              timeText: '',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // filter chips
    expect(find.byKey(const Key('filter-all')), findsOneWidget);
    expect(find.byKey(const Key('filter-pending')), findsOneWidget);
    expect(find.byKey(const Key('filter-running')), findsOneWidget);
    expect(find.byKey(const Key('filter-completed')), findsOneWidget);
    expect(find.byKey(const Key('filter-failed')), findsOneWidget);

    // default shows some task cards
    expect(find.byType(TaskCard), findsWidgets);

    // tap running filter and expect only running tasks shown
    await tester.tap(find.byKey(const Key('filter-running')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('task-card-2')), findsOneWidget);
    expect(find.byKey(const Key('task-card-1')), findsNothing);
    expect(find.byKey(const Key('task-card-3')), findsNothing);
    expect(find.byKey(const Key('task-card-4')), findsNothing);
  });

  testWidgets('New task form input and callbacks', (tester) async {
    TaskViewData? saved;
    TaskViewData? executed;
    await tester.pumpWidget(
      MaterialApp(
        home: TasksPage(
          onCreate: (t) => saved = t,
          onExecute: (t) => executed = t,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // open form via FAB
    await tester.tap(find.byKey(const Key('open-new-task')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('new-task-name')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('new-task-name')), '测试任务');
    await tester.ensureVisible(find.byKey(const Key('new-task-area')));
    await tester.tap(find.byKey(const Key('new-task-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B区').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('new-task-mode')));
    await tester.tap(find.byKey(const Key('new-task-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('深度').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();
    expect(saved, isNotNull);
    expect(saved!.name, '测试任务');
    expect(saved!.mode, '深度');

    await tester.tap(find.byKey(const Key('execute-task-button')));
    await tester.pumpAndSettle();
    expect(executed, isNotNull);
    expect(executed!.mode, '深度');
  });

  testWidgets('Task detail shows correct buttons for statuses', (tester) async {
    final running = TaskViewData(
      id: 'r',
      name: 'R',
      area: 'A区',
      status: 'running',
      progress: 50,
      timeText: '',
    );
    final paused = TaskViewData(
      id: 'p',
      name: 'P',
      area: 'B区',
      status: 'paused',
      progress: 50,
      timeText: '',
    );
    final done = TaskViewData(
      id: 'd',
      name: 'D',
      area: 'C区',
      status: 'completed',
      progress: 100,
      timeText: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                TaskCard(task: running),
                TaskDetailView(task: running),
                TaskDetailView(task: paused),
                TaskDetailView(task: done),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail-pause')), findsOneWidget);
    expect(find.byKey(const Key('detail-stop')), findsWidgets);
    expect(find.byKey(const Key('detail-resume')), findsOneWidget);
    // completed has no control buttons
    expect(find.text('任务已完成'), findsOneWidget);
  });
  testWidgets(
    'Detail callbacks receive correct TaskViewData and completed shows no controls',
    (tester) async {
      TaskViewData? pausedTaskCaptured;
      TaskViewData? resumedTaskCaptured;
      TaskViewData? stoppedTaskCaptured;

      final running = TaskViewData(
        id: 'r',
        name: 'R',
        area: 'A区',
        status: 'running',
        progress: 50,
        timeText: '',
        mode: '深度',
      );
      final paused = TaskViewData(
        id: 'p',
        name: 'P',
        area: 'B区',
        status: 'paused',
        progress: 50,
        timeText: '',
        mode: '标准',
      );
      final done = TaskViewData(
        id: 'd',
        name: 'D',
        area: 'C区',
        status: 'completed',
        progress: 100,
        timeText: '',
        mode: '快速',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TasksPage(
            tasks: [running, paused, done],
            onPause: (t) => pausedTaskCaptured = t,
            onResume: (t) => resumedTaskCaptured = t,
            onStop: (t) => stoppedTaskCaptured = t,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // open running task detail and pause
      await tester.ensureVisible(find.byKey(const Key('task-card-r')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('task-card-r')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail-pause')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('detail-pause')));
      await tester.tap(find.byKey(const Key('detail-pause')));
      await tester.pumpAndSettle();
      expect(pausedTaskCaptured?.id, 'r');

      // open paused task detail and resume
      await tester.ensureVisible(find.byKey(const Key('task-card-p')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('task-card-p')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail-resume')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('detail-resume')));
      await tester.tap(find.byKey(const Key('detail-resume')));
      await tester.pumpAndSettle();
      expect(resumedTaskCaptured?.id, 'p');

      // stop action available for paused/running
      await tester.ensureVisible(find.byKey(const Key('task-card-r')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('task-card-r')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('detail-stop')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail-stop')));
      await tester.pumpAndSettle();
      expect(stoppedTaskCaptured, isNotNull);

      // completed shows finished text and no control buttons
      await tester.ensureVisible(find.byKey(const Key('task-card-d')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('task-card-d')));
      await tester.pumpAndSettle();
      expect(find.text('任务已完成'), findsOneWidget);
      expect(find.byKey(const Key('detail-pause')), findsNothing);
      expect(find.byKey(const Key('detail-resume')), findsNothing);
    },
  );

  testWidgets('Responsive: 360x800 no overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: TasksPage(
          tasks: [
            TaskViewData(
              id: '2',
              name: '会议室深度清洁',
              area: '实验楼',
              status: 'running',
              progress: 48,
              timeText: '',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // tap a task card to show detail
    await tester.ensureVisible(find.byKey(const Key('task-card-2')));
    await tester.tap(find.byKey(const Key('task-card-2')));
    await tester.pumpAndSettle();
    expect(find.text('会议室深度清洁'), findsWidgets);

    // tap FAB to open new form
    await tester.tap(find.byKey(const Key('open-new-task')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('new-task-name')), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Filter change clears selected detail and shows placeholder (desktop)',
    (tester) async {
      // desktop viewport
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final completed = TaskViewData(
        id: 'c',
        name: 'Completed Task',
        area: 'X',
        status: 'completed',
        progress: 100,
        timeText: '',
      );
      final pending = TaskViewData(
        id: 'p',
        name: 'Pending Task',
        area: 'Y',
        status: 'pending',
        progress: 0,
        timeText: '',
      );

      await tester.pumpWidget(
        MaterialApp(home: TasksPage(tasks: [completed, pending])),
      );
      await tester.pumpAndSettle();

      // show completed filter and open completed task
      await tester.ensureVisible(find.byKey(const Key('filter-completed')));
      await tester.tap(find.byKey(const Key('filter-completed')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('task-card-c')));
      await tester.tap(find.byKey(const Key('task-card-c')));
      await tester.pumpAndSettle();
      expect(find.byType(TaskDetailView), findsOneWidget);
      expect(find.text('Completed Task'), findsWidgets);

      // switch to pending filter -> selected should be cleared and placeholder shown
      await tester.ensureVisible(find.byKey(const Key('filter-pending')));
      await tester.tap(find.byKey(const Key('filter-pending')));
      await tester.pumpAndSettle();

      expect(find.byType(TaskDetailView), findsNothing);
      expect(find.text('Completed Task'), findsNothing);
      expect(find.text('选择任务查看详情'), findsOneWidget);

      // now tap pending task and ensure detail shows
      await tester.ensureVisible(find.byKey(const Key('task-card-p')));
      await tester.tap(find.byKey(const Key('task-card-p')));
      await tester.pumpAndSettle();
      expect(find.byType(TaskDetailView), findsOneWidget);
      expect(find.text('Pending Task'), findsWidgets);
    },
  );
}
