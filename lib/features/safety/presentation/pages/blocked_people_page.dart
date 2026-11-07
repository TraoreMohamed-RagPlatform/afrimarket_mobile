import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_controller.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/blocked_person.dart';
import 'package:afrimarket_mobile/features/safety/presentation/controllers/blocked_people_controller.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/snackbar_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:afrimarket_mobile/shared/widgets/app_empty_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_error_state.dart';
import 'package:afrimarket_mobile/shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Réglages → Personnes bloquées (comme Messenger) : on peut y débloquer
/// quelqu'un même sans discussion ouverte.
class BlockedPeoplePage extends ConsumerWidget {
  const new({super.key});

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    BlockedPerson person,
    String name,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.safetyUnblockTitle(name)),
        content: Text(l10n.safetyUnblockMessage(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.safetyCancel),
          ),
          TextButton(
            key: const Key('safety-unblock-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.safetyUnblock),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    final done = await ref
        .read(blockedPeopleControllerProvider.notifier)
        .unblock(person.userId);
    if (!done || !context.mounted) return;
    // Ses annonces réapparaissent dans le fil.
    unawaited(ref.read(feedControllerProvider.notifier).refresh());
    context.showAppSnackBar(context.l10n.safetyUnblocked(name));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(blockedPeopleControllerProvider);
    final controller = ref.read(blockedPeopleControllerProvider.notifier);

    ref.listen<Failure?>(
      blockedPeopleControllerProvider.select((s) => s.actionFailure),
      (_, failure) {
        if (failure == null) return;
        context.showAppSnackBar(failure.message(context.l10n));
        controller.actionFailureShown();
      },
    );

    final Widget body;
    switch (state.phase) {
      case BlockedPeoplePhase.loading:
        body = const Center(child: CircularProgressIndicator());
      case BlockedPeoplePhase.failed:
        body = AppErrorState(
          failure: state.failure ?? const UnexpectedFailure(),
          onRetry: () => unawaited(controller.refresh()),
        );
      case BlockedPeoplePhase.ready when state.isEmpty:
        body = AppEmptyState(
          icon: AppIcons.prohibit,
          title: l10n.safetyBlockedPeopleEmptyTitle,
          message: l10n.safetyBlockedPeopleEmptyMessage,
        );
      case BlockedPeoplePhase.ready:
        body = RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final person = state.items[index];
              final name = person.name == null
                  ? l10n.messagesDeletedAccount
                  : userText(person.name!);
              return ListTile(
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.page,
                  vertical: AppSpacing.xs,
                ),
                leading: UserAvatar(
                  name: person.name ?? '',
                  imageUrl: person.avatarUrl,
                ),
                title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  l10n.safetyBlockedSince(
                    DateFormat.yMMMd(l10n.localeName)
                        .format(person.blockedAt.toLocal()),
                  ),
                ),
                trailing: OutlinedButton(
                  key: ValueKey('unblock-${person.userId}'),
                  onPressed: () =>
                      unawaited(_unblock(context, ref, person, name)),
                  child: Text(l10n.safetyUnblock),
                ),
              );
            },
          ),
        );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.safetyBlockedPeopleTitle)),
      body: body,
    );
  }
}
