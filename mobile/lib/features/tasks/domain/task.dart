/// Defines the task data used by the Flutter application.
library;

/// Represents a task owned by the signed-in user.
class Task {
  /// Creates a task value.
  ///
  /// [id] is the server-generated task identifier.
  /// [title] is the task title.
  /// [description] is optional detail.
  /// [completed] indicates whether the task is complete.
  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.completed,
  });

  /// Server-generated task identifier.
  final String id;

  /// Short task title.
  final String title;

  /// Optional task details.
  final String? description;

  /// Completion state.
  final bool completed;

  /// Creates a task from the API JSON response.
  ///
  /// [json] is a decoded task object.
  /// Returns the parsed task.
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      completed: json['completed'] as bool,
    );
  }

  /// Converts editable fields into a request payload.
  ///
  /// Returns only task fields accepted by the API.
  Map<String, dynamic> toWriteJson() => {
        'title': title,
        'description': description,
        'completed': completed,
      };
}
