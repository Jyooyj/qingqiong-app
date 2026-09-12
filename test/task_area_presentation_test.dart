import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/widgets/tasks/task_view_data.dart';

void main() {
  TaskViewData task(String id, String area) => TaskViewData(
    id: id,
    name: 'test',
    area: area,
    campusZoneId: id,
    status: 'completed',
    progress: 100,
    timeText: '',
  );

  test('campus zone IDs resolve to building names', () {
    expect(task('lab_building', 'lab_building').presentationArea, '实验楼');
    expect(
      task('information_college', 'information_college').presentationArea,
      '信息学院',
    );
  });

  test('custom area IDs resolve to the generic custom area label', () {
    expect(task('custom-123', 'custom-123').presentationArea, '自定义清扫区域');
  });

  test('unknown IDs never appear as the area label', () {
    expect(task('unknown-zone', 'unknown-zone').presentationArea, '校园区域');
    expect(task('unknown-zone', '人工指定区域').presentationArea, '人工指定区域');
  });
}
