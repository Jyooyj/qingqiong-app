import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/services/task_statistics_formatter.dart';
import 'package:robot_cleaner/widgets/tasks/task_detail_view.dart';
import 'package:robot_cleaner/widgets/tasks/task_view_data.dart';

void main() {
  test('area uses grouped metres or two-decimal hectares at the threshold', () {
    expect(TaskStatisticsFormatter.area(4422), '4,422 m²');
    expect(TaskStatisticsFormatter.area(9999), '9,999 m²');
    expect(TaskStatisticsFormatter.area(10000), '1.00 公顷');
    expect(TaskStatisticsFormatter.area(12500), '1.25 公顷');
    expect(TaskStatisticsFormatter.area(0), '0 m²');
    expect(TaskStatisticsFormatter.area(double.nan), '—');
  });
  test('duration preserves total minutes and seconds', () {
    expect(
      TaskStatisticsFormatter.duration(
        const Duration(minutes: 14, seconds: 23),
      ),
      '14 分 23 秒',
    );
    expect(
      TaskStatisticsFormatter.duration(const Duration(hours: 1, seconds: 3)),
      '60 分 3 秒',
    );
    expect(TaskStatisticsFormatter.duration(Duration.zero), '0 分 0 秒');
  });
  testWidgets('task details render the shared area and duration formats', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskDetailView(
            task: TaskViewData(
              id: 'format',
              name: 'test',
              area: 'test',
              status: 'completed',
              progress: 100,
              timeText: '',
              cleanedArea: 4422,
              durationText: TaskStatisticsFormatter.duration(
                const Duration(minutes: 14, seconds: 23),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('4,422 m²'), findsOneWidget);
    expect(find.textContaining('14 分 23 秒'), findsOneWidget);
  });
}
