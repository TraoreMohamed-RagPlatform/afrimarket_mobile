import 'package:afrimarket_mobile/app/pages/not_found_page.dart';
import 'package:afrimarket_mobile/app/pages/splash_page.dart';
import 'package:afrimarket_mobile/app/router/route_guard.dart';
import 'package:afrimarket_mobile/app/shell/app_shell.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:afrimarket_mobile/features/favorites/presentation/pages/favorites_page.dart';
import 'package:afrimarket_mobile/features/health/presentation/pages/health_check_page.dart';
import 'package:afrimarket_mobile/features/listings/presentation/pages/home_page.dart';
import 'package:afrimarket_mobile/features/listings/presentation/pages/publish_listing_page.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/pages/messages_page.dart';
import 'package:afrimarket_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Routeur de l'application.
///
/// Sécurité (OWASP MASVS - AUTH) :
/// - la protection des pages est CENTRALISÉE (resolveRedirect +
///   RouteAccessPolicy, fermé par défaut) ;
/// - le routeur réagit à chaque changement de session (connexion,
///   déconnexion, session expirée) ;
/// - la page de diagnostic n'est déclarée QU'EN dev.
///
/// Navigation (ADR 0003) : coquille à onglets (StatefulShellRoute), chaque
/// onglet garde sa propre pile ; les pages plein écran (Publier,
/// connexion) sont déclarées hors de la coquille.
final appRouterProvider = Provider<GoRouter>((ref) {
  final config = ref.watch(appConfigProvider);

  // Relais entre Riverpod et go_router : notifie le routeur à chaque
  // changement de session.
  final session = ValueNotifier<SessionStatus>(ref.read(sessionProvider));
  ref
    ..listen<SessionStatus>(
      sessionProvider,
      (previous, next) => session.value = next,
    )
    ..onDispose(session.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: session,
    redirect: (context, state) =>
        resolveRedirect(status: session.value, location: state.uri),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      // Onglets : l'ordre des branches = l'ordre des onglets (AppShell).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.favorites,
                builder: (context, state) => const FavoritesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.messages,
                builder: (context, state) => const MessagesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notifications,
                builder: (context, state) => const NotificationsPage(),
              ),
            ],
          ),
        ],
      ),
      // Plein écran, par-dessus les onglets.
      GoRoute(
        path: AppRoutes.publish,
        builder: (context, state) => const PublishListingPage(),
      ),
      if (config.flavor == Flavor.dev)
        GoRoute(
          path: AppRoutes.diagnostics,
          builder: (context, state) => const HealthCheckPage(),
        ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );

  ref.onDispose(router.dispose);
  return router;
});
