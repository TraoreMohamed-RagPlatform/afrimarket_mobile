import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/features/auth/auth_providers.dart';
import 'package:afrimarket_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:afrimarket_mobile/features/auth/presentation/pages/register_page.dart';
import 'package:afrimarket_mobile/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:afrimarket_mobile/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_page_harness.dart';
import '../../../../helpers/l10n.dart';

class _MockRegister extends Mock implements RegisterUseCase;

const _user = AuthUser(
  id: 'u1',
  email: 'awa@example.com',
  username: 'awa_t',
  fullName: 'Awa Traoré',
);

void main() {
  late _MockRegister register;

  setUp(() => register = _MockRegister());

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

  void verifyNotSent() {
    verifyNever(
      () => register(
        fullName: any(named: 'fullName'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  }

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    String? returnTo,
    List<String> stack = const [],
  }) {
    return pumpAuthPage(
      tester,
      initialLocation: AppRoutes.register,
      stack: stack,
      pages: {AppRoutes.register: (_) => RegisterPage(returnTo: returnTo)},
      overrides: [registerUseCaseProvider.overrideWithValue(register)],
    );
  }

  Future<void> fill(
    WidgetTester tester, {
    String fullName = 'Awa Traoré',
    String username = 'awa_t',
    String email = 'awa@example.com',
    String password = 'Correct-horse-42',
    String? confirmation,
  }) async {
    await tester.enterText(fieldByLabel(fr.authFullNameLabel), fullName);
    await tester.enterText(fieldByLabel(fr.authUsernameLabel), username);
    await tester.enterText(fieldByLabel(fr.authEmailLabel), email);
    await tester.enterText(fieldByLabel(fr.authPasswordLabel), password);
    await tester.enterText(
      fieldByLabel(fr.authConfirmPasswordLabel),
      confirmation ?? password,
    );
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, fr.registerSubmit));
    await tester.pumpAndSettle();
  }

  group('Validation (avant tout appel réseau)', () {
    testWidgets('formulaire vide : tous les champs obligatoires', (
      tester,
    ) async {
      await pump(tester);

      await submit(tester);

      expect(find.text(fr.authFieldRequired), findsNWidgets(5));
      verifyNotSent();
    });

    testWidgets('mot de passe trop court', (tester) async {
      await pump(tester);

      await fill(tester, password: 'Abc-123');
      await submit(tester);

      expect(find.text(fr.authPasswordTooShort), findsOneWidget);
      verifyNotSent();
    });

    testWidgets('mot de passe de plus de 72 octets', (tester) async {
      await pump(tester);

      await fill(tester, password: 'é' * 37);
      await submit(tester);

      expect(find.text(fr.authPasswordTooLong), findsOneWidget);
      verifyNotSent();
    });

    testWidgets('confirmation différente', (tester) async {
      await pump(tester);

      await fill(tester, confirmation: 'Autre-mot-de-passe');
      await submit(tester);

      expect(find.text(fr.authPasswordMismatch), findsOneWidget);
      verifyNotSent();
    });

    testWidgets('nom d’utilisateur invalide', (tester) async {
      await pump(tester);

      await fill(tester, username: 'awa traoré');
      await submit(tester);

      expect(find.text(fr.authUsernameInvalid), findsOneWidget);
      verifyNotSent();
    });
  });

  group('Envoi', () {
    testWidgets('succès : compte créé et session ouverte', (tester) async {
      answer(() async => const Ok(_user));
      final container = await pump(tester);

      await fill(tester);
      await submit(tester);

      verify(
        () => register(
          fullName: 'Awa Traoré',
          username: 'awa_t',
          email: 'awa@example.com',
          password: 'Correct-horse-42',
        ),
      ).called(1);
      expect(container.read(sessionProvider), SessionStatus.authenticated);
    });

    for (final (failure, message) in [
      (const ValidationFailure(), fr.registerRejected),
      (const ForbiddenFailure(), fr.authForbidden),
      (const NetworkFailure(), fr.errorNetwork),
    ]) {
      testWidgets('échec ${failure.runtimeType} : message adapté', (
        tester,
      ) async {
        answer(() async => Err(failure));
        final container = await pump(tester);

        await fill(tester);
        await submit(tester);

        expect(find.text(message), findsOneWidget);
        expect(
          container.read(sessionProvider),
          isNot(SessionStatus.authenticated),
        );
      });
    }
  });

  group('Retour à la connexion', () {
    testWidgets('ouverte depuis la connexion : retour en arrière', (
      tester,
    ) async {
      await pump(tester, stack: [AppRoutes.home, AppRoutes.login]);

      await tester.tap(find.widgetWithText(TextButton, fr.loginSubmit));
      await tester.pumpAndSettle();

      expect(findRoute(AppRoutes.login), findsOneWidget);
    });

    testWidgets('ouverte directement : connexion avec la page mémorisée', (
      tester,
    ) async {
      await pump(tester, returnTo: AppRoutes.publish);

      await tester.tap(find.widgetWithText(TextButton, fr.loginSubmit));
      await tester.pumpAndSettle();

      expect(
        findRoute(AppRoutes.withReturn(AppRoutes.login, AppRoutes.publish)),
        findsOneWidget,
      );
    });
  });

  testWidgets('texte agrandi (×2) : aucun débordement', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('arabe et mode sombre : droite à gauche, logo affiché', (
    tester,
  ) async {
    await pumpAuthPage(
      tester,
      initialLocation: AppRoutes.register,
      pages: {AppRoutes.register: (_) => const RegisterPage()},
      overrides: [registerUseCaseProvider.overrideWithValue(register)],
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
