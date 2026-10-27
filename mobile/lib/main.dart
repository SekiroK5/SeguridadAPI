/// Entry point for the Secure Task Manager Flutter client.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/tasks/presentation/task_page.dart';

void main() {
  runApp(const ProviderScope(child: TaskManagerApp()));
}

/// Root widget that switches between login and tasks based on auth state.
class TaskManagerApp extends ConsumerWidget {
  /// Creates the application.
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authStateProvider);
    return MaterialApp(
      title: 'Secure Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: switch (status) {
        AuthStatus.unknown => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        AuthStatus.signedIn => const TaskPage(),
        AuthStatus.signedOut => const LoginPage(),
      },
    );
  }
}
