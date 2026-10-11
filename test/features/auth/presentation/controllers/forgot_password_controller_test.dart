import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/auth/auth_providers.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:afrimarket_mobile/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRequestReset extends Mock implements RequestPasswordResetUseCase;

class _MockReset extends Mock implements ResetPasswordUseCase;

void main() {
  late _MockRequestReset requestReset;
  late _MockReset reset;
  late ProviderContainer container;

  ForgotPasswordState read() =>
      container.read(forgotPasswordControllerProvider);
  ForgotPasswordController controller() =>
      container.read(forgotPasswordControllerProvider.notifier);

  void answerRequest(Future<Result<void>> Function() result) {
    when(() => requestReset(email: any(named: 'email')))
        .thenAnswer((_) => result());
  }

  void answerReset(Future<Result<void>> Function() result) {
    when(
      () => reset(
        email: any(named: 'email'),
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) => result());
  }

  Future<void> toCodeStep() async {
    answerRequest(() async => const Ok<void>(null));
    await controller().requestCode(' awa@example.com ');
  }

  setUp(() {
    requestReset = _MockRequestReset();
    reset = _MockReset();
    container = ProviderContainer(
      overrides: [
        requestPasswordResetUseCaseProvider.overrideWithValue(requestReset),
        resetPasswordUseCaseProvider.overrideWithValue(reset),
      ],
    );
    addTearDown(container.dispose);
    container.listen(forgotPasswordControllerProvider, (previous, next) {});
  });

  test('démarre à l’étape e-mail', () {
    expect(read().step, ForgotPasswordStep.email);
    expect(read().isBusy, isFalse);
  });

  group('étape 1 : demande du code', () {
    test('succès : étape code, adresse nettoyée et conservée', () async {
      await toCodeStep();

      expect(read().step, ForgotPasswordStep.code);
      expect(read().email, 'awa@example.com');
      expect(read().failure, isNull);
    });

    test('échec : reste à l’étape e-mail avec l’erreur', () async {
      answerRequest(() async => const Err<void>(NetworkFailure()));

      await controller().requestCode('awa@example.com');

      expect(read().step, ForgotPasswordStep.email);
      expect(read().failure, isA<NetworkFailure>());
    });

    test('pendant l’envoi : occupé, un seul envoi', () async {
      final pending = Completer<Result<void>>();
      answerRequest(() => pending.future);

      final first = controller().requestCode('awa@example.com');
      expect(read().pending, ForgotPasswordAction.requestCode);
      await controller().requestCode('awa@example.com');
      pending.complete(const Ok<void>(null));
      await first;

      verify(() => requestReset(email: any(named: 'email'))).called(1);
    });
  });

  group('étape 2', () {
    test('nouveau code : confirmation affichée', () async {
      await toCodeStep();

      await controller().resendCode();

      expect(read().step, ForgotPasswordStep.code);
      expect(read().codeResent, isTrue);
      verify(() => requestReset(email: 'awa@example.com')).called(2);
    });

    test('nouveau code refusé : erreur, toujours à l’étape code', () async {
      await toCodeStep();
      answerRequest(() async => const Err<void>(RateLimitFailure()));

      await controller().resendCode();

      expect(read().step, ForgotPasswordStep.code);
      expect(read().codeResent, isFalse);
      expect(read().failure, isA<RateLimitFailure>());
    });

    test('réinitialisation réussie : étape terminée', () async {
      await toCodeStep();
      answerReset(() async => const Ok<void>(null));

      await controller().resetPassword(code: '123456', newPassword: 'Abc-1234');

      expect(read().step, ForgotPasswordStep.done);
      verify(
        () => reset(
          email: 'awa@example.com',
          code: '123456',
          newPassword: 'Abc-1234',
        ),
      ).called(1);
    });

    test('code refusé : erreur, toujours à l’étape code', () async {
      await toCodeStep();
      answerReset(() async => const Err<void>(ValidationFailure()));

      await controller().resetPassword(code: '000000', newPassword: 'Abc-1234');

      expect(read().step, ForgotPasswordStep.code);
      expect(read().failure, isA<ValidationFailure>());
    });

    test('modifier l’adresse : retour à l’étape e-mail', () async {
      await toCodeStep();

      controller().changeEmail();

      expect(read().step, ForgotPasswordStep.email);
      expect(read().email, 'awa@example.com');
    });
  });

  test('étape 2 impossible sans être passé par l’étape 1', () async {
    await controller().resendCode();
    await controller().resetPassword(code: '123456', newPassword: 'Abc-1234');

    verifyZeroInteractions(requestReset);
    verifyZeroInteractions(reset);
  });
}
