import 'package:afrimarket_mobile/app/router/route_guard.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

String? _redirect(SessionStatus status, String location) =>
    resolveRedirect(status: status, location: Uri.parse(location));

String _from(String target, String from) =>
    Uri(path: target, queryParameters: {fromParam: from}).toString();

void main() {
  group('Session en cours de vérification', () {
    test('toute page passe par le démarrage, en la mémorisant', () {
      expect(
        _redirect(SessionStatus.unknown, '/listings/12'),
        _from(AppRoutes.splash, '/listings/12'),
      );
    });

    test('la page de démarrage elle-même est autorisée', () {
      expect(_redirect(SessionStatus.unknown, AppRoutes.splash), isNull);
    });
  });

  group('Visiteur (non connecté)', () {
    const guest = SessionStatus.unauthenticated;

    test('fil, annonce et recherche : accès libre', () {
      expect(_redirect(guest, AppRoutes.home), isNull);
      expect(_redirect(guest, '/listings/12'), isNull);
      expect(_redirect(guest, AppRoutes.search), isNull);
    });

    test('onglets avec invitation : accès libre (la page invite)', () {
      expect(_redirect(guest, AppRoutes.favorites), isNull);
      expect(_redirect(guest, AppRoutes.messages), isNull);
    });

    test('Publier : connexion, puis retour à Publier', () {
      expect(
        _redirect(guest, AppRoutes.publish),
        _from(AppRoutes.login, AppRoutes.publish),
      );
    });

    test('page non déclarée : connexion (fermé par défaut)', () {
      expect(
        _redirect(guest, '/account/settings'),
        _from(AppRoutes.login, '/account/settings'),
      );
    });

    group('fin du démarrage', () {
      test('sans page mémorisée : le fil', () {
        expect(_redirect(guest, AppRoutes.splash), AppRoutes.home);
      });

      test('lien partagé vers une annonce : l’annonce', () {
        expect(
          _redirect(guest, _from(AppRoutes.splash, '/listings/12')),
          '/listings/12',
        );
      });

      test('page protégée mémorisée : connexion, puis cette page', () {
        expect(
          _redirect(guest, _from(AppRoutes.splash, AppRoutes.publish)),
          _from(AppRoutes.login, AppRoutes.publish),
        );
      });

      test('adresse externe mémorisée : ignorée (CWE-601)', () {
        expect(
          _redirect(guest, _from(AppRoutes.splash, 'https://evil.com')),
          AppRoutes.home,
        );
      });
    });
  });

  group('Utilisateur connecté', () {
    const user = SessionStatus.authenticated;

    test('pages protégées : accès libre', () {
      expect(_redirect(user, AppRoutes.publish), isNull);
      expect(_redirect(user, AppRoutes.favorites), isNull);
    });

    test('connexion : retour à la page mémorisée', () {
      expect(
        _redirect(user, _from(AppRoutes.login, AppRoutes.publish)),
        AppRoutes.publish,
      );
    });

    test('connexion sans page mémorisée : le fil', () {
      expect(_redirect(user, AppRoutes.login), AppRoutes.home);
    });
  });

  group('safeInternalPath (CWE-601)', () {
    test('accepte un chemin interne', () {
      expect(safeInternalPath('/listings/12?ref=share'), isNotNull);
    });

    test('refuse les redirections dangereuses', () {
      for (final candidate in [
        null,
        '',
        'listings/12',
        'https://evil.com',
        '//evil.com',
        r'/\evil.com',
        AppRoutes.login,
        AppRoutes.splash,
      ]) {
        expect(safeInternalPath(candidate), isNull, reason: '$candidate');
      }
    });
  });
}
