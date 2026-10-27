/// Holds task-list state outside of widgets.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../domain/task.dart';

/// Immutable snapshot of the task list screen.
class TaskState {
  /// Creates a task state.
  const TaskState({this.loading = false, this.tasks = const [], this.errorMessage});

  /// Whether tasks are being loaded.
  final bool loading;

  /// Tasks from the last successful load.
  final List<Task> tasks;

  /// Safe error message from the last failed operation.
  final String? errorMessage;
}

/// Loads and mutates the signed-in user's tasks.
class TaskController extends Notifier<TaskState> {
  @override
  TaskState build() {
    Future.microtask(load);
    return const TaskState(loading: true);
  }

  /// Loads the first page of tasks.
  Future<void> load() async {
    state = const TaskState(loading: true);
    try {
      final tasks = await ref.read(taskRepositoryProvider).list();
      state = TaskState(tasks: tasks);
    } on ApiException catch (error) {
      state = TaskState(errorMessage: error.message);
    }
  }

  /// Creates a task and prepends it to the list.
  Future<String?> add(String title, String? description) async {
    try {
      final task = await ref.read(taskRepositoryProvider).create(title, description);
      state = TaskState(tasks: [task, ...state.tasks]);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// Flips a task's completion state.
  Future<void> toggle(Task task) async {
    try {
      final updated =
          await ref.read(taskRepositoryProvider).setCompleted(task, !task.completed);
      state = TaskState(
        tasks: [for (final t in state.tasks) t.id == updated.id ? updated : t],
      );
    } on ApiException catch (error) {
      state = TaskState(errorMessage: error.message);
    }
  }

  /// Deletes a task from the server and the list.
  Future<void> delete(Task task) async {
    try {
      await ref.read(taskRepositoryProvider).delete(task.id);
      state = TaskState(tasks: state.tasks.where((t) => t.id != task.id).toList());
    } on ApiException catch (error) {
      state = TaskState(errorMessage: error.message);
    }
  }
}

/// Task-list state for the signed-in user.
final tasksProvider = NotifierProvider.autoDispose<TaskController, TaskState>(
  TaskController.new,
);
