import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_guard.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('guardApiCall', () {
    test('renvoie Ok en cas de succès', () async {
      final result = await guardApiCall(() async => 'donnée');

      expect((result as Ok<String>).value, 'donnée');
    });

    test('traduit une DioException en Failure', () async {
      final result = await guardApiCall<String>(
        () async => throw DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect((result as Err<String>).failure, isA<TimeoutFailure>());
    });

    test('une réponse inattendue donne une UnexpectedFailure', () async {
      final result = await guardApiCall<int>(
        () async => throw const FormatException('JSON invalide'),
      );

      expect((result as Err<int>).failure, isA<UnexpectedFailure>());
    });
  });
}
