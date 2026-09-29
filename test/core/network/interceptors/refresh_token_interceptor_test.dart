import 'dart:convert';
import 'dart:typed_data';

import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:afrimarket_mobile/core/network/interceptors/refresh_token_interceptor.dart';
import 'package:afrimarket_mobile/core/storage/secure_storage.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stockage sécurisé simulé en mémoire.
class _InMemorySecureStorage extends Fake implements SecureStorage {
  final values = <String, String>{};

  @override
  Future<Result<String?>> read(String key) async => Ok(values[key]);

  @override
  Future<Result<void>> write({
    required String key,
    required String value,
  }) async {
    values[key] = value;
    return const Ok(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    values.remove(key);
    return const Ok(null);
  }
}

/// Faux backend AfriMarket.
class _FakeServer implements HttpClientAdapter {
  int refreshCalls = 0;
  int refreshStatus = 200;
  bool refreshNetworkError = false;
  bool rejectAllTokens = false;
  String? rotatedRefreshToken;
  String validAccessToken = 'NEW';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;

    if (path == ApiEndpoints.refreshToken) {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (refreshNetworkError) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      if (refreshStatus != 200) {
        return _json({'error': 'Invalid refresh token'}, refreshStatus);
      }
      return _json({
        'accessToken': validAccessToken,
        'refreshToken': ?rotatedRefreshToken,
      }, 200);
    }

    if (path == ApiEndpoints.me) {
      final authorized =
          !rejectAllTokens &&
          options.headers['Authorization'] == 'Bearer $validAccessToken';
      return authorized
          ? _json({'user': 'ok'}, 200)
          : _json({'error': 'expired'}, 401);
    }

    return _json({'error': 'Invalid credentials'}, 401);
  }

  ResponseBody _json(Map<String, Object?> body, int status) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final apiBaseUrl = Uri.parse('https://api.example.com');

  late TokenStorage tokens;
  late _FakeServer server;
  late Dio dio;
  late int expiredCalls;

  Future<String?> readAccess() async {
    return switch (await tokens.readAccessToken()) {
      Ok(:final value) => value,
      Err() => null,
    };
  }

  Future<String?> readRefresh() async {
    return switch (await tokens.readRefreshToken()) {
      Ok(:final value) => value,
      Err() => null,
    };
  }

  setUp(() async {
    tokens = TokenStorage(_InMemorySecureStorage());
    await tokens.saveTokens(accessToken: 'OLD', refreshToken: 'R1');

    server = _FakeServer();
    expiredCalls = 0;

    final refreshDio = Dio(BaseOptions(baseUrl: apiBaseUrl.toString()))
      ..httpClientAdapter = server;
    dio = Dio(BaseOptions(baseUrl: apiBaseUrl.toString()))
      ..httpClientAdapter = server;
    dio.interceptors.addAll([
      AuthInterceptor(tokenStorage: tokens, apiBaseUrl: apiBaseUrl),
      RefreshTokenInterceptor(
        dio: dio,
        refreshDio: refreshDio,
        tokenStorage: tokens,
        apiBaseUrl: apiBaseUrl,
        onSessionExpired: () => expiredCalls++,
      ),
    ]);
  });

  group('RefreshTokenInterceptor', () {
    test('un 401 déclenche un refresh puis rejoue la requête', () async {
      final response = await dio.get<Map<String, dynamic>>(ApiEndpoints.me);

      expect(response.statusCode, 200);
      expect(server.refreshCalls, 1);
      expect(await readAccess(), 'NEW');
      expect(await readRefresh(), 'R1');
    });

    test('plusieurs 401 simultanés : un seul refresh', () async {
      final responses = await Future.wait([
        dio.get<Map<String, dynamic>>(ApiEndpoints.me),
        dio.get<Map<String, dynamic>>(ApiEndpoints.me),
        dio.get<Map<String, dynamic>>(ApiEndpoints.me),
      ]);

      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(server.refreshCalls, 1);
    });

    test('refresh refusé : session expirée et tokens effacés', () async {
      server.refreshStatus = 401;

      await expectLater(
        dio.get<void>(ApiEndpoints.me),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
      expect(expiredCalls, 1);
      expect(await readAccess(), isNull);
      expect(await readRefresh(), isNull);
    });

    test('coupure réseau pendant le refresh : session conservée', () async {
      server.refreshNetworkError = true;

      await expectLater(
        dio.get<void>(ApiEndpoints.me),
        throwsA(isA<DioException>()),
      );
      expect(expiredCalls, 0);
      expect(await readRefresh(), 'R1');
    });

    test('sans refresh token : session expirée, aucun appel serveur', () async {
      await tokens.clear();

      await expectLater(
        dio.get<void>(ApiEndpoints.me),
        throwsA(isA<DioException>()),
      );
      expect(server.refreshCalls, 0);
      expect(expiredCalls, 1);
    });

    test('rotation : le nouveau refresh token est enregistré', () async {
      server.rotatedRefreshToken = 'R2';

      await dio.get<void>(ApiEndpoints.me);

      expect(await readRefresh(), 'R2');
    });

    test('un 401 sur une route publique ne déclenche rien', () async {
      await expectLater(
        dio.post<void>(ApiEndpoints.login),
        throwsA(isA<DioException>()),
      );
      expect(server.refreshCalls, 0);
      expect(expiredCalls, 0);
    });

    test('pas de boucle : un 401 après refresh est renvoyé', () async {
      server.rejectAllTokens = true;

      await expectLater(
        dio.get<void>(ApiEndpoints.me),
        throwsA(isA<DioException>()),
      );
      expect(server.refreshCalls, 1);
    });
  });
}
