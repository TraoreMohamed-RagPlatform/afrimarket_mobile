import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/storage/secure_storage.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements SecureStorage;

void main() {
  group('storage providers', () {
    test('tokenStorageProvider renvoie toujours la même instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(tokenStorageProvider);
      final second = container.read(tokenStorageProvider);

      expect(identical(first, second), isTrue);
    });

    test('tokenStorageProvider utilise le secureStorageProvider', () async {
      final mock = _MockSecureStorage();
      when(() => mock.read(any()))
          .thenAnswer((_) async => const Ok<String?>('R'));

      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(mock)],
      );
      addTearDown(container.dispose);

      final result = await container.read(tokenStorageProvider).hasTokens();

      expect((result as Ok<bool>).value, isTrue);
      verify(() => mock.read(any())).called(1);
    });
  });
}
