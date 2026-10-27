/// Screen that lists, creates, completes, and deletes the user's tasks.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/task.dart';
import 'task_controller.dart';
import 'task_list_view.dart';

/// Main task screen for a signed-in user.
class TaskPage extends ConsumerWidget {
  /// Creates the task page.
  const TaskPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tasksProvider);
    final controller = ref.read(tasksProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My tasks'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: controller.load,
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              ref.read(authStateProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: TaskListView(
        loading: state.loading,
        tasks: state.tasks,
        errorMessage: state.errorMessage,
        onRetry: controller.load,
        onToggle: controller.toggle,
        onDelete: (task) => _confirmDelete(context, controller, task),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, controller),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TaskController controller,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.delete(task);
  }

  Future<void> _showCreateDialog(BuildContext context, TaskController controller) {
    return showDialog<void>(
      context: context,
      builder: (context) => _CreateTaskDialog(controller: controller),
    );
  }
}

class _CreateTaskDialog extends StatefulWidget {
  const _CreateTaskDialog({required this.controller});

  final TaskController controller;

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.controller.add(_title.text, _description.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New task'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('taskTitle'),
              controller: _title,
              autofocus: true,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Title is required.' : null,
            ),
            TextFormField(
              key: const Key('taskDescription'),
              controller: _description,
              maxLength: 2000,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
