import 'dart:convert';
import 'dart:typed_data';

import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/network/interceptors/safe_log_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Faux serveur : renvoie des tokens (qui ne doivent JAMAIS être loggés).
class _FakeServer implements HttpClientAdapter {
  int status = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'message': 'Login successful',
        'user': {'email': 'test@afrimarket.com'},
        'accessToken': 'SECRET-ACCESS',
        'refreshToken': 'SECRET-REFRESH',
      }),
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
  late List<String> logs;
  late _FakeServer server;
  late Dio dio;

  setUp(() {
    logs = [];
    server = _FakeServer();
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
      ..httpClientAdapter = server
      ..interceptors.add(SafeLogInterceptor(sink: logs.add));
  });

  group('SafeLogInterceptor.redact', () {
    test('masque les clés sensibles à tous les niveaux', () {
      final redacted = SafeLogInterceptor.redact({
        'email': 'a@b.c',
        'password': 'P@ss',
        'nested': {'accessToken': 'A', 'name': 'Mohamed'},
        'list': [
          {'refreshToken': 'R', 'id': 1},
        ],
      });

      expect(redacted, {
        'email': 'a@b.c',
        'password': '***',
        'nested': {'accessToken': '***', 'name': 'Mohamed'},
        'list': [
          {'refreshToken': '***', 'id': 1},
        ],
      });
    });

    test('le masquage ignore la casse', () {
      final redacted = SafeLogInterceptor.redact({'RecaptchaTOKEN': 'x'});

      expect(redacted, {'RecaptchaTOKEN': '***'});
    });
  });

  group('SafeLogInterceptor', () {
    test('aucun secret n’apparaît dans les logs', () async {
      await dio.post<void>(
        ApiEndpoints.login,
        data: {
          'email': 'test@afrimarket.com',
          'password': 'P@ssw0rd!',
          'recaptchaToken': 'SECRET-CAPTCHA',
        },
        options: Options(headers: {'Authorization': 'Bearer SECRET-HEADER'}),
      );

      final all = logs.join('\n');
      expect(all, contains('/api/auth/login'));
      expect(all, contains('200'));
      expect(all, isNot(contains('SECRET')));
      expect(all, isNot(contains('P@ssw0rd!')));
    });

    test('les paramètres d’URL sensibles sont masqués', () async {
      await dio.get<void>(
        '/api/search',
        queryParameters: {'q': 'iphone', 'token': 'SECRET-QUERY'},
      );

      final all = logs.join('\n');
      expect(all, contains('q=iphone'));
      expect(all, contains('token=***'));
      expect(all, isNot(contains('SECRET')));
    });

    test('les erreurs sont journalisées sans secret', () async {
      server.status = 401;

      await expectLater(
        dio.get<void>(ApiEndpoints.me),
        throwsA(isA<DioException>()),
      );

      final all = logs.join('\n');
      expect(all, contains('✗ 401'));
      expect(all, isNot(contains('SECRET')));
    });

    test('un formulaire multipart n’est jamais affiché', () async {
      final form = FormData.fromMap({
        'documentNumber': 'AB123456',
        'documentType': 'PASSPORT',
      });

      await dio.post<void>('/api/identity/upload', data: form);

      final all = logs.join('\n');
      expect(all, contains('[multipart'));
      expect(all, isNot(contains('AB123456')));
      expect(all, isNot(contains('PASSPORT')));
    });
  });
}
