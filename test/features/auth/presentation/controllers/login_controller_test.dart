import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:afrimarket_mobile/features/auth/auth_providers.dart';
import 'package:afrimarket_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:afrimarket_mobile/features/auth/presentation/controllers/auth_form_state.dart';
import 'package:afrimarket_mobile/features/auth/presentation/controllers/login_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLogin extends Mock implements LoginUseCase;

class _MockTokenStorage extends Mock implements TokenStorage;

const _user = AuthUser(
  id: 'u1',
  email: 'awa@example.com',
  username: 'awa',
  fullName: 'Awa Traoré',
);

void main() {
  late _MockLogin login;
  late ProviderContainer container;

  void answer(Future<Result<AuthUser>> Function() result) {
    when(
      () => login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => result());
  }

  Future<void> submit() => container
      .read(loginControllerProvider.notifier)
      .submit(email: 'awa@example.com', password: 'Abc-1234');

  setUp(() {
    login = _MockLogin();
    final tokens = _MockTokenStorage();
    when(tokens.hasTokens).thenAnswer((_) async => const Ok<bool>(false));

    container = ProviderContainer(
      overrides: [
        loginUseCaseProvider.overrideWithValue(login),
        tokenStorageProvider.overrideWithValue(tokens),
      ],
    );
    addTearDown(container.dispose);
    container.listen(loginControllerProvider, (previous, next) {});
  });

  test('démarre à AuthFormIdle', () {
    expect(container.read(loginControllerProvider), isA<AuthFormIdle>());
  });

  test('succès : session ouverte', () async {
    answer(() async => const Ok<AuthUser>(_user));

    await submit();

    expect(container.read(loginControllerProvider), isA<AuthFormSucceeded>());
    expect(container.read(sessionProvider), SessionStatus.authenticated);
  });

  test('échec : AuthFormFailed, session inchangée', () async {
    answer(() async => const Err<AuthUser>(UnauthorizedFailure()));

    await submit();

    final state = container.read(loginControllerProvider);
    expect((state as AuthFormFailed).failure, isA<UnauthorizedFailure>());
    expect(container.read(sessionProvider), isNot(SessionStatus.authenticated));
  });

  test('un seul envoi à la fois', () async {
    final pending = Completer<Result<AuthUser>>();
    answer(() => pending.future);

    final first = submit();
    expect(container.read(loginControllerProvider), isA<AuthFormSubmitting>());
    await submit();
    pending.complete(const Ok<AuthUser>(_user));
    await first;

    verify(
      () => login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).called(1);
  });
}
