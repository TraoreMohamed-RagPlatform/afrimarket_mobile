import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Ok expose sa valeur et isOk', () {
      const Result<int> result = Ok(42);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
    });

    test('Err expose sa Failure et isErr', () {
      const Result<int> result = Err(NetworkFailure());

      expect(result.isErr, isTrue);
      expect(result.isOk, isFalse);
    });

    test('fold appelle onOk en cas de succès', () {
      const Result<int> result = Ok(2);

      final text = result.fold(
        onOk: (value) => 'ok:$value',
        onErr: (failure) => 'err',
      );

      expect(text, 'ok:2');
    });

    test('fold appelle onErr en cas d’échec', () {
      const Result<int> result = Err(TimeoutFailure());

      final text = result.fold(
        onOk: (value) => 'ok',
        onErr: (failure) => failure is TimeoutFailure ? 'timeout' : 'autre',
      );

      expect(text, 'timeout');
    });

    test('map transforme la valeur en cas de succès', () {
      const Result<int> result = Ok(21);

      final mapped = result.map((value) => value * 2);

      expect(mapped, isA<Ok<int>>());
      expect((mapped as Ok<int>).value, 42);
    });

    test('map conserve la Failure en cas d’échec', () {
      const Result<int> result = Err(NotFoundFailure());

      final mapped = result.map((value) => value.toString());

      expect(mapped, isA<Err<String>>());
      expect((mapped as Err<String>).failure, isA<NotFoundFailure>());
    });

    test('switch exhaustif avec extraction de la valeur', () {
      const Result<String> result = Ok('AfriMarket');

      final text = switch (result) {
        Ok(:final value) => value,
        Err() => 'erreur',
      };

      expect(text, 'AfriMarket');
    });
  });
}
