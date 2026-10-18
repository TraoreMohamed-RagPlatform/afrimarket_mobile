import 'dart:async';

import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/features/auth/auth_providers.dart';
import 'package:afrimarket_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:afrimarket_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:afrimarket_mobile/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:afrimarket_mobile/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_page_harness.dart';
import '../../../../helpers/l10n.dart';

class _MockLogin extends Mock implements LoginUseCase;

const _user = AuthUser(
  id: 'u1',
  email: 'awa@example.com',
  username: 'awa',
  fullName: 'Awa Traoré',
);

void main() {
  late _MockLogin login;

  setUp(() => login = _MockLogin());

  void answer(Future<Result<AuthUser>> Function() result) {
    when(
      () => login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => result());
  }

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Flavor flavor = Flavor.prod,
    String? returnTo,
  }) {
    return pumpAuthPage(
      tester,
      initialLocation: AppRoutes.login,
      flavor: flavor,
      pages: {AppRoutes.login: (_) => LoginPage(returnTo: returnTo)},
      overrides: [loginUseCaseProvider.overrideWithValue(login)],
    );
  }

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    String email = 'awa@example.com',
    String password = 'Abc-1234',
  }) async {
    await tester.enterText(fieldByLabel(fr.authEmailLabel), email);
    await tester.enterText(fieldByLabel(fr.authPasswordLabel), password);
    await tester.tap(find.widgetWithText(FilledButton, fr.loginSubmit));
    await tester.pumpAndSettle();
  }

  group('Outils de développement', () {
    testWidgets('le bouton Diagnostic est visible en dev', (tester) async {
      await pump(tester, flavor: Flavor.dev);

      expect(find.text(fr.devDiagnosticsButton), findsOneWidget);
    });

    testWidgets('le bouton Diagnostic est absent en prod', (tester) async {
      await pump(tester);

      expect(find.text(fr.devDiagnosticsButton), findsNothing);
    });

    testWidgets('le bouton Diagnostic ouvre la page de diagnostic', (
      tester,
    ) async {
      await pump(tester, flavor: Flavor.dev);

      await tester.tap(find.text(fr.devDiagnosticsButton));
      await tester.pumpAndSettle();

      expect(findRoute(AppRoutes.diagnostics), findsOneWidget);
    });
  });

  group('Validation (avant tout appel réseau)', () {
    testWidgets('champs vides : obligatoires', (tester) async {
      await pump(tester);

      await tester.tap(find.widgetWithText(FilledButton, fr.loginSubmit));
      await tester.pumpAndSettle();

      expect(find.text(fr.authFieldRequired), findsNWidgets(2));
      verifyNever(
        () => login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('e-mail mal formé : refusé', (tester) async {
      await pump(tester);

      await fillAndSubmit(tester, email: 'awa@');

      expect(find.text(fr.authEmailInvalid), findsOneWidget);
    });

    testWidgets('mot de passe court accepté (ancien compte)', (tester) async {
      answer(() async => const Ok(_user));
      await pump(tester);

      await fillAndSubmit(tester, password: 'abc');

      verify(() => login(email: 'awa@example.com', password: 'abc')).called(1);
    });
  });

  group('Envoi', () {
    testWidgets('succès : la session est ouverte', (tester) async {
      answer(() async => const Ok(_user));
      final container = await pump(tester);

      await fillAndSubmit(tester);

      verify(() => login(email: 'awa@example.com', password: 'Abc-1234'))
          .called(1);
      expect(container.read(sessionProvider), SessionStatus.authenticated);
    });

    testWidgets('pendant l’envoi : bouton désactivé, indicateur affiché', (
      tester,
    ) async {
      final pending = Completer<Result<AuthUser>>();
      answer(() => pending.future);
      await pump(tester);

      await tester.enterText(fieldByLabel(fr.authEmailLabel), 'a@b.co');
      await tester.enterText(fieldByLabel(fr.authPasswordLabel), 'secret');
      await tester.tap(find.widgetWithText(FilledButton, fr.loginSubmit));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      pending.complete(const Err(NetworkFailure()));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    for (final (failure, message) in [
      (const UnauthorizedFailure(), fr.loginInvalidCredentials),
      (const ForbiddenFailure(), fr.authForbidden),
      (const NetworkFailure(), fr.errorNetwork),
    ]) {
      testWidgets('échec ${failure.runtimeType} : message adapté', (
        tester,
      ) async {
        answer(() async => Err(failure));
        final container = await pump(tester);

        await fillAndSubmit(tester);

        expect(find.text(message), findsOneWidget);
        expect(
          container.read(sessionProvider),
          isNot(SessionStatus.authenticated),
        );
      });
    }
  });

  group('Liens', () {
    testWidgets('« Mot de passe oublié ? » ouvre la réinitialisation', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text(fr.loginForgotPassword));
      await tester.pumpAndSettle();

      expect(findRoute(AppRoutes.forgotPassword), findsOneWidget);
    });

    testWidgets('« Créer un compte » transmet la page mémorisée', (
      tester,
    ) async {
      await pump(tester, returnTo: AppRoutes.publish);

      await tester.tap(find.text(fr.loginCreateAccount));
      await tester.pumpAndSettle();

      expect(
        findRoute(AppRoutes.withReturn(AppRoutes.register, AppRoutes.publish)),
        findsOneWidget,
      );
    });

    testWidgets('« Créer un compte » sans page mémorisée', (tester) async {
      await pump(tester);

      await tester.tap(find.text(fr.loginCreateAccount));
      await tester.pumpAndSettle();

      expect(findRoute(AppRoutes.register), findsOneWidget);
    });
  });

  testWidgets('texte agrandi (×2) : aucun débordement', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(tester, flavor: Flavor.dev);

    expect(tester.takeException(), isNull);
  });

  testWidgets('arabe et mode sombre : droite à gauche, logo affiché', (
    tester,
  ) async {
    await pumpAuthPage(
      tester,
      initialLocation: AppRoutes.login,
      pages: {AppRoutes.login: (_) => const LoginPage()},
      overrides: [loginUseCaseProvider.overrideWithValue(login)],
      locale: const Locale('ar'),
      themeMode: ThemeMode.dark,
    );

    expect(tester.takeException(), isNull);
    final context = tester.element(find.byType(AuthFormLayout));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(find.byType(AppLogo), findsOneWidget);
  });
}
