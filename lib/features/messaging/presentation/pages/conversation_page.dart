import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_controller.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/chat_message.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:afrimarket_mobile/features/messaging/domain/messaging_conflicts.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/controllers/chat_controller.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/controllers/conversations_controller.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/message_time.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/widgets/chat_bubble.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/widgets/chat_composer.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/widgets/chat_header.dart';
import 'package:afrimarket_mobile/features/safety/domain/safety_conflicts.dart';
import 'package:afrimarket_mobile/features/safety/presentation/widgets/safety_dialogs.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/snackbar_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:afrimarket_mobile/shared/widgets/app_error_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_load_more_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Une discussion (maquette page 9).
///
/// - en-tête : l'autre personne ; dessous, l'annonce (mène à son détail) ;
/// - conseil de sécurité, que l'on peut masquer ;
/// - messages du plus ancien (haut) au plus récent (bas), séparés par
///   jour ; « Vu » sous mon dernier message lu ; les précédents se
///   chargent en remontant ;
/// - envoi affiché tout de suite ; non envoyé : nouvel essai ou retrait ;
/// - compte de l'autre personne suspendu ou supprimé, ou blocage : plus de
///   champ ;
/// - menu « ··· » : bloquer / débloquer, signaler (comme Messenger).
class ConversationPage extends ConsumerStatefulWidget {
  const new({required this.conversationId, super.key});

  /// Distance au haut de la discussion (px) à partir de laquelle les
  /// messages précédents sont demandés.
  static const double loadOlderThreshold = 400;

  final String conversationId;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  bool _showTip = true;

  ChatController get _chat =>
      ref.read(chatControllerProvider(widget.conversationId).notifier);

  /// Nom affiché de l'autre personne (isolé comme un texte saisi).
  String _name(ConversationPerson person, AppLocalizations l10n) {
    final name = person.name;
    return name == null ? l10n.messagesDeletedAccount : userText(name);
  }

  /// Résultat d'une action de sécurité : message, puis fil actualisé
  /// (les annonces de la personne bloquée disparaissent, ou reviennent).
  void _afterSafetyAction(Failure? failure, String success) {
    if (!mounted) return;
    if (failure != null) {
      context.showAppSnackBar(_safetyFailureMessage(failure));
      return;
    }
    unawaited(HapticFeedback.lightImpact());
    unawaited(ref.read(feedControllerProvider.notifier).refresh());
    context.showAppSnackBar(success);
  }

  String _safetyFailureMessage(Failure failure) {
    final l10n = context.l10n;
    return switch (failure) {
      ConflictFailure(code: SafetyConflicts.alreadyReported) =>
        l10n.safetyAlreadyReported,
      _ => failure.message(l10n),
    };
  }

  Future<void> _block(ConversationPerson person) async {
    final name = _name(person, context.l10n);
    if (!await confirmBlock(context, name) || !mounted) return;
    final failure = await _chat.block();
    if (!mounted) return;
    _afterSafetyAction(failure, context.l10n.safetyBlocked(name));
  }

  Future<void> _unblock(ConversationPerson person) async {
    final name = _name(person, context.l10n);
    final failure = await _chat.unblock();
    if (!mounted) return;
    _afterSafetyAction(failure, context.l10n.safetyUnblocked(name));
  }

  Future<void> _report(ConversationSummary header) async {
    final name = _name(header.otherUser, context.l10n);
    final report = await showReportPersonSheet(
      context,
      name: name,
      alreadyBlocked: header.blockedByMe,
    );
    if (report == null || !mounted) return;
    final failure = await _chat.report(
      reason: report.reason,
      details: report.details,
      alsoBlock: report.alsoBlock,
    );
    if (!mounted) return;
    _afterSafetyAction(
      failure,
      report.alsoBlock
          ? context.l10n.safetyReportSentBlocked(name)
          : context.l10n.safetyReportSent,
    );
  }

