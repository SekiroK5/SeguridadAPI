/// In-memory token store for tests.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/storage/token_store.dart';

/// Records saved tokens without touching platform storage.
class FakeTokenStore extends TokenStore {
  /// Creates a fake store with an optional initial token pair.
  FakeTokenStore({this.accessToken, this.refreshToken})
      : super(const FlutterSecureStorage());

  /// Current access token.
  String? accessToken;

  /// Current refresh token.
  String? refreshToken;

  /// Last access token passed to [saveTokens].
  String? savedAccessToken;

  /// Last refresh token passed to [saveTokens].
  String? savedRefreshToken;

  /// Whether [clear] was called.
  bool cleared = false;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens(String access, String refresh) async {
    accessToken = savedAccessToken = access;
    refreshToken = savedRefreshToken = refresh;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    accessToken = null;
    refreshToken = null;
  }
}
