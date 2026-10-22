import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/realtime/realtime_connection.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/theme/app_theme.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/chat_message.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/cursor_page.dart';
import 'package:afrimarket_mobile/features/messaging/domain/messaging_conflicts.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/pages/conversation_page.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/pages/messages_page.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/widgets/conversation_tile.dart';
import 'package:afrimarket_mobile/shared/formatters/price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/fake_messaging_repository.dart';
import '../../../helpers/fake_realtime_connection.dart';
import '../../../helpers/fake_unread_counts_repository.dart';
import '../../../helpers/l10n.dart';

class _Session extends SessionNotifier {
  new(this._initial);

  final SessionStatus _initial;

  @override
  SessionStatus build() => _initial;
}

void main() {
  late FakeMessagingRepository messaging;
  late FakeRealtimeConnection realtime;

  setUp(() {
    messaging = FakeMessagingRepository();
    realtime = FakeRealtimeConnection();
  });

  /// Ouvre [location] dans un vrai routeur (Messages, discussion, annonce,
  /// fil, Publier) et attend la fin des chargements.
  Future<GoRouter> pump(
    WidgetTester tester, {
    String location = AppRoutes.messages,
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
          path: AppRoutes.publish,
          builder: (_, _) => const Text('PUBLIER'),
        ),
        GoRoute(
          path: AppRoutes.messages,
          builder: (_, _) => const MessagesPage(),
        ),
        GoRoute(
          path: AppRoutes.conversationPattern,
          builder: (_, state) =>
              ConversationPage(conversationId: state.pathParameters['id']!),
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
        ...messagingOverrides(messaging),
        ...realtimeOverrides(realtime),
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
    return router;
  }

  group('Messages', () {
    testWidgets('visiteur : invitation à se connecter', (tester) async {
      await pump(tester, session: SessionStatus.unauthenticated);

      expect(find.text(fr.signInMessagesTitle), findsOneWidget);
      expect(messaging.conversationCalls, isEmpty);
    });

    testWidgets('onglet Achat : discussions, statut, aperçu, non-lus', (
      tester,
    ) async {
      messaging.conversationsByRole[ConversationRole.buying] = CursorPage(
        items: [
          sampleConversation(unread: 2),
          sampleConversation(
            id: 'c2',
            name: 'Youssef B.',
            status: ConversationListingStatus.reserved,
            preview: 'D’accord pour samedi.',
            lastIsMine: true,
          ),
        ],
      );
      messaging.conversationsByRole[ConversationRole.selling] = CursorPage(
        items: [sampleConversation(id: 'c3', unread: 1)],
      );
      await pump(tester);

      expect(find.byType(ConversationTile), findsNWidgets(2));
      expect(find.textContaining('Aminata K.'), findsOneWidget);
      expect(find.text(fr.listingStatusReserved), findsOneWidget);
      expect(find.textContaining(fr.messagesFromMe('')), findsOneWidget);
      expect(find.textContaining(formatPrice(1200, fr)), findsNWidgets(2));
      // Pastilles : la discussion, l'onglet Achat (2) et l'onglet Vente (1).
      expect(find.widgetWithText(UnreadPill, '2'), findsNWidgets(2));
      expect(find.widgetWithText(UnreadPill, '1'), findsOneWidget);
    });

    testWidgets('compte et annonce supprimés', (tester) async {
      messaging.conversationsByRole[ConversationRole.buying] = CursorPage(
        items: [sampleConversation(name: null, withListing: false)],
      );
      await pump(tester);

      expect(find.text(fr.messagesDeletedAccount), findsOneWidget);
      expect(find.text(fr.messagesListingDeleted), findsOneWidget);
    });

    testWidgets('onglet Vente vide : Publier ; Achat vide : le fil', (
      tester,
    ) async {
      final router = await pump(tester);

      expect(find.text(fr.messagesEmptyBuyingTitle), findsOneWidget);
      await tester.tap(find.text(fr.messagesTabSelling));
      await tester.pumpAndSettle();
      expect(find.text(fr.messagesEmptySellingTitle), findsOneWidget);

      await tester.tap(find.text(fr.messagesEmptySellingAction));
      await tester.pumpAndSettle();
      expect(find.text('PUBLIER'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text(fr.messagesTabBuying));
      await tester.pumpAndSettle();
      await tester.tap(find.text(fr.messagesEmptyBuyingAction));
      await tester.pumpAndSettle();
      expect(find.text('FIL'), findsOneWidget);
    });

    testWidgets('erreur : message et Réessayer', (tester) async {
      messaging.conversationsAnswer = const Err(NetworkFailure());
      await pump(tester);

      expect(find.text(fr.errorNetwork), findsWidgets);

      messaging.conversationsAnswer = null;
      await tester.tap(find.text(fr.retry).first);
      await tester.pumpAndSettle();
      expect(find.text(fr.messagesEmptyBuyingTitle), findsOneWidget);
    });

    testWidgets('ouvrir une discussion : pastille retirée, liste relue', (
      tester,
    ) async {
      messaging
        ..conversationsByRole[ConversationRole.buying] = CursorPage(
          items: [sampleConversation(unread: 2)],
        )
        ..conversationAnswer = Ok(sampleConversation());
      await pump(tester);
      final calls = messaging.conversationCalls.length;

      await tester.tap(find.byType(ConversationTile));
      await tester.pumpAndSettle();
      expect(find.byType(ConversationPage), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(MessagesPage), findsOneWidget);
      expect(messaging.conversationCalls.length, greaterThan(calls));
    });

    for (final (label, locale, mode, scale) in [
      ('sombre', const Locale('fr'), ThemeMode.dark, 1.0),
      ('arabe', const Locale('ar'), ThemeMode.light, 1.0),
      ('texte ×2', const Locale('fr'), ThemeMode.light, 2.0),
    ]) {
      testWidgets('$label : aucun débordement', (tester) async {
        messaging.conversationsByRole[ConversationRole.buying] = CursorPage(
          items: [
            sampleConversation(
              unread: 120,
              status: ConversationListingStatus.sold,
              preview: 'Un message assez long pour être coupé ' * 3,
            ),
          ],
        );
        await pump(tester, locale: locale, themeMode: mode, textScale: scale);

        expect(tester.takeException(), isNull);
        expect(find.byType(ConversationTile), findsOneWidget);
      });
    }
  });

  group('Discussion', () {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    setUp(() {
      messaging.conversationAnswer = Ok(sampleConversation());
      messaging.messagesAnswers
        ..clear()
        ..add(
          Ok(
            CursorPage(
              items: [
                sampleMessage('m3', text: 'Parfait, à samedi.', sentAt: today),
                sampleMessage(
                  'm2',
                  mine: true,
                  text: 'Samedi au Maârif ?',
                  sentAt: today,
                  readAt: today,
                ),
                sampleMessage('m1', text: 'Bonjour !', sentAt: yesterday),
              ],
            ),
          ),
        );
    });

    Future<GoRouter> open(
      WidgetTester tester, {
      Locale locale = const Locale('fr'),
      ThemeMode themeMode = ThemeMode.light,
      double textScale = 1,
    }) => pump(
      tester,
      location: AppRoutes.conversation('conv-1'),
      locale: locale,
      themeMode: themeMode,
      textScale: textScale,
    );

    testWidgets('en-tête, annonce, conseil, jours, bulles et « Vu »', (
      tester,
    ) async {
      await open(tester);

      expect(find.textContaining('Aminata K.'), findsOneWidget);
      expect(find.textContaining('Canapé 3 places'), findsOneWidget);
      expect(find.textContaining(fr.chatSafetyTitle), findsOneWidget);
      expect(find.text(fr.chatToday), findsOneWidget);
      expect(find.text(fr.messagesYesterday), findsOneWidget);
      expect(find.textContaining('Samedi au Maârif'), findsOneWidget);
      expect(find.textContaining(fr.chatSeen), findsOneWidget);
    });

    testWidgets('annonce : ouvre son détail', (tester) async {
      await open(tester);

      await tester.tap(find.textContaining('Canapé 3 places'));
      await tester.pumpAndSettle();

      expect(find.text('ANNONCE listing-1'), findsOneWidget);
    });

    testWidgets('conseil de sécurité : masqué', (tester) async {
      await open(tester);

      await tester.tap(find.byTooltip(fr.chatSafetyDismiss));
      await tester.pumpAndSettle();

      expect(find.textContaining(fr.chatSafetyTitle), findsNothing);
    });

    testWidgets('envoyer : bouton actif avec du texte, message affiché', (
      tester,
    ) async {
      await open(tester);
      final send = find.byTooltip(fr.chatSend);

      IconButton button() => tester.widget<IconButton>(
        find.ancestor(of: send, matching: find.byType(IconButton)),
      );
      expect(button().onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Je confirme.');
      await tester.pump();
      expect(button().onPressed, isNotNull);
      await tester.tap(send);
      await tester.pumpAndSettle();

      expect(messaging.sentInConversation.single, ('conv-1', 'Je confirme.'));
      expect(find.textContaining('Je confirme.'), findsOneWidget);
    });

    testWidgets('envoi en échec : message, nouvel essai', (tester) async {
      messaging.sendAnswer = const Err(
        ConflictFailure(code: MessagingConflicts.recipientUnavailable),
      );
      await open(tester);

      await tester.enterText(find.byType(TextField), 'Bonjour');
      await tester.pump();
      await tester.tap(find.byTooltip(fr.chatSend));
      await tester.pumpAndSettle();

      expect(find.text(fr.chatRecipientUnavailable), findsOneWidget);
      expect(find.text(fr.chatNotSent), findsOneWidget);

      messaging.sendAnswer = null;
      await tester.tap(find.text(fr.chatNotSent));
      await tester.pumpAndSettle();
      expect(find.text(fr.chatNotSent), findsNothing);
      expect(messaging.sentInConversation, hasLength(2));
    });

    testWidgets('message non envoyé : retiré', (tester) async {
      messaging.sendAnswer = const Err(NetworkFailure());
      await open(tester);

      await tester.enterText(find.byType(TextField), 'Bonjour');
      await tester.pump();
      await tester.tap(find.byTooltip(fr.chatSend));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(fr.chatDiscard));
      await tester.pumpAndSettle();

      expect(find.text(fr.chatNotSent), findsNothing);
    });

    testWidgets('compte suspendu : plus de champ, une explication', (
      tester,
    ) async {
      messaging.conversationAnswer = Ok(sampleConversation(canReceive: false));
      await open(tester);

      expect(find.byType(TextField), findsNothing);
      expect(find.text(fr.chatRecipientUnavailable), findsOneWidget);
    });

    testWidgets('discussion vide : invitation à écrire', (tester) async {
      messaging.messagesAnswers
        ..clear()
        ..add(const Ok(CursorPage<ChatMessage>(items: [])));
      await open(tester);

      expect(find.text(fr.chatEmpty), findsOneWidget);
    });

    testWidgets('introuvable : erreur, Réessayer', (tester) async {
      messaging.conversationAnswer = const Err(NotFoundFailure());
      await open(tester);

      expect(find.text(fr.errorNotFound), findsOneWidget);
      expect(find.text(fr.chatTitleFallback), findsOneWidget);

      messaging.conversationAnswer = Ok(sampleConversation());
      await tester.tap(find.text(fr.retry));
      await tester.pumpAndSettle();
      expect(find.textContaining('Aminata K.'), findsOneWidget);
    });

    testWidgets('nouveau message reçu : affiché sans recharger la page', (
      tester,
    ) async {
      await open(tester);
      messaging.messagesAnswers
        ..clear()
        ..add(
          Ok(
            CursorPage(
              items: [
                sampleMessage('m4', text: 'Je suis en bas.', sentAt: today),
              ],
            ),
          ),
        );

      realtime.emit(RealtimeEvent.message);
      await tester.pumpAndSettle();

      expect(find.textContaining('Je suis en bas.'), findsOneWidget);
      expect(find.textContaining('Parfait, à samedi.'), findsOneWidget);
    });

    testWidgets('messages précédents : chargés en remontant', (tester) async {
      messaging.messagesAnswers
        ..clear()
        ..addAll([
          Ok(
            CursorPage(
              items: [
                for (var i = 30; i > 0; i--)
                  sampleMessage(
                    'm$i',
                    text: 'Message numéro $i',
                    sentAt: today,
                  ),
              ],
              nextCursor: 'm1',
            ),
          ),
          Ok(
            CursorPage(
              items: [
                sampleMessage('m0', text: 'Le tout premier', sentAt: today),
              ],
            ),
          ),
        ]);
      await open(tester);

      await tester.fling(find.byType(ListView), const Offset(0, 3000), 3000);
      await tester.pumpAndSettle();

      expect(messaging.messagesCalls, contains('m1'));
    });

    for (final (label, locale, mode, scale) in [
      ('sombre', const Locale('fr'), ThemeMode.dark, 1.0),
      ('arabe', const Locale('ar'), ThemeMode.light, 1.0),
      ('texte ×2', const Locale('fr'), ThemeMode.light, 2.0),
    ]) {
      testWidgets('$label : aucun débordement', (tester) async {
        await open(tester, locale: locale, themeMode: mode, textScale: scale);

        expect(tester.takeException(), isNull);
        expect(find.byType(TextField), findsOneWidget);
      });
    }
  });
}
