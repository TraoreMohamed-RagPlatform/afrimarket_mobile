import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/storage/secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage;

void main() {
  late _MockFlutterSecureStorage mock;
  late SecureStorage storage;

  setUp(() {
    mock = _MockFlutterSecureStorage();
    storage = SecureStorage(mock);
  });

  group('SecureStorage', () {
    test('read renvoie la valeur stockée', () async {
      when(() => mock.read(key: 'k')).thenAnswer((_) async => 'valeur');

      final result = await storage.read('k');

      expect(result, isA<Ok<String?>>());
      expect((result as Ok<String?>).value, 'valeur');
    });

    test('read renvoie null si la clé est absente', () async {
      when(() => mock.read(key: 'k')).thenAnswer((_) async => null);

      final result = await storage.read('k');

      expect((result as Ok<String?>).value, isNull);
    });

    test('write enregistre la valeur', () async {
      when(() => mock.write(key: 'k', value: 'v')).thenAnswer((_) async {});

      final result = await storage.write(key: 'k', value: 'v');

      expect(result.isOk, isTrue);
      verify(() => mock.write(key: 'k', value: 'v')).called(1);
    });

    test('delete supprime la valeur', () async {
      when(() => mock.delete(key: 'k')).thenAnswer((_) async {});

      final result = await storage.delete('k');

      expect(result.isOk, isTrue);
      verify(() => mock.delete(key: 'k')).called(1);
    });

    test('deleteAll supprime toutes les valeurs', () async {
      when(() => mock.deleteAll()).thenAnswer((_) async {});

      final result = await storage.deleteAll();

      expect(result.isOk, isTrue);
      verify(() => mock.deleteAll()).called(1);
    });

    test('une erreur de lecture devient une StorageFailure', () async {
      when(() => mock.read(key: 'k'))
          .thenThrow(PlatformException(code: 'keystore_error'));

      final result = await storage.read('k');

      expect(result, isA<Err<String?>>());
      expect((result as Err<String?>).failure, isA<StorageFailure>());
    });

    test('une erreur d’écriture devient une StorageFailure', () async {
      when(() => mock.write(key: 'k', value: 'v'))
          .thenThrow(PlatformException(code: 'keystore_error'));

      final result = await storage.write(key: 'k', value: 'v');

      expect((result as Err<void>).failure, isA<StorageFailure>());
    });
  });
}
