import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_theme.dart';
import 'package:afrimarket_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:afrimarket_mobile/features/notifications/presentation/notification_text.dart';
import 'package:afrimarket_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:afrimarket_mobile/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/fake_notifications_repository.dart';
import '../../../helpers/fake_realtime_connection.dart';
import '../../../helpers/fake_unread_counts_repository.dart';
import '../../../helpers/l10n.dart';

class _Session extends SessionNotifier {
  new(this._initial);

  final SessionStatus _initial;

  @override
  SessionStatus build() => _initial;
}

final AppLocalizations _ar = lookupAppLocalizations(const Locale('ar'));

void main() {
  late FakeNotificationsRepository notifications;

  setUp(() => notifications = FakeNotificationsRepository());

  void showItems(List<AppNotification> items, {String? next}) {
    notifications.pages
      ..clear()
      ..add(Ok(CursorPage(items: items, nextCursor: next)));
  }

  /// Ouvre l'onglet dans un vrai routeur (annonce et Messages simulées).
  Future<void> pump(
    WidgetTester tester, {
    SessionStatus session = SessionStatus.authenticated,
    Locale locale = const Locale('fr'),
    ThemeMode themeMode = ThemeMode.light,
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.notifications,
      routes: [
        GoRoute(
          path: AppRoutes.notifications,
          builder: (_, _) => const NotificationsPage(),
        ),
        GoRoute(
          path: AppRoutes.messages,
          builder: (_, _) => const Text('MESSAGES'),
        ),
        GoRoute(
          path: AppRoutes.listingPattern,
          builder: (_, state) => Text('ANNONCE ${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(() => _Session(session)),
        ...notificationsOverrides(notifications),
        ...realtimeOverrides(FakeRealtimeConnection()),
        ...unreadOverrides(),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData.fromView(tester.view)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder markAllButton() => find.widgetWithIcon(IconButton, AppIcons.checks);

  bool markAllEnabled(WidgetTester tester) =>
      tester.widget<IconButton>(markAllButton()).onPressed != null;

  testWidgets('visiteur : invitation à se connecter, sans bouton', (
    tester,
  ) async {
    await pump(tester, session: SessionStatus.unauthenticated);

    expect(find.text(fr.signInNotificationsTitle), findsOneWidget);
    expect(markAllButton(), findsNothing);
    expect(notifications.listCalls, isEmpty);
  });

  testWidgets('aucune notification : message vide, bouton désactivé', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text(fr.notificationsEmptyTitle), findsOneWidget);
    expect(markAllEnabled(tester), isFalse);
  });

  testWidgets('liste : textes traduits, non lue annoncée et surlignée', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    showItems([
      sampleNotification('a'),
      sampleNotification(
        'b',
        kind: NotificationKind.ratingReceived,
        read: true,
      ),
      sampleNotification(
        'c',
        kind: NotificationKind.system,
        withListing: false,
        read: true,
        title: 'Bienvenue',
        message: 'Publiez votre première annonce.',
      ),
    ]);
    await pump(tester);

    final title = userText('Canapé 3 places');
    expect(find.text(fr.notificationListingInterest(title)), findsOneWidget);
    expect(find.text(fr.notificationRatingReceived(title)), findsOneWidget);
    expect(
      find.text(userText('Bienvenue — Publiez votre première annonce.')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(fr.notificationUnread)),
      findsOneWidget,
    );
    expect(find.text(fr.notificationTimeJustNow), findsNWidgets(3));
    expect(markAllEnabled(tester), isTrue);
    handle.dispose();
  });

  testWidgets('toucher : lue, puis l’annonce s’ouvre', (tester) async {
    showItems([sampleNotification('a')]);
    await pump(tester);

    await tester.tap(find.byType(NotificationTile));
    await tester.pumpAndSettle();

    expect(notifications.readIds, ['a']);
    expect(find.text('ANNONCE listing-1'), findsOneWidget);
  });

  testWidgets('message : ouvre Messages', (tester) async {
    showItems([
      sampleNotification(
        'm',
        kind: NotificationKind.message,
        withListing: false,
      ),
    ]);
    await pump(tester);

    expect(find.text(fr.notificationMessage), findsOneWidget);
    await tester.tap(find.byType(NotificationTile));
    await tester.pumpAndSettle();

    expect(find.text('MESSAGES'), findsOneWidget);
  });

  testWidgets('sans annonce : lue, on reste sur l’onglet', (tester) async {
    showItems([
      sampleNotification(
        's',
        kind: NotificationKind.system,
        withListing: false,
        title: 'Info',
      ),
    ]);
    await pump(tester);

    await tester.tap(find.byType(NotificationTile));
    await tester.pumpAndSettle();

    expect(notifications.readIds, ['s']);
    expect(find.byType(NotificationsPage), findsOneWidget);
  });

  testWidgets('Tout marquer comme lu', (tester) async {
    showItems([sampleNotification('a'), sampleNotification('b')]);
    await pump(tester);

    await tester.tap(markAllButton());
    await tester.pumpAndSettle();

    expect(notifications.readAllCalls, 1);
    expect(markAllEnabled(tester), isFalse);
  });

  testWidgets('glisser : retirée, Annuler la remet sans rien supprimer', (
    tester,
  ) async {
    showItems([sampleNotification('a')]);
    await pump(tester);

    await tester.drag(find.byType(NotificationTile), const Offset(-800, 0));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationTile), findsNothing);
    expect(find.text(fr.notificationDeleted), findsOneWidget);

    await tester.tap(find.text(fr.undo));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationTile), findsOneWidget);
    expect(notifications.deletedIds, isEmpty);
  });

  testWidgets('glisser sans Annuler : supprimée sur le serveur', (
    tester,
  ) async {
    showItems([sampleNotification('a'), sampleNotification('b')]);
    await pump(tester);

    await tester.drag(
      find.byType(NotificationTile).first,
      const Offset(-800, 0),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(notifications.deletedIds, ['a']);
    expect(find.byType(NotificationTile), findsOneWidget);
  });

  testWidgets('action de suppression accessible', (tester) async {
    final handle = tester.ensureSemantics();
    showItems([sampleNotification('a')]);
    await pump(tester);

    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp(fr.notificationUnread)),
    );
    final action = CustomSemanticsAction(label: fr.notificationDelete);
    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(action),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NotificationTile), findsNothing);
    handle.dispose();
  });

  testWidgets('échec d’une action : message affiché', (tester) async {
    showItems([sampleNotification('a', withListing: false)]);
    notifications.actionAnswer = const Err(NetworkFailure());
    await pump(tester);

    await tester.tap(find.byType(NotificationTile));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(notifications.readIds, ['a']);
  });

  testWidgets('erreur au chargement, puis Réessayer', (tester) async {
    notifications.pages
      ..clear()
      ..addAll([
        const Err(NetworkFailure()),
        Ok(CursorPage(items: [sampleNotification('a')])),
      ]);
    await pump(tester);

    await tester.tap(find.text(fr.retry));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationTile), findsOneWidget);
  });

  testWidgets('page suivante chargée en descendant', (tester) async {
    notifications.pages
      ..clear()
      ..addAll([
        Ok(
          CursorPage(
            items: [for (var i = 0; i < 12; i++) sampleNotification('n$i')],
            nextCursor: 'n11',
          ),
        ),
        Ok(CursorPage(items: [sampleNotification('n12')])),
      ]);
    await pump(tester);

    await tester.fling(find.byType(ListView), const Offset(0, -2000), 3000);
    await tester.pumpAndSettle();

    expect(notifications.listCalls, [null, 'n11']);
  });

  testWidgets('page suivante en échec : Réessayer en bas', (tester) async {
    notifications.pages
      ..clear()
      ..addAll([
        Ok(CursorPage(items: [sampleNotification('a')], nextCursor: 'a')),
        const Err(NetworkFailure()),
        Ok(CursorPage(items: [sampleNotification('b')])),
      ]);
    await pump(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -50));
    await tester.pumpAndSettle();

    expect(find.text(fr.retry), findsOneWidget);
    await tester.tap(find.text(fr.retry));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationTile), findsNWidgets(2));
  });

  testWidgets('tirer pour actualiser', (tester) async {
    showItems([sampleNotification('a')]);
    await pump(tester);

    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(notifications.listCalls.length, greaterThanOrEqualTo(2));
  });

  testWidgets('mode sombre, arabe (RTL) et texte ×2 : sans débordement', (
    tester,
  ) async {
    showItems([
      sampleNotification('a'),
      sampleNotification('b', kind: NotificationKind.listingSold, read: true),
      sampleNotification('c', kind: NotificationKind.listingUpdated),
    ]);
    await pump(
      tester,
      locale: const Locale('ar'),
      themeMode: ThemeMode.dark,
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text(_ar.navNotifications), findsOneWidget);
    expect(
      find.text(_ar.notificationListingSold(userText('Canapé 3 places'))),
      findsOneWidget,
    );

    // RTL : glisser vers le début, c'est-à-dire vers la droite.
    await tester.drag(
      find.byType(NotificationTile).first,
      const Offset(800, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NotificationTile), findsNWidgets(2));
  });

  group('NotificationText', () {
    final now = DateTime(2026, 10, 23, 12);

    test('dates relatives, puis la date', () {
      String time(Duration age) =>
          NotificationText.time(now.subtract(age), fr, now: now);

      expect(time(const Duration(seconds: 10)), fr.notificationTimeJustNow);
      expect(time(const Duration(minutes: 5)), fr.notificationTimeMinutes(5));
      expect(time(const Duration(hours: 3)), fr.notificationTimeHours(3));
      expect(time(const Duration(days: 1)), fr.notificationTimeYesterday);
      expect(time(const Duration(days: 4)), fr.notificationTimeDays(4));
      expect(time(const Duration(days: 30)), contains('2026'));
    });

    test('avis sans annonce, type sans annonce : textes de repli', () {
      expect(
        NotificationText.message(
          sampleNotification(
            'r',
            kind: NotificationKind.ratingReceived,
            withListing: false,
          ),
          fr,
        ),
        fr.notificationRatingNoListing,
      );
      expect(
        NotificationText.message(
          sampleNotification(
            's',
            kind: NotificationKind.listingSold,
            withListing: false,
            title: 'Vendue',
          ),
          fr,
        ),
        userText('Vendue'),
      );
    });

    test('une icône par type', () {
      final icons = {
        for (final kind in NotificationKind.values) NotificationText.icon(kind),
      };
      expect(icons, hasLength(NotificationKind.values.length));
    });
  });
}
