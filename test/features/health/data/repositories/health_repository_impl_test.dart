import 'dart:convert';
import 'dart:typed_data';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:afrimarket_mobile/features/health/data/datasources/health_remote_datasource.dart';
import 'package:afrimarket_mobile/features/health/data/repositories/health_repository_impl.dart';
import 'package:afrimarket_mobile/features/health/domain/entities/health_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenStorage extends Mock implements TokenStorage;

/// Faux backend : réponse configurable, mémorise la dernière requête.
class _FakeServer implements HttpClientAdapter {
  int status = 200;
  String body = jsonEncode({
    'status': 'ok',
    'database': 'connected',
    'websocket': 'active',
  });
  bool timeout = false;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (timeout) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      );
    }
    return ResponseBody.fromString(
      body,
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

  late _FakeServer server;
  late HealthRepositoryImpl repository;

  setUp(() {
    server = _FakeServer();

    final tokens = _MockTokenStorage();
    when(tokens.readAccessToken)
        .thenAnswer((_) async => const Ok<String?>('TOKEN'));

    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl.toString()))
      ..httpClientAdapter = server
      ..interceptors.add(
        AuthInterceptor(tokenStorage: tokens, apiBaseUrl: apiBaseUrl),
      );

    repository = HealthRepositoryImpl(HealthRemoteDataSource(dio));
  });

  group('HealthRepositoryImpl', () {
    test('renvoie l’état de santé', () async {
      final result = await repository.check();

      expect(
        (result as Ok<HealthStatus>).value,
        const HealthStatus(
          status: 'ok',
          database: 'connected',
          websocket: 'active',
        ),
      );
    });

    test('n’envoie jamais de token sur la route publique', () async {
      await repository.check();

      expect(server.lastRequest?.headers['Authorization'], isNull);
    });

    test('erreur serveur : ServerFailure', () async {
      server.status = 503;

      final result = await repository.check();

      expect((result as Err<HealthStatus>).failure, isA<ServerFailure>());
    });

    test('délai dépassé : TimeoutFailure', () async {
      server.timeout = true;

      final result = await repository.check();

      expect((result as Err<HealthStatus>).failure, isA<TimeoutFailure>());
    });

    test('réponse inattendue : UnexpectedFailure', () async {
      server.body = jsonEncode({'status': 'ok'});

      final result = await repository.check();

      expect((result as Err<HealthStatus>).failure, isA<UnexpectedFailure>());
    });
  });
}
