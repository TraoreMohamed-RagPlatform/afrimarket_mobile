import 'package:afrimarket_mobile/app/router/app_routes.dart';
import 'package:afrimarket_mobile/app/router/route_guard.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

String? redirect(SessionStatus status, String location) {
  return resolveRedirect(status: status, location: Uri.parse(location));
}

void main() {
  group('resolveRedirect - session inconnue', () {
    test('reste sur le splash', () {
      expect(redirect(SessionStatus.unknown, '/splash'), isNull);
    });

    test('envoie vers le splash en retenant la page demandée', () {
      expect(redirect(SessionStatus.unknown, '/home'), '/splash?from=%2Fhome');
    });
  });

  group('resolveRedirect - non connecté', () {
    test('autorise la page de connexion', () {
      expect(redirect(SessionStatus.unauthenticated, '/login'), isNull);
    });

    test('bloque une page protégée et retient la destination', () {
      expect(
        redirect(SessionStatus.unauthenticated, '/home'),
        '/login?from=%2Fhome',
      );
    });

    test('quitte le splash vers la connexion', () {
      expect(redirect(SessionStatus.unauthenticated, '/splash'), '/login');
    });
  });

  group('resolveRedirect - connecté', () {
    test('autorise une page protégée', () {
      expect(redirect(SessionStatus.authenticated, '/home'), isNull);
    });

    test('quitte la connexion vers l’accueil', () {
      expect(redirect(SessionStatus.authenticated, '/login'), AppRoutes.home);
    });

    test('revient à la page retenue après connexion', () {
      expect(
        redirect(SessionStatus.authenticated, '/login?from=%2Flistings%2F42'),
        '/listings/42',
      );
    });
  });

  group('safeInternalPath - protection redirection ouverte', () {
    test('accepte un chemin interne', () {
      expect(
        safeInternalPath('/listings/42?tab=photos'),
        '/listings/42?tab=photos',
      );
    });

    test('refuse une URL externe', () {
      expect(safeInternalPath('https://site-malveillant.com'), isNull);
    });

    test('refuse un hôte déguisé', () {
      expect(safeInternalPath('//site-malveillant.com'), isNull);
    });

    test('refuse un antislash', () {
      expect(safeInternalPath(r'/\site-malveillant.com'), isNull);
    });

    test('refuse un chemin relatif', () {
      expect(safeInternalPath('home'), isNull);
    });

    test('refuse les routes qui provoqueraient une boucle', () {
      expect(safeInternalPath('/login'), isNull);
      expect(safeInternalPath('/splash'), isNull);
    });

    test('une redirection malveillante renvoie vers l’accueil', () {
      expect(
        redirect(
          SessionStatus.authenticated,
          '/login?from=https%3A%2F%2Fsite-malveillant.com',
        ),
        AppRoutes.home,
      );
    });
  });
}
