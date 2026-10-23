import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/realtime/realtime_connection.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/features/inbox/presentation/unread_counts_controller.dart';
import 'package:afrimarket_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:afrimarket_mobile/features/notifications/notifications_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Étape du chargement de la liste.
enum NotificationsPhase { loading, ready, failed }

/// État de l'onglet Notifications.
@immutable
final class NotificationsState {
  const new({
    this.phase = NotificationsPhase.loading,
    this.items = const [],
    this.nextCursor,
    this.isLoadingMore = false,
    this.failure,
    this.loadMoreFailure,
    this.actionFailure,
  });

  final NotificationsPhase phase;

  /// Les plus récentes d'abord.
  final List<AppNotification> items;
  final String? nextCursor;
  final bool isLoadingMore;

  /// Échec du premier chargement (plein écran).
  final Failure? failure;

  /// Échec de la page suivante (ligne en bas de liste).
  final Failure? loadMoreFailure;

  /// Échec d'une action (actualisation, lecture, suppression) : message à
  /// afficher une fois.
  final Failure? actionFailure;

  bool get isEmpty => phase == NotificationsPhase.ready && items.isEmpty;

  bool get hasUnread => items.any((item) => !item.read);

  bool get canLoadMore =>
      phase == NotificationsPhase.ready &&
      nextCursor != null &&
      !isLoadingMore &&
      loadMoreFailure == null;

  NotificationsState copyWith({
    NotificationsPhase? phase,
    List<AppNotification>? items,
    String? Function()? nextCursor,
    bool? isLoadingMore,
    Failure? Function()? failure,
    Failure? Function()? loadMoreFailure,
    Failure? Function()? actionFailure,
  }) {
    return NotificationsState(
      phase: phase ?? this.phase,
      items: items ?? this.items,
      nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: failure == null ? this.failure : failure(),
      loadMoreFailure: loadMoreFailure == null
          ? this.loadMoreFailure
          : loadMoreFailure(),
      actionFailure: actionFailure == null
          ? this.actionFailure
          : actionFailure(),
    );
  }
}

/// Pilote l'onglet Notifications, comme Facebook :
///
/// - onglet affiché ([setVisible]) : toutes les notifications deviennent
///   « vues », la pastille s'efface (elles restent surlignées) ;
/// - notification touchée ([markRead]) : plus surlignée ;
/// - [remove] retire tout de suite de la liste ; [confirmRemove] supprime
///   sur le serveur (après « Annuler »), [restore] la remet ;
/// - nouvelle notification en temps réel : liste relue (et vue si l'onglet
///   est affiché).
class NotificationsController extends Notifier<NotificationsState> {
  int _generation = 0;
  bool _visible = false;

  @override
  NotificationsState build() {
    final signedIn = ref.watch(sessionProvider) == SessionStatus.authenticated;
    if (!signedIn) {
      return const NotificationsState(phase: NotificationsPhase.ready);
    }

    final events = ref
        .read(realtimeConnectionProvider)
        .events
        .where((event) => event == RealtimeEvent.notification)
        .listen((_) => unawaited(_onNewNotification()));
    ref.onDispose(() => unawaited(events.cancel()));

    final generation = ++_generation;
    unawaited(Future.microtask(() => _loadFirstPage(generation)));
    return const NotificationsState();
  }

  /// L'onglet devient visible (ou ne l'est plus).
  Future<void> setVisible({required bool visible}) async {
    _visible = visible;
    if (visible) await _markAllSeen();
  }

  /// Recharge depuis la première page (les notifications restent visibles).
  Future<void> refresh() {
    if (!ref.mounted) return Future.value();
    final generation = ++_generation;
    if (state.phase == NotificationsPhase.failed) {
      state = const NotificationsState();
    }
    return _loadFirstPage(generation);
  }

  /// Page suivante (bas de la liste).
  Future<void> loadMore() async {
    final current = state;
    if (!current.canLoadMore) return;
    final generation = _generation;
    state = current.copyWith(isLoadingMore: true);

    final result = await ref.read(getNotificationsUseCaseProvider)(
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

  /// Notification touchée : affichée lue tout de suite.
  Future<void> markRead(String id) async {
    final item = _byId(id);
    if (item == null || item.read) return;
    _replace(item.markedRead());
    final result = await ref
        .read(manageNotificationsUseCaseProvider)
        .markRead(id);
    if (!ref.mounted) return;
    if (result case Err(:final failure) when failure is! NotFoundFailure) {
      _replace(item);
      state = state.copyWith(actionFailure: () => failure);
    }
  }

  /// « Tout marquer comme lu ».
  Future<void> markAllRead() async {
    if (!state.hasUnread) return;
    final before = state.items;
    state = state.copyWith(
      items: [for (final item in before) item.markedRead()],
    );
    final result = await ref
        .read(manageNotificationsUseCaseProvider)
        .markAllRead();
    if (!ref.mounted) return;
    if (result case Err(:final failure)) {
      state = state.copyWith(items: before, actionFailure: () => failure);
    }
  }

  /// Retire [id] de la liste (« Annuler » possible) ; renvoie sa position
  /// pour [restore].
  int remove(String id) {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index < 0) return -1;
    state = state.copyWith(items: [...state.items]..removeAt(index));
    return index;
  }

  /// « Annuler » : remet [item] à sa place.
  void restore(AppNotification item, int index) {
    if (state.items.any((existing) => existing.id == item.id)) return;
    final items = [...state.items];
    items.insert(index.clamp(0, items.length), item);
    state = state.copyWith(items: items);
  }

  /// Supprime sur le serveur une notification déjà retirée de la liste ;
  /// en cas d'échec, elle revient.
  Future<void> confirmRemove(AppNotification item, int index) async {
    final result = await ref
        .read(manageNotificationsUseCaseProvider)
        .delete(item.id);
    if (!ref.mounted) return;
    if (result case Err(:final failure) when failure is! NotFoundFailure) {
      restore(item, index);
      state = state.copyWith(actionFailure: () => failure);
    }
  }

  /// Le message d'échec a été affiché.
  void actionFailureShown() =>
      state = state.copyWith(actionFailure: () => null);

  AppNotification? _byId(String id) {
    for (final item in state.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _replace(AppNotification updated) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == updated.id) updated else item,
      ],
    );
  }

  Future<void> _onNewNotification() async {
    await refresh();
    if (_visible) await _markAllSeen();
  }

  Future<void> _markAllSeen() async {
    if (!ref.mounted) return;
    if (ref.read(sessionProvider) != SessionStatus.authenticated) return;
    final result = await ref
        .read(manageNotificationsUseCaseProvider)
        .markAllSeen();
    if (!ref.mounted || result is Err) return;
    unawaited(ref.read(unreadCountsProvider.notifier).refresh());
  }

  Future<void> _loadFirstPage(int generation) async {
    final result = await ref.read(getNotificationsUseCaseProvider)();
    if (!ref.mounted || generation != _generation) return;

    switch (result) {
      case Ok(:final value):
        state = NotificationsState(
          phase: NotificationsPhase.ready,
          items: value.items,
          nextCursor: value.nextCursor,
        );
      case Err(:final failure):
        state =
            state.phase == NotificationsPhase.ready && state.items.isNotEmpty
            ? state.copyWith(actionFailure: () => failure)
            : NotificationsState(
                phase: NotificationsPhase.failed,
                failure: failure,
              );
    }
  }
}

/// Onglet Notifications. Gardé tant que la barre du bas existe.
final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );
