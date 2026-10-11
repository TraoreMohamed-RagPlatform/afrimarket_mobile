import 'dart:async';

import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:afrimarket_mobile/features/auth/auth_providers.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:afrimarket_mobile/features/auth/presentation/controllers/sign_out.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLogout extends Mock implements LogoutUseCase;

class _MockTokenStorage extends Mock implements TokenStorage;

void main() {
  test('masque la session AVANT d’attendre le serveur', () async {
    final tokens = _MockTokenStorage();
    when(tokens.hasTokens).thenAnswer((_) async => const Ok<bool>(true));
    final logout = _MockLogout();
    final pending = Completer<void>();
    when(logout.call).thenAnswer((_) => pending.future);

    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokens),
        logoutUseCaseProvider.overrideWithValue(logout),
      ],
    );
    addTearDown(container.dispose);
    container.read(sessionProvider.notifier).markAuthenticated();

    final done = container.read(signOutProvider)();

    expect(container.read(sessionProvider), SessionStatus.unauthenticated);
    verify(logout.call).called(1);

    pending.complete();
    await done;
  });
}
