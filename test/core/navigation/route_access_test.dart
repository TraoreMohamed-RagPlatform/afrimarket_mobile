import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/navigation/route_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pages publiques', () {
    for (final path in [
      AppRoutes.home,
      AppRoutes.login,
      AppRoutes.search,
      AppRoutes.listing('a1B2-c3_d4'),
      AppRoutes.seller('42'),
      AppRoutes.diagnostics,
    ]) {
      test(path, () {
        expect(RouteAccessPolicy.of(path), RouteAccess.public);
      });
    }
  });

  group('Invitation à se connecter', () {
    for (final path in [
      AppRoutes.favorites,
      AppRoutes.messages,
      AppRoutes.notifications,
    ]) {
      test(path, () {
        expect(RouteAccessPolicy.of(path), RouteAccess.signInPrompt);
      });
    }
  });

  group('Fermé par défaut', () {
    test('Publier exige une connexion', () {
      expect(
        RouteAccessPolicy.of(AppRoutes.publish),
        RouteAccess.authenticated,
      );
    });

    test('une page non déclarée est protégée', () {
      expect(
        RouteAccessPolicy.of('/account/settings'),
        RouteAccess.authenticated,
      );
    });

    test('un identifiant mal formé n’est jamais public', () {
      for (final path in [
        '/listings/',
        '/listings/<script>',
        '/listings/a/b',
        '/listings/${'x' * 65}',
        '/sellers/../admin',
      ]) {
        expect(
          RouteAccessPolicy.of(path),
          RouteAccess.authenticated,
          reason: path,
        );
      }
    });
  });

  test('les identifiants sont encodés dans les adresses', () {
    expect(AppRoutes.listing('a b'), '/listings/a%20b');
  });
}