  Future<void> _openMenu(ConversationSummary header) async {
    final l10n = context.l10n;
    final colors = context.colors;
    final choice = await showModalBottomSheet<VoidCallback>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (header.blockedByMe)
              ListTile(
                key: const Key('chat-menu-unblock'),
                leading: const Icon(AppIcons.prohibit),
                title: Text(l10n.safetyUnblock),
                onTap: () =>
                    Navigator.of(sheetContext)
                        .pop(() => unawaited(_unblock(header.otherUser))),
              )
            else
              ListTile(
                key: const Key('chat-menu-block'),
                leading: Icon(AppIcons.prohibit, color: colors.error),
                title: Text(
                  l10n.safetyBlock,
                  style: TextStyle(color: colors.error),
                ),
                onTap: () =>
                    Navigator.of(sheetContext)
                        .pop(() => unawaited(_block(header.otherUser))),
              ),
            ListTile(
              key: const Key('chat-menu-report'),
              leading: const Icon(AppIcons.flag),
              title: Text(l10n.safetyReport),
              onTap: () =>
                  Navigator.of(sheetContext)
                      .pop(() => unawaited(_report(header))),
            ),
          ],
        ),
      ),
    );
    choice?.call();
  }

  String _sendFailureMessage(Failure failure, AppLocalizations l10n) {
    return switch (failure) {
      ConflictFailure(code: MessagingConflicts.recipientUnavailable) =>
        l10n.chatRecipientUnavailable,
      _ => failure.message(l10n),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = chatControllerProvider(widget.conversationId);
    final state = ref.watch(provider);
    final header = state.header;
    final listing = header?.listing;

    ref.listen<Failure?>(provider.select((chat) => chat.sendFailure), (
      _,
      failure,
    ) {
      if (failure == null) return;
      context.showAppSnackBar(_sendFailureMessage(failure, context.l10n));
      _chat.sendFailureShown();
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: ChatTitle(person: header?.otherUser),
        actions: [
          if (header != null)
            IconButton(
              tooltip: l10n.listingMoreTooltip,
              icon: const Icon(AppIcons.dotsThree),
              onPressed: () => unawaited(_openMenu(header)),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (listing != null)
            ChatListingBar(
              listing: listing,
              onTap: () =>
                  unawaited(context.push(AppRoutes.listing(listing.id))),
            ),
          Expanded(child: _body(state)),
          if (state.phase == ListPhase.ready && header != null)
            if (header.blockedByMe)
              _Notice(
                text: l10n.safetyBlockedBanner(_name(header.otherUser, l10n)),
                actionLabel: l10n.safetyUnblock,
                onAction: () => unawaited(_unblock(header.otherUser)),
              )
            else if (state.canSend)
              ChatComposer(onSend: (text) => unawaited(_chat.send(text)))
            else
              _Notice(text: l10n.chatRecipientUnavailable),
        ],
      ),
    );
  }

  Widget _body(ChatState state) {
    switch (state.phase) {
      case ListPhase.loading:
        return const Center(child: CircularProgressIndicator());
      case ListPhase.failed:
        return AppErrorState(
          failure: state.failure ?? const UnexpectedFailure(),
          onRetry: () => unawaited(_chat.retry()),
        );
      case ListPhase.ready:
        break;
    }

    final l10n = context.l10n;
    final rows = _rows(state, l10n);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Liste inversée : le haut de la discussion est à la fin.
        if (notification.metrics.extentAfter <
            ConversationPage.loadOlderThreshold) {
          unawaited(_chat.loadOlder());
        }
        return false;
      },
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.page,
          vertical: AppSpacing.md,
        ),
        itemCount: rows.length,
        itemBuilder: (context, index) => rows[index],
      ),
    );
  }

  /// Lignes du bas (plus récent) vers le haut : envois en cours, messages,
  /// séparateurs de jour, chargement des précédents, conseil de sécurité.
  List<Widget> _rows(ChatState state, AppLocalizations l10n) {
    final rows = <Widget>[];
    final messages = state.messages;
    final pending = state.pending;

    for (final item in pending.reversed) {
      rows.add(
        _spaced(
          ChatBubble(
            text: item.text,
            isMine: true,
            delivery: item.failed
                ? BubbleDelivery.failed
                : BubbleDelivery.sending,
            meta: item.failed ? l10n.chatNotSent : l10n.chatSending,
            onRetry: () => unawaited(_chat.resend(item.localId)),
            onDiscard: () => _chat.discard(item.localId),
          ),
        ),
      );
    }

    final lastSeen = _lastSeenMine(messages);
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final newer = i == 0 ? null : messages[i - 1];
      final older = i + 1 < messages.length ? messages[i + 1] : null;
      // Heure sous le dernier message d'une suite du même auteur.
      final endsGroup =
          (i == 0 && pending.isEmpty) ||
          (newer != null && newer.isMine != message.isMine) ||
          (newer != null && !MessageTime.sameDay(newer.sentAt, message.sentAt));
      final time = MessageTime.time(message.sentAt, l10n);
      final seen = identical(message, lastSeen);
      rows.add(
        _spaced(
          ChatBubble(
            text: message.text,
            isMine: message.isMine,
            meta: seen
                ? '$time · ${l10n.chatSeen}'
                : endsGroup
                ? time
                : null,
          ),
          tight: older != null && older.isMine == message.isMine,
        ),
      );
      final dayStarts = older == null
          ? !state.canLoadOlder && !state.isLoadingOlder
          : !MessageTime.sameDay(older.sentAt, message.sentAt);
      if (dayStarts) {
        rows.add(_DaySeparator(MessageTime.day(message.sentAt, l10n)));
      }
    }

    if (messages.isEmpty && pending.isEmpty) {
      rows.add(_EmptyHint(text: l10n.chatEmpty));
    }

    final olderFailure = state.olderFailure;
    if (olderFailure != null) {
      rows.add(
        AppErrorState(
          failure: olderFailure,
          compact: true,
          onRetry: () => unawaited(_chat.retryOlder()),
        ),
      );
    } else if (state.isLoadingOlder) {
      rows.add(const AppLoadMoreIndicator());
    }

    if (_showTip && !state.canLoadOlder) {
      rows.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
          child: ChatSafetyTip(
            onDismiss: () => setState(() => _showTip = false),
          ),
        ),
      );
    }
    return rows;
  }

  /// Mon message le plus récent, s'il a été lu (« Vu »).
  static ChatMessage? _lastSeenMine(List<ChatMessage> messages) {
    for (final message in messages) {
      if (message.isMine) return message.readAt == null ? null : message;
    }
    return null;
  }

  static Widget _spaced(Widget child, {bool tight = false}) => Padding(
    padding: EdgeInsetsDirectional.only(
      top: tight ? AppSpacing.xs / 2 : AppSpacing.sm,
    ),
    child: child,
  );
}

class _DaySeparator extends StatelessWidget {
  const new(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.md),
      child: Semantics(
        header: true,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xl),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.textStyles.bodyMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

/// À la place du champ : on ne peut plus écrire (et, si on a bloqué la
/// personne, « Débloquer »).
class _Notice extends StatelessWidget {
  const new({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  key: const Key('chat-unblock'),
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
