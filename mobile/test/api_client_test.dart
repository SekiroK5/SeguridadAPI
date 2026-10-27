/// Verifies one refresh followed by one retry using MockClient.
library;
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/tasks/data/task_repository.dart';

import 'fake_token_store.dart';

void main() {
  test('refreshes once on 401 and retries the original request once', () async {
    var originalCalls = 0;
    var refreshCalls = 0;
    final mock = MockClient((request) async {
      if (request.url.path.endsWith('/auth/refresh')) {
        refreshCalls++;
        return http.Response(jsonEncode({
          'accessToken': 'new-access',
          'refreshToken': 'new-refresh',
        }), 200);
      }
      originalCalls++;
      if (originalCalls == 1) return http.Response('{}', 401);
      expect(request.headers['authorization'], 'Bearer new-access');
      return http.Response(jsonEncode({'items': []}), 200);
    });
    final tokens = FakeTokenStore(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    final client = ApiClient(mock, tokens);

    await client.send('GET', 'tasks');

    expect(refreshCalls, 1);
    expect(originalCalls, 2);
    expect(tokens.savedAccessToken, 'new-access');
    expect(tokens.savedRefreshToken, 'new-refresh');
  });

  test('failed refresh clears tokens, signals expiry and does not retry', () async {
    var originalCalls = 0;
    var expired = false;
    final mock = MockClient((request) async {
      if (request.url.path.endsWith('/auth/refresh')) return http.Response('{}', 401);
      originalCalls++;
      return http.Response('{}', 401);
    });
    final tokens = FakeTokenStore(accessToken: 'a', refreshToken: 'r');
    final client = ApiClient(mock, tokens, onSessionExpired: () => expired = true);

    await expectLater(client.send('GET', 'tasks'), throwsA(isA<ApiException>()));
    expect(originalCalls, 1);
    expect(tokens.cleared, isTrue);
    expect(expired, isTrue);
  });

  test('concurrent 401s share a single refresh (single-flight)', () async {
    var refreshCalls = 0;
    final mock = MockClient((request) async {
      if (request.url.path.endsWith('/auth/refresh')) {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response(jsonEncode({'accessToken': 'n', 'refreshToken': 'm'}), 200);
      }
      if (request.headers['authorization'] == 'Bearer n') {
        return http.Response(jsonEncode({'items': []}), 200);
      }
      return http.Response('{}', 401);
    });
    final client = ApiClient(mock, FakeTokenStore(accessToken: 'o', refreshToken: 'r'));

    await Future.wait([client.send('GET', 'tasks'), client.send('GET', 'tasks')]);
    expect(refreshCalls, 1);
  });

  test('errors never expose tokens or raw server bodies', () async {
    final mock = MockClient((request) async =>
        http.Response('{"stack":"PrismaClientKnownRequestError at secret-token"}', 500));
    final client = ApiClient(mock, FakeTokenStore(accessToken: 'secret-token', refreshToken: 'r'));

    try {
      await client.send('GET', 'tasks');
      fail('expected ApiException');
    } on ApiException catch (error) {
      expect(error.toString(), isNot(contains('secret-token')));
      expect(error.toString(), isNot(contains('Prisma')));
      expect(error.statusCode, 500);
    }
  });

  test('timeouts and network failures become a safe message', () async {
    final mock = MockClient((request) async => throw const SocketLikeException());
    final client = ApiClient(mock, FakeTokenStore());

    await expectLater(
      client.send('GET', 'tasks'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('Could not connect'))),
    );
  });

  group('TaskRepository', () {
    test('parses tasks and keeps the query string intact', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, endsWith('/tasks'));
        expect(request.url.queryParameters, {'page': '1', 'limit': '20'});
        return http.Response(jsonEncode({
          'items': [
            {'id': 'c1', 'title': 'One', 'description': null, 'completed': false},
            {'id': 'c2', 'title': 'Two', 'description': 'd', 'completed': true},
          ],
        }), 200);
      });
      final tasks = await TaskRepository(ApiClient(mock, FakeTokenStore(accessToken: 'a'))).list();
      expect(tasks.map((t) => t.title), ['One', 'Two']);
      expect(tasks.last.completed, isTrue);
    });

    test('returns an empty list', () async {
      final mock = MockClient((request) async => http.Response(jsonEncode({'items': []}), 200));
      final tasks = await TaskRepository(ApiClient(mock, FakeTokenStore(accessToken: 'a'))).list();
      expect(tasks, isEmpty);
    });

    test('never sends an ownerId when creating a task', () async {
      final mock = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('ownerId'), isFalse);
        return http.Response(jsonEncode({
          'item': {'id': 'c3', 'title': body['title'], 'description': null, 'completed': false},
        }), 201);
      });
      final task = await TaskRepository(ApiClient(mock, FakeTokenStore(accessToken: 'a')))
          .create('  Trim me  ', null);
      expect(task.title, 'Trim me');
    });
  });
}

/// Simulates a low-level connection failure.
class SocketLikeException implements Exception {
  /// Creates the exception.
  const SocketLikeException();
}
