import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:afrimarket_mobile/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:afrimarket_mobile/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/snackbar_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_empty_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_error_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_load_more_indicator.dart';
import 'package:afrimarket_mobile/shared/widgets/app_skeleton.dart';
import 'package:afrimarket_mobile/shared/widgets/auth_gate.dart';
import 'package:afrimarket_mobile/shared/widgets/sign_in_prompt_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Onglet Notifications (maquette page 11), comme Facebook.
///
/// - visiteur : invitation à se connecter ;
/// - connecté : plus récentes d'abord ; non lues surlignées ; toucher
///   marque comme lue et ouvre l'annonce ; « Tout marquer comme lu » ;
///   glisser pour retirer (« Annuler » possible) ; tirer pour actualiser,
///   mise à jour en temps réel, page suivante ;
/// - la pastille de l'onglet s'efface quand il est affiché (`AppShell`).
class NotificationsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final signedIn = ref.watch(sessionProvider) == SessionStatus.authenticated;
    final hasUnread =
        signedIn &&
        ref.watch(notificationsControllerProvider.select((s) => s.hasUnread));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navNotifications),
        actions: [
          if (signedIn)
            IconButton(
              tooltip: l10n.notificationsMarkAllRead,
              icon: const Icon(AppIcons.checks),
              onPressed: hasUnread
                  ? () => unawaited(
                      ref
                          .read(notificationsControllerProvider.notifier)
                          .markAllRead(),
                    )
                  : null,
            ),
        ],
      ),
      body: AuthGate(
        signInPrompt: SignInPromptView(
          icon: AppIcons.bell,
          title: l10n.signInNotificationsTitle,
          message: l10n.signInNotificationsMessage,
        ),
        child: const _NotificationsList(),
      ),
    );
  }
}

class _NotificationsList extends ConsumerWidget {
  const new();

  /// Distance au bas de la liste (px) à partir de laquelle la page
  /// suivante est demandée.
  static const double loadMoreThreshold = 400;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);

    ref.listen<Failure?>(
      notificationsControllerProvider.select((s) => s.actionFailure),
      (_, failure) {
        if (failure == null) return;
        context.showAppSnackBar(failure.message(context.l10n));
        controller.actionFailureShown();
      },
    );

    void open(AppNotification item) {
      unawaited(controller.markRead(item.id));
      final listing = item.listing;
      if (item.kind == NotificationKind.message) {
        context.go(AppRoutes.messages);
      } else if (listing != null) {
        unawaited(context.push(AppRoutes.listing(listing.id)));
      }
    }

    void delete(AppNotification item) {
      final index = controller.remove(item.id);
      if (index < 0) return;
      final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
      final snackBar = messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.notificationDeleted),
          // Disparaît seul : la suppression n'est faite qu'à la fermeture.
          persist: false,
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => controller.restore(item, index),
          ),
        ),
      );
      unawaited(
        snackBar.closed.then((reason) {
          if (reason != SnackBarClosedReason.action) {
            unawaited(controller.confirmRemove(item, index));
          }
        }),
      );
    }

    switch (state.phase) {
      case NotificationsPhase.loading:
        return const _NotificationsSkeleton();
      case NotificationsPhase.failed:
        return AppErrorState(
          failure: state.failure ?? const UnexpectedFailure(),
          onRetry: () => unawaited(controller.refresh()),
        );
      case NotificationsPhase.ready:
        break;
    }

    if (state.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: AppEmptyState(
                icon: AppIcons.bell,
                title: l10n.notificationsEmptyTitle,
                message: l10n.notificationsEmptyMessage,
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
            final item = items[index];
            return NotificationTile(
              notification: item,
              onTap: () => open(item),
              onDelete: () => delete(item),
            );
          },
        ),
      ),
    );
  }
}

/// Squelette de la liste : mêmes proportions que les lignes.
class _NotificationsSkeleton extends StatelessWidget {
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
                width: NotificationTile.leadingSize,
                height: NotificationTile.leadingSize,
                borderRadius: AppRadius.sm,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonBox(height: 14),
                    SizedBox(height: AppSpacing.sm),
                    AppSkeletonBox(width: 180, height: 14),
                    SizedBox(height: AppSpacing.sm),
                    AppSkeletonBox(width: 80, height: 12),
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
