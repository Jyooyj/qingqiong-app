import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/models/cleaning_task.dart';
import 'package:robot_cleaner/models/robot_status.dart';
import 'package:robot_cleaner/services/product_session.dart';

void main() {
  test('fresh ProductSession starts clean with no task or route', () {
    final session = ProductSession();
    addTearDown(session.dispose);
    expect(session.robotController.currentStatus.online, isTrue);
    expect(session.robotController.currentStatus.state, RobotState.idle);
    expect(session.robotController.currentStatus.progress, 0);
    expect(session.currentTask, isNull);
    expect(session.taskController.activeTask, isNull);
    expect(session.warningHistory.currentWarnings, isEmpty);
    expect(session.campusCoordinator.geoPlannedPath, isEmpty);
    expect(session.campusCoordinator.geoProgress, 0);
  });

  test('a completed task does not seed a later fresh session', () {
    final first = ProductSession();
    first.startOrCreateTask(area: 'A区');
    first.taskController.completeTask(first.currentTask!.id);
    first.dispose();
    final fresh = ProductSession();
    addTearDown(fresh.dispose);
    expect(fresh.taskController.tasks, isEmpty);
    expect(fresh.currentTask, isNull);
    expect(fresh.robotController.currentStatus.state, RobotState.idle);
    expect(
      fresh.taskController.tasks.where(
        (t) => t.status == CleaningTaskStatus.running,
      ),
      isEmpty,
    );
  });
}
