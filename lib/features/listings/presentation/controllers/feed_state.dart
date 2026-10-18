import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/feed_filters.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:flutter/foundation.dart';

/// Étape du premier chargement du fil.
enum FeedPhase {
  /// Première page en cours : squelettes.
  loading,

  /// Fil affiché (éventuellement vide).
  ready,

  /// Première page impossible à charger : écran d'erreur + « Réessayer ».
  failed,
}

/// État du fil d'annonces.
@immutable
final class FeedState {
  const new({
    this.phase = FeedPhase.loading,
    this.items = const [],
    this.category,
    this.filters = FeedFilters.none,
    this.failure,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreFailure,
    this.refreshFailure,
  });

  final FeedPhase phase;
  final List<ListingSummary> items;

  /// Catégorie choisie ; `null` = toutes les annonces (« Pour vous »).
  final ListingCategory? category;

  /// Quartier, tri et prix choisis.
  final FeedFilters filters;

  /// Vrai si une catégorie ou un filtre limite le fil.
  bool get isFiltered => category != null || filters.isActive;

  /// Erreur du premier chargement ([FeedPhase.failed]).
  final Failure? failure;

  /// Vrai s'il reste des annonces à charger en bas du fil.
  final bool hasMore;

  /// Page suivante en cours de chargement.
  final bool isLoadingMore;

  /// Erreur de la page suivante : affichée en bas, sans masquer le fil.
  final Failure? loadMoreFailure;

  /// Erreur d'actualisation alors que des annonces sont déjà affichées :
  /// signalée une fois (message), les annonces restent visibles.
  final Failure? refreshFailure;

  /// Fil chargé mais sans aucune annonce.
  bool get isEmpty => phase == FeedPhase.ready && items.isEmpty;

  /// Peut-on demander la page suivante maintenant ?
  bool get canLoadMore =>
      phase == FeedPhase.ready &&
      hasMore &&
      !isLoadingMore &&
      loadMoreFailure == null;
}
