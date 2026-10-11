import 'dart:convert';
import 'dart:typed_data';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:afrimarket_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:afrimarket_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:afrimarket_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenStorage extends Mock implements TokenStorage;

/// Faux backend : une réponse par route, mémorise les requêtes reçues.
class _FakeServer implements HttpClientAdapter {
  final responses = <String, (int, Object?)>{};
  final requests = <RequestOptions>[];
  bool offline = false;

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final (status, body) = responses[options.path] ?? (404, null);
    return ResponseBody.fromString(
      jsonEncode(body ?? const <String, Object?>{}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _user = AuthUser(
  id: 'u1',
  email: 'awa@example.com',
  username: 'awa',
  fullName: 'Awa Traoré',
);

Map<String, Object?> _session() => {
  'user': {
    'id': 'u1',
    'email': 'awa@example.com',
    'username': 'awa',
    'fullName': 'Awa Traoré',
  },
  'accessToken': 'ACCESS',
  'refreshToken': 'REFRESH',
};

void main() {
  final apiBaseUrl = Uri.parse('https://api.example.com');

  late _FakeServer server;
  late _MockTokenStorage tokens;
  late AuthRepositoryImpl repository;

  setUp(() {
    server = _FakeServer();
    tokens = _MockTokenStorage();
    when(
      () => tokens.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async => const Ok<void>(null));
    when(() => tokens.clear()).thenAnswer((_) async => const Ok<void>(null));
    when(() => tokens.readAccessToken())
        .thenAnswer((_) async => const Ok<String?>('OLD-ACCESS'));

    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl.toString()))
      ..httpClientAdapter = server
      ..interceptors.add(
        AuthInterceptor(tokenStorage: tokens, apiBaseUrl: apiBaseUrl),
      );
    repository = AuthRepositoryImpl(AuthRemoteDataSource(dio), tokens);
  });

  group('connexion', () {
    test('succès : tokens enregistrés, utilisateur renvoyé', () async {
      server.responses[ApiEndpoints.login] = (200, _session());

      final result = await repository.login(
        email: 'awa@example.com',
        password: 'Abc-1234',
      );

      expect((result as Ok<AuthUser>).value, _user);
      expect(server.last.data, {
        'email': 'awa@example.com',
        'password': 'Abc-1234',
      });
      verify(
        () => tokens.saveTokens(accessToken: 'ACCESS', refreshToken: 'REFRESH'),
      ).called(1);
    });

    test('route publique : aucun token envoyé', () async {
      server.responses[ApiEndpoints.login] = (200, _session());

      await repository.login(email: 'awa@example.com', password: 'x');

      expect(server.last.headers['Authorization'], isNull);
    });

    test(
      'identifiants refusés : UnauthorizedFailure, rien enregistré',
      () async {
        server.responses[ApiEndpoints.login] = (
          401,
          {'error': 'Invalid credentials'},
        );

        final result = await repository.login(email: 'a@b.co', password: 'x');

        expect((result as Err<AuthUser>).failure, isA<UnauthorizedFailure>());
        verifyNever(
          () => tokens.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ),
        );
      },
    );

    test('réponse sans token : UnexpectedFailure, rien enregistré', () async {
      server.responses[ApiEndpoints.login] = (200, {'user': _user.id});

      final result = await repository.login(email: 'a@b.co', password: 'x');

      expect((result as Err<AuthUser>).failure, isA<UnexpectedFailure>());
      verifyNever(
        () => tokens.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      );
    });

    test('enregistrement impossible : StorageFailure', () async {
      server.responses[ApiEndpoints.login] = (200, _session());
      when(
        () => tokens.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async => const Err<void>(StorageFailure()));

      final result = await repository.login(email: 'a@b.co', password: 'x');

      expect((result as Err<AuthUser>).failure, isA<StorageFailure>());
    });
  });

