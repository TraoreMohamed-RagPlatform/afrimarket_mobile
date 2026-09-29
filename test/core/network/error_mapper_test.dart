import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/network/error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _ofType(DioExceptionType type) {
  return DioException(
    requestOptions: RequestOptions(path: '/test'),
    type: type,
  );
}

DioException _response(
  int status, {
  Object? data,
  Map<String, List<String>> headers = const {},
}) {
  final options = RequestOptions(path: '/test');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: data,
      headers: Headers.fromMap(headers),
    ),
  );
}

void main() {
  group('mapDioException', () {
    test('les délais dépassés donnent une TimeoutFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ]) {
        expect(mapDioException(_ofType(type)), isA<TimeoutFailure>());
      }
    });

    test('un problème réseau donne une NetworkFailure', () {
      expect(
        mapDioException(_ofType(DioExceptionType.connectionError)),
        isA<NetworkFailure>(),
      );
      expect(
        mapDioException(_ofType(DioExceptionType.badCertificate)),
        isA<NetworkFailure>(),
      );
    });

    test('400 lit les erreurs par champ (express-validator)', () {
      final failure = mapDioException(
        _response(
          400,
          data: {
            'errors': [
              {'path': 'email', 'msg': 'Invalid value'},
              {'path': 'email', 'msg': 'Email requis'},
              {'param': 'password', 'msg': 'Trop court'},
            ],
          },
        ),
      );

      expect(failure, isA<ValidationFailure>());
      final fields = (failure as ValidationFailure).fieldErrors;
      expect(fields['email'], ['Invalid value', 'Email requis']);
      expect(fields['password'], ['Trop court']);
    });

    test('400 avec un JSON inattendu ne plante pas', () {
      final failure = mapDioException(_response(400, data: 'texte brut'));

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).fieldErrors, isEmpty);
    });

    test('401, 403 et 404 sont correctement traduits', () {
      expect(mapDioException(_response(401)), isA<UnauthorizedFailure>());
      expect(mapDioException(_response(403)), isA<ForbiddenFailure>());
      expect(mapDioException(_response(404)), isA<NotFoundFailure>());
    });

    test('429 donne une RateLimitFailure avec Retry-After', () {
      final failure = mapDioException(
        _response(
          429,
          headers: {
            'retry-after': ['900'],
          },
        ),
      );

      expect(failure, isA<RateLimitFailure>());
      expect(
        (failure as RateLimitFailure).retryAfter,
        const Duration(seconds: 900),
      );
    });

    test('429 avec le code ACCOUNT_LOCKED donne un compte bloqué', () {
      final failure = mapDioException(
        _response(429, data: {'code': 'ACCOUNT_LOCKED'}),
      );

      expect(failure, isA<AccountLockedFailure>());
    });

    test('423 donne une AccountLockedFailure', () {
      expect(mapDioException(_response(423)), isA<AccountLockedFailure>());
    });

    test('5xx donne une ServerFailure avec le code HTTP', () {
      final failure = mapDioException(_response(503));

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 503);
    });

    test('le message d’erreur du serveur n’est jamais repris', () {
      final failure = mapDioException(
        _response(500, data: {'error': 'PrismaClientKnownRequestError...'}),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.toString(), isNot(contains('Prisma')));
    });

    test('une requête annulée donne une UnexpectedFailure', () {
      expect(
        mapDioException(_ofType(DioExceptionType.cancel)),
        isA<UnexpectedFailure>(),
      );
    });
  });
}
