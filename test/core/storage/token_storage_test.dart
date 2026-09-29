import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/storage/secure_storage.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements SecureStorage;

const String _access = TokenStorage.accessTokenKey;
const String _refresh = TokenStorage.refreshTokenKey;

void main() {
  late _MockSecureStorage storage;
  late TokenStorage tokens;

  setUp(() {
    storage = _MockSecureStorage();
    tokens = TokenStorage(storage);

    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async => const Ok<void>(null));
    when(() => storage.delete(any()))
        .thenAnswer((_) async => const Ok<void>(null));
  });

  group('TokenStorage', () {
    test('saveTokens enregistre les deux tokens', () async {
      final result = await tokens.saveTokens(
        accessToken: 'A',
        refreshToken: 'R',
      );

      expect(result.isOk, isTrue);
      verify(() => storage.write(key: _access, value: 'A')).called(1);
      verify(() => storage.write(key: _refresh, value: 'R')).called(1);
    });

    test('readAccessToken utilise la mémoire après saveTokens', () async {
      await tokens.saveTokens(accessToken: 'A', refreshToken: 'R');

      final result = await tokens.readAccessToken();

      expect((result as Ok<String?>).value, 'A');
      verifyNever(() => storage.read(any()));
    });

    test('readAccessToken lit le stockage puis garde en mémoire', () async {
      when(() => storage.read(_access))
          .thenAnswer((_) async => const Ok<String?>('A'));

      await tokens.readAccessToken();
      final second = await tokens.readAccessToken();

      expect((second as Ok<String?>).value, 'A');
      verify(() => storage.read(_access)).called(1);
    });

    test('readRefreshToken lit toujours le stockage chiffré', () async {
      when(() => storage.read(_refresh))
          .thenAnswer((_) async => const Ok<String?>('R'));

      await tokens.readRefreshToken();
      await tokens.readRefreshToken();

      verify(() => storage.read(_refresh)).called(2);
    });

    test('saveTokens est « tout ou rien » si le refresh échoue', () async {
      when(() => storage.write(key: _refresh, value: 'R'))
          .thenAnswer((_) async => const Err<void>(StorageFailure()));

      final result = await tokens.saveTokens(
        accessToken: 'A',
        refreshToken: 'R',
      );

      expect((result as Err<void>).failure, isA<StorageFailure>());
      verify(() => storage.delete(_access)).called(1);
    });

    test('hasTokens est vrai si un refresh token existe', () async {
      when(() => storage.read(_refresh))
          .thenAnswer((_) async => const Ok<String?>('R'));

      final result = await tokens.hasTokens();

      expect((result as Ok<bool>).value, isTrue);
    });

    test('hasTokens est faux sans refresh token', () async {
      when(() => storage.read(_refresh))
          .thenAnswer((_) async => const Ok<String?>(null));

      final result = await tokens.hasTokens();

      expect((result as Ok<bool>).value, isFalse);
    });

    test('clear efface les tokens et vide la mémoire', () async {
      await tokens.saveTokens(accessToken: 'A', refreshToken: 'R');
      when(() => storage.read(_access))
          .thenAnswer((_) async => const Ok<String?>(null));

      final result = await tokens.clear();
      final afterClear = await tokens.readAccessToken();

      expect(result.isOk, isTrue);
      verify(() => storage.delete(_access)).called(1);
      verify(() => storage.delete(_refresh)).called(1);
      expect((afterClear as Ok<String?>).value, isNull);
    });
  });
}
