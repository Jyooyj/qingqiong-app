import '../models/cleaning_task.dart';

abstract class TaskRepository {
  Future<List<CleaningTask>> getAll();

  Future<void> save(CleaningTask task);

  Future<void> delete(String id);
}

class InMemoryTaskRepository implements TaskRepository {
  final List<CleaningTask> _tasks = [];

  @override
  Future<List<CleaningTask>> getAll() async {
    return List.unmodifiable(_tasks);
  }

  @override
  Future<void> save(CleaningTask task) async {
    final index = _tasks.indexWhere(
      (existingTask) => existingTask.id == task.id,
    );

    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
  }

  @override
  Future<void> delete(String id) async {
    _tasks.removeWhere((task) => task.id == id);
  }
}
