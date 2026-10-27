/// Implements login, registration, and best-effort logout with the API.
library;

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_store.dart';

/// Coordinates authentication requests and local token persistence.
class AuthRepository {
  /// Creates a repository using [client] and [tokens].
  AuthRepository(this._client, this._tokens);

  final ApiClient _client;
  final TokenStore _tokens;

  /// Logs in and persists the returned access and refresh tokens.
  Future<void> login(String email, String password) async {
    final result = await _client.send('POST', 'auth/login', body: {
      'email': email,
      'password': password,
    });
    await _savePair(result);
  }

  /// Registers an account and persists its returned token pair.
  Future<void> register(String email, String password) async {
    final result = await _client.send('POST', 'auth/register', body: {
      'email': email,
      'password': password,
    });
    await _savePair(result);
  }

  Future<void> _savePair(Map<String, dynamic> result) async {
    final accessToken = result['accessToken'];
    final refreshToken = result['refreshToken'];
    if (accessToken is! String || refreshToken is! String) {
      throw const ApiException('The server returned unexpected data.');
    }
    await _tokens.saveTokens(accessToken, refreshToken);
  }

  /// Attempts server-side logout and always clears local tokens.
  Future<void> logout() async {
    try {
      final refreshToken = await _tokens.readRefreshToken();
      if (refreshToken != null) {
        await _client.send('POST', 'auth/logout', body: {
          'refreshToken': refreshToken,
        });
      }
    } on ApiException {
      // Local logout still proceeds when the server cannot be reached.
    } finally {
      await _tokens.clear();
    }
  }
}
