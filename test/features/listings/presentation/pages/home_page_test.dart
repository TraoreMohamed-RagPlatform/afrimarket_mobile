import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:afrimarket_mobile/features/listings/presentation/pages/home_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/l10n.dart';

class _MockTokenStorage extends Mock implements TokenStorage;

AppConfig _config(Flavor flavor) {
  return AppConfig.fromValues(
    expected: flavor,
    flavorName: flavor.name,
    appName: 'AfriMarket',
    apiBaseUrl: flavor == Flavor.dev
        ? 'http://10.0.2.2:3000'
        : 'https://api.example.com',
    enableNetworkLogs: false,
  );
}

void main() {
  late _MockTokenStorage tokens;

  setUp(() {
    tokens = _MockTokenStorage();
    when(() => tokens.clear()).thenAnswer((_) async => const Ok<void>(null));
  });

  /// Affiche l'accueil et attend la fin de la vérification de la session.
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required Flavor flavor,
    bool hasSession = true,
  }) async {
    when(() => tokens.hasTokens())
        .thenAnswer((_) async => Ok<bool>(hasSession));

    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(_config(flavor)),
        tokenStorageProvider.overrideWithValue(tokens),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedApp(const HomePage()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('Outils de développement', () {
    testWidgets('dev : boutons Diagnostic et Galerie visibles', (tester) async {
      await pump(tester, flavor: Flavor.dev);

      expect(find.text(fr.devDiagnosticsButton), findsOneWidget);
      expect(find.text(fr.devGalleryButton), findsOneWidget);
    });

    testWidgets('prod : boutons Diagnostic et Galerie absents', (tester) async {
      await pump(tester, flavor: Flavor.prod);

      expect(find.text(fr.devDiagnosticsButton), findsNothing);
      expect(find.text(fr.devGalleryButton), findsNothing);
    });
  });

  group('Déconnexion', () {
    testWidgets('se déconnecter termine la session', (tester) async {
      final container = await pump(tester, flavor: Flavor.prod);

      await tester.tap(find.byTooltip(fr.logoutTooltip));
      await tester.pump();

      expect(container.read(sessionProvider), SessionStatus.unauthenticated);
      verify(() => tokens.clear()).called(1);
    });

    testWidgets('un visiteur ne voit pas le bouton de déconnexion', (
      tester,
    ) async {
      await pump(tester, flavor: Flavor.prod, hasSession: false);

      expect(find.byTooltip(fr.logoutTooltip), findsNothing);
    });
  });
}
