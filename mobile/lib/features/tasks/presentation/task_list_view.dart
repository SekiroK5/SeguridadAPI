/// Displays task-list states and task completion controls.
library;

import 'package:flutter/material.dart';

import '../domain/task.dart';

/// Renders an asynchronous task-list result.
class TaskListView extends StatelessWidget {
  /// Creates a task list view.
  const TaskListView({
    super.key,
    required this.loading,
    required this.tasks,
    required this.errorMessage,
    required this.onRetry,
    required this.onToggle,
    required this.onDelete,
  });

  /// Whether the repository is loading tasks.
  final bool loading;

  /// Tasks to display after a successful load.
  final List<Task> tasks;

  /// Safe error message, if the request failed.
  final String? errorMessage;

  /// Callback to retry loading.
  final VoidCallback onRetry;

  /// Callback for completion changes.
  final ValueChanged<Task> onToggle;

  /// Callback for deletion.
  final ValueChanged<Task> onDelete;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks yet. Add your first task.'));
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          leading: Checkbox(
            value: task.completed,
            onChanged: (_) => onToggle(task),
          ),
          title: Text(
            task.title,
            style: task.completed
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: task.description == null ? null : Text(task.description!),
          trailing: IconButton(
            tooltip: 'Delete task',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => onDelete(task),
          ),
        );
      },
    );
  }
}