  group('inscription', () {
    test('succès : champs envoyés, tokens enregistrés', () async {
      server.responses[ApiEndpoints.register] = (201, _session());

      final result = await repository.register(
        fullName: 'Awa Traoré',
        username: 'awa',
        email: 'awa@example.com',
        password: 'Abc-1234',
      );

      expect(result.isOk, isTrue);
      expect(server.last.data, {
        'fullName': 'Awa Traoré',
        'username': 'awa',
        'email': 'awa@example.com',
        'password': 'Abc-1234',
      });
      verify(
        () => tokens.saveTokens(accessToken: 'ACCESS', refreshToken: 'REFRESH'),
      ).called(1);
    });

    test('doublon : ValidationFailure', () async {
      server.responses[ApiEndpoints.register] = (
        400,
        {'error': 'Email or username already exists'},
      );

      final result = await repository.register(
        fullName: 'Awa',
        username: 'awa',
        email: 'awa@example.com',
        password: 'Abc-1234',
      );

      expect((result as Err<AuthUser>).failure, isA<ValidationFailure>());
    });
  });

  group('mot de passe oublié', () {
    test('code envoyé : succès', () async {
      server.responses[ApiEndpoints.forgotPassword] = (200, {'success': true});

      final result = await repository.requestPasswordReset(
        email: 'awa@example.com',
      );

      expect(result.isOk, isTrue);
      expect(server.last.data, {'email': 'awa@example.com'});
    });

    test('compte inconnu (404) : même succès (anti-énumération)', () async {
      server.responses[ApiEndpoints.forgotPassword] = (
        404,
        {'error': 'User not found'},
      );

      final result = await repository.requestPasswordReset(email: 'x@y.co');

      expect(result.isOk, isTrue);
    });

    test('trop de demandes : RateLimitFailure', () async {
      server.responses[ApiEndpoints.forgotPassword] = (429, null);

      final result = await repository.requestPasswordReset(email: 'x@y.co');

      expect((result as Err<void>).failure, isA<RateLimitFailure>());
    });
  });

  group('réinitialisation', () {
    Future<Result<void>> reset() => repository.resetPassword(
      email: 'awa@example.com',
      code: '123456',
      newPassword: 'Nouveau-7',
    );

    test('succès', () async {
      server.responses[ApiEndpoints.resetPassword] = (200, {'success': true});

      expect((await reset()).isOk, isTrue);
      expect(server.last.data, {
        'email': 'awa@example.com',
        'code': '123456',
        'newPassword': 'Nouveau-7',
      });
    });

    test('code refusé : ValidationFailure', () async {
      server.responses[ApiEndpoints.resetPassword] = (
        400,
        {'error': 'Invalid reset code'},
      );

      expect(((await reset()) as Err<void>).failure, isA<ValidationFailure>());
    });

    test('compte inconnu : même erreur qu’un code refusé', () async {
      server.responses[ApiEndpoints.resetPassword] = (
        404,
        {'error': 'User not found'},
      );

      expect(((await reset()) as Err<void>).failure, isA<ValidationFailure>());
    });
  });

  group('déconnexion', () {
    test(
      'efface la session, puis révoque le jeton sans token d’accès',
      () async {
        when(() => tokens.readRefreshToken())
            .thenAnswer((_) async => const Ok<String?>('REFRESH'));
        server.responses[ApiEndpoints.logout] = (200, {'message': 'ok'});

        await repository.logout();

        verify(() => tokens.clear()).called(1);
        expect(server.last.path, ApiEndpoints.logout);
        expect(server.last.data, {'refreshToken': 'REFRESH'});
        expect(server.last.headers['Authorization'], isNull);
      },
    );

    test('hors ligne : la session locale est quand même effacée', () async {
      when(() => tokens.readRefreshToken())
          .thenAnswer((_) async => const Ok<String?>('REFRESH'));
      server.offline = true;

      await repository.logout();

      verify(() => tokens.clear()).called(1);
    });

    test('aucun jeton : aucun appel réseau', () async {
      when(() => tokens.readRefreshToken())
          .thenAnswer((_) async => const Ok<String?>(null));

      await repository.logout();

      verify(() => tokens.clear()).called(1);
      expect(server.requests, isEmpty);
    });

    test('stockage illisible : effacé quand même, aucun appel', () async {
      when(() => tokens.readRefreshToken())
          .thenAnswer((_) async => const Err<String?>(StorageFailure()));

      await repository.logout();

      verify(() => tokens.clear()).called(1);
      expect(server.requests, isEmpty);
    });
  });
}
