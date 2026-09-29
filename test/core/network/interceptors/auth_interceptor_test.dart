import 'dart:typed_data';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenStorage extends Mock implements TokenStorage;

/// Faux serveur : mémorise la dernière requête reçue.
class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '{}',
      200,
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

  late _MockTokenStorage tokens;
  late _CaptureAdapter adapter;
  late Dio dio;

  setUp(() {
    tokens = _MockTokenStorage();
    adapter = _CaptureAdapter();
    dio = Dio(BaseOptions(baseUrl: apiBaseUrl.toString()))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        AuthInterceptor(tokenStorage: tokens, apiBaseUrl: apiBaseUrl),
      );

    when(() => tokens.readAccessToken())
        .thenAnswer((_) async => const Ok<String?>('TOKEN'));
  });

  String? authHeader() =>
      adapter.lastRequest?.headers['Authorization'] as String?;

  group('AuthInterceptor', () {
    test('ajoute le token sur une route protégée', () async {
      await dio.get<void>(ApiEndpoints.me);

      expect(authHeader(), 'Bearer TOKEN');
    });

    test('n’ajoute pas de token sur les routes publiques', () async {
      await dio.post<void>(ApiEndpoints.login);
      expect(authHeader(), isNull);

      await dio.post<void>(ApiEndpoints.refreshToken);
      expect(authHeader(), isNull);
    });

    test('n’envoie jamais le token vers un autre serveur', () async {
      await dio.get<void>('https://autre-site.example.org/image.png');

      expect(authHeader(), isNull);
    });

    test('n’envoie pas le token en HTTP si l’API est en HTTPS', () async {
      await dio.get<void>('http://api.example.com/api/auth/me');

      expect(authHeader(), isNull);
    });

    test('respecte skipAuth', () async {
      await dio.get<void>(
        ApiEndpoints.me,
        options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
      );

      expect(authHeader(), isNull);
    });

    test('pas d’en-tête si aucun token n’est stocké', () async {
      when(() => tokens.readAccessToken())
          .thenAnswer((_) async => const Ok<String?>(null));

      await dio.get<void>(ApiEndpoints.me);

      expect(authHeader(), isNull);
    });

    test('pas d’en-tête si le stockage est en erreur', () async {
      when(() => tokens.readAccessToken())
          .thenAnswer((_) async => const Err<String?>(StorageFailure()));

      await dio.get<void>(ApiEndpoints.me);

      expect(authHeader(), isNull);
    });
  });
}
