import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/feed_filters.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:afrimarket_mobile/features/listings/listings_providers.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pilote le fil d'annonces : premier chargement, défilement infini,
/// actualisation, catégorie et filtres (quartier, tri, prix).
///
/// Une réponse qui arrive après un changement (nouvelle catégorie,
/// actualisation) est ignorée : le fil n'affiche jamais un mélange.
class FeedController extends Notifier<FeedState> {
  /// Augmente à chaque nouveau chargement depuis la première page.
  int _generation = 0;

  /// Dernière page chargée.
  int _page = 0;

  @override
  FeedState build() {
    final generation = ++_generation;
    unawaited(_loadFirstPage(generation, null, FeedFilters.none));
    return const FeedState();
  }

  /// Recharge depuis la première page (tirer pour actualiser).
  ///
  /// Les annonces déjà affichées restent visibles pendant le chargement.
  Future<void> refresh() {
    final generation = ++_generation;
    final current = state;
    if (current.phase != FeedPhase.ready) {
      state = FeedState(category: current.category, filters: current.filters);
    }
    return _loadFirstPage(generation, current.category, current.filters);
  }

  /// Limite le fil à [category] ; `null` = toutes les annonces.
  Future<void> selectCategory(ListingCategory? category) async {
    if (category?.id == state.category?.id) return;
    final filters = state.filters;
    final generation = ++_generation;
    state = FeedState(category: category, filters: filters);
    await _loadFirstPage(generation, category, filters);
  }

  /// Applique quartier, tri et prix (la catégorie est conservée).
  Future<void> applyFilters(FeedFilters filters) async {
    if (filters == state.filters) return;
    final category = state.category;
    final generation = ++_generation;
    state = FeedState(category: category, filters: filters);
    await _loadFirstPage(generation, category, filters);
  }

  /// Retire catégorie et filtres : tout le fil (« Voir toutes les annonces »).
  Future<void> clearFilters() async {
    if (!state.isFiltered) return;
    final generation = ++_generation;
    state = const FeedState();
    await _loadFirstPage(generation, null, FeedFilters.none);
  }

  /// Charge la page suivante (bas du fil). Sans effet si rien à charger
  /// ou si un chargement est déjà en cours.
  Future<void> loadMore() async {
    final current = state;
    if (!current.canLoadMore) return;
    final generation = _generation;
    state = _copy(current, isLoadingMore: true);

    final result = await ref.read(getFeedUseCaseProvider)(
      page: _page + 1,
      categoryId: current.category?.id,
      filters: current.filters,
    );
    if (!ref.mounted || generation != _generation) return;

    switch (result) {
      case Ok(:final value):
        _page = value.page;
        final known = {for (final item in state.items) item.id};
        state = _copy(
          state,
          // Une annonce publiée entre-temps décale les pages : on évite
          // d'afficher deux fois la même.
          items: [
            ...state.items,
            ...value.items.where((item) => !known.contains(item.id)),
          ],
          hasMore: value.hasMore,
          isLoadingMore: false,
        );
      case Err(:final failure):
        state = _copy(state, isLoadingMore: false, loadMoreFailure: failure);
    }
  }

  /// « Réessayer » en bas du fil, après une erreur de page suivante.
  Future<void> retryLoadMore() {
    state = _copy(state, clearLoadMoreFailure: true);
    return loadMore();
  }

  /// Le message d'erreur d'actualisation a été affiché.
  void refreshFailureShown() {
    if (state.refreshFailure == null) return;
    state = _copy(state, clearRefreshFailure: true);
  }

  Future<void> _loadFirstPage(
    int generation,
    ListingCategory? category,
    FeedFilters filters,
  ) async {
    final result = await ref.read(getFeedUseCaseProvider)(
      categoryId: category?.id,
      filters: filters,
    );
    if (!ref.mounted || generation != _generation) return;

    switch (result) {
      case Ok(:final value):
        _page = value.page;
        state = _ready(value, category, filters);
      case Err(:final failure):
        final current = state;
        state = current.phase == FeedPhase.ready && current.items.isNotEmpty
            // Actualisation ratée : on garde les annonces affichées.
            ? _copy(current, refreshFailure: failure)
            : FeedState(
                phase: FeedPhase.failed,
                category: category,
                filters: filters,
                failure: failure,
              );
    }
  }

  static FeedState _ready(
    ListingPage page,
    ListingCategory? category,
    FeedFilters filters,
  ) {
    return FeedState(
      phase: FeedPhase.ready,
      items: page.items,
      category: category,
      filters: filters,
      hasMore: page.hasMore,
    );
  }

  static FeedState _copy(
    FeedState state, {
    List<ListingSummary>? items,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
    Failure? refreshFailure,
    bool clearRefreshFailure = false,
  }) {
    return FeedState(
      phase: state.phase,
      items: items ?? state.items,
      category: state.category,
      filters: state.filters,
      failure: state.failure,
      hasMore: hasMore ?? state.hasMore,
      isLoadingMore: isLoadingMore ?? state.isLoadingMore,
      loadMoreFailure: clearLoadMoreFailure
          ? null
          : loadMoreFailure ?? state.loadMoreFailure,
      refreshFailure: clearRefreshFailure
          ? null
          : refreshFailure ?? state.refreshFailure,
    );
  }
}

/// Le fil reste en mémoire en changeant d'onglet : on retrouve ses
/// annonces et sa position sans nouveau chargement.
final NotifierProvider<FeedController, FeedState> feedControllerProvider =
    NotifierProvider<FeedController, FeedState>(FeedController.new);

/// Catégories proposées (menu ☰ et pastille « Catégories »).
///
/// Libéré dès qu'il n'est plus affiché : un nouvel affichage, ou
/// `ref.invalidate` (« Réessayer »), recharge la liste.
final FutureProvider<Result<List<ListingCategory>>> listingCategoriesProvider =
    FutureProvider.autoDispose<Result<List<ListingCategory>>>(
      (ref) => ref.watch(getCategoriesUseCaseProvider)(),
    );
