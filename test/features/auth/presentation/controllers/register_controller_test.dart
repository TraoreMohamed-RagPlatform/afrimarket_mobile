import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:afrimarket_mobile/features/auth/auth_providers.dart';
import 'package:afrimarket_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:afrimarket_mobile/features/auth/presentation/controllers/auth_form_state.dart';
import 'package:afrimarket_mobile/features/auth/presentation/controllers/register_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRegister extends Mock implements RegisterUseCase;

class _MockTokenStorage extends Mock implements TokenStorage;

const _user = AuthUser(
  id: 'u1',
  email: 'awa@example.com',
  username: 'awa',
  fullName: 'Awa Traoré',
);

void main() {
  late _MockRegister register;
  late ProviderContainer container;

  void answer(Future<Result<AuthUser>> Function() result) {
    when(
      () => register(
        fullName: any(named: 'fullName'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => result());
  }

  Future<void> submit() => container
      .read(registerControllerProvider.notifier)
      .submit(
        fullName: 'Awa Traoré',
        username: 'awa',
        email: 'awa@example.com',
        password: 'Abc-1234',
      );

  setUp(() {
    register = _MockRegister();
    final tokens = _MockTokenStorage();
    when(tokens.hasTokens).thenAnswer((_) async => const Ok<bool>(false));

    container = ProviderContainer(
      overrides: [
        registerUseCaseProvider.overrideWithValue(register),
        tokenStorageProvider.overrideWithValue(tokens),
      ],
    );
    addTearDown(container.dispose);
    container.listen(registerControllerProvider, (previous, next) {});
  });

  test('succès : compte créé et session ouverte', () async {
    answer(() async => const Ok<AuthUser>(_user));

    await submit();

    expect(
      container.read(registerControllerProvider),
      isA<AuthFormSucceeded>(),
    );
    expect(container.read(sessionProvider), SessionStatus.authenticated);
  });

  test('échec : AuthFormFailed', () async {
    answer(() async => const Err<AuthUser>(ValidationFailure()));

    await submit();

    final state = container.read(registerControllerProvider);
    expect((state as AuthFormFailed).failure, isA<ValidationFailure>());
  });

  test('un seul envoi à la fois', () async {
    final pending = Completer<Result<AuthUser>>();
    answer(() => pending.future);

    final first = submit();
    await submit();
    pending.complete(const Err<AuthUser>(NetworkFailure()));
    await first;

    verify(
      () => register(
        fullName: any(named: 'fullName'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).called(1);
  });
}
