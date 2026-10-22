import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/controllers/conversations_controller.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/widgets/conversation_tile.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/snackbar_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_empty_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_error_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_load_more_indicator.dart';
import 'package:afrimarket_mobile/shared/widgets/app_skeleton.dart';
import 'package:afrimarket_mobile/shared/widgets/auth_gate.dart';
import 'package:afrimarket_mobile/shared/widgets/sign_in_prompt_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Onglet Messages (maquette page 6) : discussions en deux onglets,
/// Achat et Vente, dernier message en premier.
///
/// - visiteur : invitation à se connecter ;
/// - connecté : liste paginée, tirer pour actualiser, actualisée aussi à
///   chaque nouveau message reçu (temps réel) et au retour d'une
///   discussion ;
/// - états : squelettes, vide (avec une action), erreur.
class MessagesPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMessages)),
      body: AuthGate(
        signInPrompt: SignInPromptView(
          icon: AppIcons.chatCircle,
          title: l10n.signInMessagesTitle,
          message: l10n.signInMessagesMessage,
        ),
        child: const _Inbox(),
      ),
    );
  }
}

class _Inbox extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_Inbox> createState() => _InboxState();
}

class _InboxState extends ConsumerState<_Inbox> {
  ConversationRole _role = ConversationRole.buying;

  Future<void> _open(ConversationSummary conversation) async {
    ref
        .read(conversationsControllerProvider(conversation.role).notifier)
        .markRead(conversation.id);
    await context.push(AppRoutes.conversation(conversation.id));
    if (!mounted) return;
    // Retour : ordre et derniers messages ont pu changer.
    for (final role in ConversationRole.values) {
      unawaited(
        ref.read(conversationsControllerProvider(role).notifier).refresh(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Les deux onglets restent chargés : passage instantané, et pastilles.
    final buying = ref.watch(
      conversationsControllerProvider(ConversationRole.buying),
    );
    final selling = ref.watch(
      conversationsControllerProvider(ConversationRole.selling),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l10n.messagesTabsLabel,
          container: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.page,
              AppSpacing.xs,
              AppSpacing.page,
              AppSpacing.md,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _RoleTab(
                  label: l10n.messagesTabBuying,
                  unread: buying.unreadCount,
                  selected: _role == ConversationRole.buying,
                  onTap: () => setState(() => _role = ConversationRole.buying),
                ),
                _RoleTab(
                  label: l10n.messagesTabSelling,
                  unread: selling.unreadCount,
                  selected: _role == ConversationRole.selling,
                  onTap: () => setState(() => _role = ConversationRole.selling),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _ConversationList(
            key: ValueKey(_role),
            role: _role,
            onOpen: (conversation) => unawaited(_open(conversation)),
          ),
        ),
      ],
    );
  }
}

/// Onglet Achat ou Vente, avec ses non-lus.
class _RoleTab extends StatelessWidget {
  const new({
    required this.label,
    required this.unread,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int unread;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: colors.brandSoft,
      labelStyle: context.textStyles.bodyMedium?.copyWith(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        color: selected ? colors.onBrandSoft : colors.textPrimary,
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (unread > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            UnreadPill(count: unread),
          ],
        ],
      ),
    );
  }
}

class _ConversationList extends ConsumerWidget {
  const new({required this.role, required this.onOpen, super.key});

  /// Distance au bas de la liste (px) à partir de laquelle la page
  /// suivante est demandée.
  static const double loadMoreThreshold = 400;

  final ConversationRole role;
  final ValueChanged<ConversationSummary> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = conversationsControllerProvider(role);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    ref.listen<Failure?>(provider.select((s) => s.refreshFailure), (
      _,
      failure,
    ) {
      if (failure == null) return;
      context.showAppSnackBar(failure.message(context.l10n));
      controller.refreshFailureShown();
    });

    switch (state.phase) {
      case ListPhase.loading:
        return const _ConversationListSkeleton();
      case ListPhase.failed:
        return AppErrorState(
          failure: state.failure ?? const UnexpectedFailure(),
          onRetry: () => unawaited(controller.refresh()),
        );
      case ListPhase.ready:
        break;
    }

    if (state.isEmpty) {
      final buying = role == ConversationRole.buying;
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: AppEmptyState(
                icon: AppIcons.chatCircle,
                title: buying
                    ? l10n.messagesEmptyBuyingTitle
                    : l10n.messagesEmptySellingTitle,
                message: buying
                    ? l10n.messagesEmptyBuyingMessage
                    : l10n.messagesEmptySellingMessage,
                actionLabel: buying
                    ? l10n.messagesEmptyBuyingAction
                    : l10n.messagesEmptySellingAction,
                onAction: () => buying
                    ? context.go(AppRoutes.home)
                    : unawaited(context.push(AppRoutes.publish)),
              ),
            ),
          ),
        ),
      );
    }

    final items = state.items;
    final footer = state.loadMoreFailure != null || state.isLoadingMore;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < loadMoreThreshold) {
            unawaited(controller.loadMore());
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length + (footer ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == items.length) {
              final failure = state.loadMoreFailure;
              return failure == null
                  ? const AppLoadMoreIndicator()
                  : AppErrorState(
                      failure: failure,
                      compact: true,
                      onRetry: () => unawaited(controller.retryLoadMore()),
                    );
            }
            final conversation = items[index];
            return ConversationTile(
              conversation: conversation,
              onTap: () => onOpen(conversation),
            );
          },
        ),
      ),
    );
  }
}

/// Squelette de la liste : mêmes proportions que les lignes.
class _ConversationListSkeleton extends StatelessWidget {
  const new();

  static const int rows = 6;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonPulse(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.page,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              AppSkeletonBox(
                width: ConversationTile.photoSize,
                height: ConversationTile.photoSize,
                borderRadius: AppRadius.sm,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonBox(width: 140, height: 14),
                    SizedBox(height: AppSpacing.sm),
                    AppSkeletonBox(width: 200, height: 12),
                    SizedBox(height: AppSpacing.sm),
                    AppSkeletonBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
