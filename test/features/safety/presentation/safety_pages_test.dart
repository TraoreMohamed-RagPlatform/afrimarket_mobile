import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/theme/app_theme.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/pages/conversation_page.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/person_report_reason.dart';
import 'package:afrimarket_mobile/features/safety/domain/safety_conflicts.dart';
import 'package:afrimarket_mobile/features/safety/presentation/pages/blocked_people_page.dart';
import 'package:afrimarket_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/fake_listings_repository.dart';
import '../../../helpers/fake_messaging_repository.dart';
import '../../../helpers/fake_realtime_connection.dart';
import '../../../helpers/fake_safety_repository.dart';
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
  late FakeMessagingRepository messaging;
  late FakeSafetyRepository safety;
  late FakeListingsRepository listings;

  setUp(() {
    messaging = FakeMessagingRepository()
      ..conversationAnswer = Ok(sampleConversation());
    safety = FakeSafetyRepository();
    listings = FakeListingsRepository();
  });

  Future<void> pump(
    WidgetTester tester, {
    required String location,
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
      initialLocation: location,
      routes: [
        GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('FIL')),
        GoRoute(
          path: AppRoutes.conversationPattern,
          builder: (_, state) =>
              ConversationPage(conversationId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, _) => const SettingsPage(),
        ),
        GoRoute(
          path: AppRoutes.blockedPeople,
          builder: (_, _) => const BlockedPeoplePage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(() => _Session(session)),
        ...messagingOverrides(messaging),
        ...safetyOverrides(safety),
        ...listingsOverrides(listings),
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

  final chat = AppRoutes.conversation('conv-1');
  final name = userText('Aminata K.');

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip(fr.listingMoreTooltip));
    await tester.pumpAndSettle();
  }

  group('Discussion : bloquer', () {
    setUp(() {
      // Le serveur renvoie ensuite la discussion avec le blocage.
      safety.onChange = () => messaging.conversationAnswer = Ok(
        sampleConversation(blockedByMe: true, canReceive: false),
      );
    });

    testWidgets(
      'confirmation, puis bandeau « Débloquer » à la place du champ',
      (tester) async {
        await pump(tester, location: chat);
        expect(find.byType(TextField), findsOneWidget);

        await openMenu(tester);
        await tester.tap(find.byKey(const Key('chat-menu-block')));
        await tester.pumpAndSettle();
        expect(find.text(fr.safetyBlockTitle(name)), findsOneWidget);
        expect(find.text(fr.safetyBlockMessage(name)), findsOneWidget);

        await tester.tap(find.byKey(const Key('safety-block-confirm')));
        await tester.pumpAndSettle();

        expect(safety.blocked, ['user-conv-1']);
        expect(find.text(fr.safetyBlocked(name)), findsOneWidget);
        expect(find.text(fr.safetyBlockedBanner(name)), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        // Le fil est relu : ses annonces disparaissent.
        expect(listings.feedCalls, isNotEmpty);
      },
    );

    testWidgets('annuler : rien ne change', (tester) async {
      await pump(tester, location: chat);

      await openMenu(tester);
      await tester.tap(find.byKey(const Key('chat-menu-block')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(fr.safetyCancel));
      await tester.pumpAndSettle();

      expect(safety.blocked, isEmpty);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('échec : message, le champ reste', (tester) async {
      safety.blockAnswer = const Err(NetworkFailure());
      await pump(tester, location: chat);

      await openMenu(tester);
      await tester.tap(find.byKey(const Key('chat-menu-block')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('safety-block-confirm')));
      await tester.pumpAndSettle();

      expect(find.text(fr.errorNetwork), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('Discussion : débloquer', () {
    setUp(() {
      messaging.conversationAnswer = Ok(
        sampleConversation(blockedByMe: true, canReceive: false),
      );
      safety.onChange = () =>
          messaging.conversationAnswer = Ok(sampleConversation());
    });

    testWidgets('depuis le bandeau : le champ revient', (tester) async {
      await pump(tester, location: chat);
      expect(find.text(fr.safetyBlockedBanner(name)), findsOneWidget);

      await tester.tap(find.byKey(const Key('chat-unblock')));
      await tester.pumpAndSettle();

      expect(safety.unblocked, ['user-conv-1']);
      expect(find.text(fr.safetyUnblocked(name)), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('depuis le menu', (tester) async {
      await pump(tester, location: chat);

      await openMenu(tester);
      expect(find.byKey(const Key('chat-menu-block')), findsNothing);
      await tester.tap(find.byKey(const Key('chat-menu-unblock')));
      await tester.pumpAndSettle();

      expect(safety.unblocked, ['user-conv-1']);
    });
  });

  testWidgets('bloquée par l’autre : explication neutre, pas de bandeau', (
    tester,
  ) async {
    messaging.conversationAnswer = Ok(sampleConversation(canReceive: false));
    await pump(tester, location: chat);

    expect(find.text(fr.chatRecipientUnavailable), findsOneWidget);
    expect(find.byKey(const Key('chat-unblock')), findsNothing);
  });

  group('Discussion : signaler', () {
    Future<void> openReport(WidgetTester tester) async {
      await openMenu(tester);
      await tester.tap(find.byKey(const Key('chat-menu-report')));
      await tester.pumpAndSettle();
    }

    testWidgets('motif, détail, messages joints annoncés, et bloquer aussi', (
      tester,
    ) async {
      safety.onChange = () => messaging.conversationAnswer = Ok(
        sampleConversation(blockedByMe: true, canReceive: false),
      );
      await pump(tester, location: chat);

      await openReport(tester);
      expect(find.text(fr.safetyReportTitle(name)), findsOneWidget);
      expect(
        find.text(
          fr.safetyReportMessagesNotice(PersonReportReason.copiedMessages),
        ),
        findsOneWidget,
      );
      final submit = find.byKey(const Key('safety-report-submit'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);

      await tester.tap(find.text(fr.safetyReasonScam));

      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('safety-report-details')),
        'Demande un acompte',
      );
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      final report = safety.reports.single;
      expect(report.userId, 'user-conv-1');
      expect(report.reason, PersonReportReason.scam);
      expect(report.details, 'Demande un acompte');
      expect(report.conversationId, 'conv-1');
      expect(safety.blocked, ['user-conv-1']);
      expect(find.text(fr.safetyReportSentBlocked(name)), findsOneWidget);
      expect(find.text(fr.safetyBlockedBanner(name)), findsOneWidget);
    });

    testWidgets('sans bloquer : décocher, signalement seul', (tester) async {
      await pump(tester, location: chat);

      await openReport(tester);
      await tester.tap(find.text(fr.safetyReasonHarassment));
      await tester.pump();
      await tester.tap(find.byKey(const Key('safety-report-also-block')));
      await tester.pump();
      final submit = find.byKey(const Key('safety-report-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(safety.reports.single.details, isNull);
      expect(safety.blocked, isEmpty);
      expect(find.text(fr.safetyReportSent), findsOneWidget);
    });

    testWidgets('déjà bloquée : pas de case « bloquer aussi »', (tester) async {
      messaging.conversationAnswer = Ok(
        sampleConversation(blockedByMe: true, canReceive: false),
      );
      await pump(tester, location: chat);

      await openReport(tester);

      expect(find.byKey(const Key('safety-report-also-block')), findsNothing);
    });

    testWidgets('déjà signalée : message clair', (tester) async {
      safety.reportAnswer = const Err(
        ConflictFailure(code: SafetyConflicts.alreadyReported),
      );
      await pump(tester, location: chat);

      await openReport(tester);
      await tester.tap(find.text(fr.safetyReasonSpam));
      await tester.pump();
      final submit = find.byKey(const Key('safety-report-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text(fr.safetyAlreadyReported), findsOneWidget);
      expect(safety.blocked, isEmpty);
    });

    testWidgets('fermer la feuille : rien n’est envoyé', (tester) async {
      await pump(tester, location: chat);

      await openReport(tester);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(safety.reports, isEmpty);
    });
  });

  group('Réglages', () {
    testWidgets('connecté : « Personnes bloquées » ouvre la liste', (
      tester,
    ) async {
      await pump(tester, location: AppRoutes.settings);

      expect(find.text(fr.settingsPrivacySection), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings-blocked-people')));
      await tester.pumpAndSettle();

      expect(find.byType(BlockedPeoplePage), findsOneWidget);
      expect(safety.listCalls, 1);
    });

    testWidgets('visiteur : pas d’entrée', (tester) async {
      await pump(
        tester,
        location: AppRoutes.settings,
        session: SessionStatus.unauthenticated,
      );

      expect(find.byKey(const Key('settings-blocked-people')), findsNothing);
      expect(find.text(fr.settingsComingSoon), findsOneWidget);
    });
  });

  group('Personnes bloquées', () {
    testWidgets('liste, puis débloquer après confirmation', (tester) async {
      safety.blockedAnswer = Ok([
        sampleBlocked('u1'),
        sampleBlocked('u2', name: null),
      ]);
      await pump(tester, location: AppRoutes.blockedPeople);

      final youssef = userText('Youssef B.');
      expect(find.text(youssef), findsOneWidget);
      expect(find.text(fr.messagesDeletedAccount), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('unblock-u1')));
      await tester.pumpAndSettle();
      expect(find.text(fr.safetyUnblockTitle(youssef)), findsOneWidget);
      await tester.tap(find.byKey(const Key('safety-unblock-confirm')));
      await tester.pumpAndSettle();

      expect(safety.unblocked, ['u1']);
      expect(find.text(youssef), findsNothing);
      expect(find.text(fr.safetyUnblocked(youssef)), findsOneWidget);
    });

    testWidgets('annuler : rien ne change', (tester) async {
      safety.blockedAnswer = Ok([sampleBlocked('u1')]);
      await pump(tester, location: AppRoutes.blockedPeople);

      await tester.tap(find.byKey(const ValueKey('unblock-u1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(fr.safetyCancel));
      await tester.pumpAndSettle();

      expect(safety.unblocked, isEmpty);
    });

    testWidgets('échec du déblocage : elle revient, message', (tester) async {
      safety
        ..blockedAnswer = Ok([sampleBlocked('u1')])
        ..unblockAnswer = const Err(NetworkFailure());
      await pump(tester, location: AppRoutes.blockedPeople);

      await tester.tap(find.byKey(const ValueKey('unblock-u1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('safety-unblock-confirm')));
      await tester.pumpAndSettle();

      expect(find.text(userText('Youssef B.')), findsOneWidget);
      expect(find.text(fr.errorNetwork), findsOneWidget);
    });

    testWidgets('vide : explication', (tester) async {
      await pump(tester, location: AppRoutes.blockedPeople);

      expect(find.text(fr.safetyBlockedPeopleEmptyTitle), findsOneWidget);
    });

    testWidgets('erreur, puis « Réessayer »', (tester) async {
      safety.blockedAnswer = const Err(NetworkFailure());
      await pump(tester, location: AppRoutes.blockedPeople);

      safety.blockedAnswer = Ok([sampleBlocked('u1')]);
      await tester.tap(find.text(fr.retry));
      await tester.pumpAndSettle();

      expect(find.text(userText('Youssef B.')), findsOneWidget);
    });

    testWidgets('tirer pour actualiser', (tester) async {
      safety.blockedAnswer = Ok([sampleBlocked('u1')]);
      await pump(tester, location: AppRoutes.blockedPeople);

      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(safety.listCalls, 2);
    });
  });

  group('Accessibilité', () {
    testWidgets('liste : mode sombre, arabe (RTL), texte ×2', (tester) async {
      safety.blockedAnswer = Ok([sampleBlocked('u1')]);
      await pump(
        tester,
        location: AppRoutes.blockedPeople,
        locale: const Locale('ar'),
        themeMode: ThemeMode.dark,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_ar.safetyBlockedPeopleTitle), findsOneWidget);
    });

    testWidgets('discussion bloquée et feuille : arabe, sombre, texte ×2', (
      tester,
    ) async {
      messaging.conversationAnswer = Ok(
        sampleConversation(blockedByMe: true, canReceive: false),
      );
      await pump(
        tester,
        location: chat,
        locale: const Locale('ar'),
        themeMode: ThemeMode.dark,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip(_ar.listingMoreTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-menu-report')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(_ar.safetyReasonFakeProfile), findsOneWidget);
    });
  });
}
