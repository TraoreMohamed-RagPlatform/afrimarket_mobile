import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/features/auth/auth_providers.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:afrimarket_mobile/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_page_harness.dart';
import '../../../../helpers/l10n.dart';

class _MockRequestReset extends Mock implements RequestPasswordResetUseCase;

class _MockReset extends Mock implements ResetPasswordUseCase;

const _email = 'awa@example.com';
const _password = 'Nouveau-mot-de-passe-7';

void main() {
  late _MockRequestReset requestReset;
  late _MockReset reset;

  setUp(() {
    requestReset = _MockRequestReset();
    reset = _MockReset();
  });

  void answerRequest(Result<void> result) {
    when(() => requestReset(email: any(named: 'email')))
        .thenAnswer((_) async => result);
  }

  void answerReset(Result<void> result) {
    when(
      () => reset(
        email: any(named: 'email'),
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async => result);
  }

  Future<void> pump(WidgetTester tester) async {
    await pumpAuthPage(
      tester,
      initialLocation: AppRoutes.forgotPassword,
      pages: {AppRoutes.forgotPassword: (_) => const ForgotPasswordPage()},
      overrides: [
        requestPasswordResetUseCaseProvider.overrideWithValue(requestReset),
        resetPasswordUseCaseProvider.overrideWithValue(reset),
      ],
    );
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// Étape 1 réussie : l'écran affiche l'étape du code.
  Future<void> reachCodeStep(WidgetTester tester) async {
    answerRequest(const Ok(null));
    await pump(tester);
    await tester.enterText(fieldByLabel(fr.authEmailLabel), ' $_email ');
    await tapButton(tester, fr.forgotSendCode);
  }

  Future<void> fillReset(
    WidgetTester tester, {
    String code = '123456',
    String password = _password,
  }) async {
    await tester.enterText(fieldByLabel(fr.authCodeLabel), code);
    await tester.enterText(fieldByLabel(fr.authNewPasswordLabel), password);
    await tester.enterText(fieldByLabel(fr.authConfirmPasswordLabel), password);
  }

  group('Étape 1 : adresse e-mail', () {
    testWidgets('vide : obligatoire, aucun envoi', (tester) async {
      await pump(tester);

      await tapButton(tester, fr.forgotSendCode);

      expect(find.text(fr.authFieldRequired), findsOneWidget);
      verifyNever(() => requestReset(email: any(named: 'email')));
    });

    testWidgets('succès : étape du code, adresse rappelée', (tester) async {
      await reachCodeStep(tester);

      verify(() => requestReset(email: _email)).called(1);
      expect(find.textContaining(_email), findsOneWidget);
      expect(fieldByLabel(fr.authCodeLabel), findsOneWidget);
    });

    testWidgets('échec réseau : message, reste à l’étape 1', (tester) async {
      answerRequest(const Err(NetworkFailure()));
      await pump(tester);

      await tester.enterText(fieldByLabel(fr.authEmailLabel), _email);
      await tapButton(tester, fr.forgotSendCode);

      expect(find.text(fr.errorNetwork), findsOneWidget);
      expect(fieldByLabel(fr.authCodeLabel), findsNothing);
    });
  });

  group('Étape 2 : code et nouveau mot de passe', () {
    testWidgets('code mal formé : refusé, aucun envoi', (tester) async {
      await reachCodeStep(tester);

      await fillReset(tester, code: '12ab');
      await tapButton(tester, fr.forgotResetSubmit);

      expect(find.text(fr.authCodeInvalid), findsOneWidget);
      verifyNever(
        () => reset(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });

    testWidgets('succès : confirmation puis retour à la connexion', (
      tester,
    ) async {
      await reachCodeStep(tester);
      answerReset(const Ok(null));

      await fillReset(tester);
      await tapButton(tester, fr.forgotResetSubmit);

      verify(() => reset(email: _email, code: '123456', newPassword: _password))
          .called(1);
      expect(findRoute(AppRoutes.login), findsOneWidget);
      expect(find.text(fr.resetPasswordDone), findsOneWidget);
    });

    testWidgets('code refusé : message dédié', (tester) async {
      await reachCodeStep(tester);
      answerReset(const Err(ValidationFailure()));

      await fillReset(tester);
      await tapButton(tester, fr.forgotResetSubmit);

      expect(find.text(fr.resetCodeRejected), findsOneWidget);
      expect(findRoute(AppRoutes.login), findsNothing);
    });

    testWidgets('« Renvoyer le code » : nouvel envoi et confirmation', (
      tester,
    ) async {
      await reachCodeStep(tester);

      await tapButton(tester, fr.forgotResendCode);

      verify(() => requestReset(email: _email)).called(2);
      expect(find.text(fr.forgotCodeResent), findsOneWidget);
    });

    testWidgets('« Modifier l’adresse » : retour à l’étape 1', (tester) async {
      await reachCodeStep(tester);

      await tapButton(tester, fr.forgotChangeEmail);

      expect(fieldByLabel(fr.authCodeLabel), findsNothing);
      expect(find.text(fr.forgotSendCode), findsOneWidget);
    });
  });

  testWidgets('texte agrandi (×2) : aucun débordement', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(tester);

    expect(tester.takeException(), isNull);
  });
}
