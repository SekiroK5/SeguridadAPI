/// Implements task operations using the remote Task Manager API.
library;

import '../../../core/network/api_client.dart';
import '../domain/task.dart';

/// Separates UI state management from HTTP details.
class TaskRepository {
  /// Creates a repository using [client].
  TaskRepository(this._client);

  final ApiClient _client;

  /// Fetches one page of the current user's tasks.
  ///
  /// Returns the tasks in the API response.
  Future<List<Task>> list({int page = 1, int limit = 20}) async {
    final result = await _client.send(
      'GET',
      'tasks?page=$page&limit=$limit',
    );
    final items = result['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => Task.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Creates a task using its editable fields.
  Future<Task> create(String title, String? description) async {
    final trimmed = description?.trim();
    final result = await _client.send('POST', 'tasks', body: {
      'title': title.trim(),
      if (trimmed != null && trimmed.isNotEmpty) 'description': trimmed,
    });
    return Task.fromJson(result['item'] as Map<String, dynamic>);
  }

  /// Updates a task's completion state.
  Future<Task> setCompleted(Task task, bool completed) async {
    final result = await _client.send(
      'PATCH',
      'tasks/${Uri.encodeComponent(task.id)}',
      body: {'completed': completed},
    );
    return Task.fromJson(result['item'] as Map<String, dynamic>);
  }

  /// Deletes a task by its identifier.
  Future<void> delete(String taskId) async {
    await _client.send('DELETE', 'tasks/${Uri.encodeComponent(taskId)}');
  }
}
