/// Wires storage, networking, and repositories with Riverpod.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../features/auth/data/auth_repository.dart';
import '../features/tasks/data/task_repository.dart';
import 'network/api_client.dart';
import 'storage/token_store.dart';

/// Whether a user session is known to exist on this device.
enum AuthStatus { unknown, signedIn, signedOut }

/// Tracks the signed-in state of the application.
class AuthStateNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    _restore();
    return AuthStatus.unknown;
  }

  Future<void> _restore() async {
    final refreshToken = await ref.read(tokenStoreProvider).readRefreshToken();
    state = refreshToken == null ? AuthStatus.signedOut : AuthStatus.signedIn;
  }

  /// Marks the session as active after a successful login or registration.
  void signIn() => state = AuthStatus.signedIn;

  /// Returns the application to the login screen.
  void signOut() => state = AuthStatus.signedOut;
}

/// Platform secure storage (Keystore-backed on Android, Keychain on iOS).
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Token persistence used by the API client and auth repository.
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(ref.read(secureStorageProvider)),
);

/// Current authentication state.
final authStateProvider = NotifierProvider<AuthStateNotifier, AuthStatus>(
  AuthStateNotifier.new,
);

/// Shared HTTP client that refreshes tokens and signs out when refresh fails.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(http.Client(), ref.read(tokenStoreProvider),
      onSessionExpired: () => ref.read(authStateProvider.notifier).signOut());
});

/// Authentication operations.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider), ref.read(tokenStoreProvider)),
);

/// Task operations.
final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.read(apiClientProvider)),
);
