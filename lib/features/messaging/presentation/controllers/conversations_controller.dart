import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/realtime/realtime_connection.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:afrimarket_mobile/features/messaging/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:meta/meta.dart';

/// Étape d'une liste chargée depuis le serveur.
enum ListPhase { loading, ready, failed }

/// Discussions d'un onglet (Achat ou Vente).
@immutable
final class ConversationsState {
  const new({
    this.phase = ListPhase.loading,
    this.items = const [],
    this.nextCursor,
    this.isLoadingMore = false,
    this.failure,
    this.loadMoreFailure,
    this.refreshFailure,
  });

  final ListPhase phase;
  final List<ConversationSummary> items;
  final String? nextCursor;
  final bool isLoadingMore;

  /// Échec du premier chargement (plein écran).
  final Failure? failure;

  /// Échec de la page suivante (ligne en bas de liste).
  final Failure? loadMoreFailure;

  /// Échec d'une actualisation alors que des discussions sont affichées
  /// (message à afficher une fois).
  final Failure? refreshFailure;

  bool get isEmpty => phase == ListPhase.ready && items.isEmpty;

  bool get canLoadMore =>
      phase == ListPhase.ready &&
      nextCursor != null &&
      !isLoadingMore &&
      loadMoreFailure == null;

  /// Messages non lus dans les discussions chargées (pastille de l'onglet).
  int get unreadCount =>
      items.fold(0, (total, item) => total + item.unreadCount);

  ConversationsState copyWith({
    List<ConversationSummary>? items,
    String? Function()? nextCursor,
    bool? isLoadingMore,
    Failure? Function()? loadMoreFailure,
    Failure? Function()? refreshFailure,
  }) {
    return ConversationsState(
      phase: phase,
      items: items ?? this.items,
      nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: failure,
      loadMoreFailure: loadMoreFailure == null
          ? this.loadMoreFailure
          : loadMoreFailure(),
      refreshFailure: refreshFailure == null
          ? this.refreshFailure
          : refreshFailure(),
    );
  }
}

/// Pilote la liste d'un onglet : premier chargement, page suivante,
/// actualisation (tirer, retour d'une discussion, nouveau message reçu en
/// temps réel).
///
/// Une réponse arrivée après une nouvelle actualisation est ignorée.
class ConversationsController extends Notifier<ConversationsState> {
  new(this.role);

  final ConversationRole role;

  int _generation = 0;

  @override
  ConversationsState build() {
    final signedIn = ref.watch(sessionProvider) == SessionStatus.authenticated;
    if (!signedIn) return const ConversationsState(phase: ListPhase.ready);

    final events = ref
        .read(realtimeConnectionProvider)
        .events
        .where((event) => event == RealtimeEvent.message)
        .listen((_) => unawaited(refresh()));
    ref.onDispose(() => unawaited(events.cancel()));

    final generation = ++_generation;
    // Jamais pendant la construction des écrans.
    unawaited(Future.microtask(() => _loadFirstPage(generation)));
    return const ConversationsState();
  }

  /// Recharge depuis la première page ; les discussions affichées restent
  /// visibles pendant le chargement.
  Future<void> refresh() {
    if (!ref.mounted) return Future.value();
    final generation = ++_generation;
    if (state.phase == ListPhase.failed) state = const ConversationsState();
    return _loadFirstPage(generation);
  }

  /// Page suivante (bas de la liste).
  Future<void> loadMore() async {
    final current = state;
    if (!current.canLoadMore) return;
    final generation = _generation;
    state = current.copyWith(isLoadingMore: true);

    final result = await ref.read(getConversationsUseCaseProvider)(
      role: role,
      cursor: current.nextCursor,
    );
    if (!ref.mounted || generation != _generation) return;

    switch (result) {
      case Ok(:final value):
        final known = {for (final item in state.items) item.id};
        state = state.copyWith(
          items: [
            ...state.items,
            ...value.items.where((item) => !known.contains(item.id)),
          ],
          nextCursor: () => value.nextCursor,
          isLoadingMore: false,
        );
      case Err(:final failure):
        state = state.copyWith(
          isLoadingMore: false,
          loadMoreFailure: () => failure,
        );
    }
  }

  /// « Réessayer » en bas de liste.
  Future<void> retryLoadMore() {
    state = state.copyWith(loadMoreFailure: () => null);
    return loadMore();
  }

  /// La discussion [id] vient d'être ouverte : plus de pastille.
  void markRead(String id) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == id) item.markedRead() else item,
      ],
    );
  }

  /// Le message d'échec d'actualisation a été affiché.
  void refreshFailureShown() =>
      state = state.copyWith(refreshFailure: () => null);

  Future<void> _loadFirstPage(int generation) async {
    final result = await ref.read(getConversationsUseCaseProvider)(role: role);
    if (!ref.mounted || generation != _generation) return;

    switch (result) {
      case Ok(:final value):
        state = ConversationsState(
          phase: ListPhase.ready,
          items: value.items,
          nextCursor: value.nextCursor,
        );
      case Err(:final failure):
        state = state.phase == ListPhase.ready && state.items.isNotEmpty
            ? state.copyWith(refreshFailure: () => failure)
            : ConversationsState(phase: ListPhase.failed, failure: failure);
    }
  }
}

/// Discussions par onglet. Gardées tant que l'onglet Messages existe.
final NotifierProviderFamily<
  ConversationsController,
  ConversationsState,
  ConversationRole
>
conversationsControllerProvider = NotifierProvider.autoDispose
    .family<ConversationsController, ConversationsState, ConversationRole>(
      ConversationsController.new,
    );
