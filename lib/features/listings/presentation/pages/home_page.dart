import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_locations.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_state.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/listing_detail_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/category_sheet.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/feed_filter_sheet.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/home_drawer.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/listing_card_status_of.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/snackbar_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:afrimarket_mobile/shared/widgets/app_badge.dart';
import 'package:afrimarket_mobile/shared/widgets/app_chip_bar.dart';
import 'package:afrimarket_mobile/shared/widgets/app_empty_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_error_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_load_more_indicator.dart';
import 'package:afrimarket_mobile/shared/widgets/app_logo.dart';
import 'package:afrimarket_mobile/shared/widgets/app_search_launcher.dart';
import 'package:afrimarket_mobile/shared/widgets/app_section_header.dart';
import 'package:afrimarket_mobile/shared/widgets/app_skeleton.dart';
import 'package:afrimarket_mobile/shared/widgets/app_sliver_header.dart';
import 'package:afrimarket_mobile/shared/widgets/listing_card.dart';
import 'package:afrimarket_mobile/shared/widgets/sliver_listing_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Le fil d'annonces (maquette page 1, style Facebook Marketplace).
///
/// - en-tête qui se masque en descendant : menu ☰, logo, profil,
///   recherche, pastilles « Vendre · Pour vous · Catégories · Filtres » ;
/// - grille 2 colonnes, défilement infini, tirer pour actualiser ;
/// - états : squelettes, fil vide, erreur, erreur de page suivante.
///
/// Consultation sans compte (ADR 0002) : le fil est public ; « Vendre »
/// et « Mon profil » demandent une connexion (garde de navigation).
class HomePage extends ConsumerStatefulWidget {
  const new({super.key});

  /// Distance au bas du fil (px) à partir de laquelle la page suivante
  /// est demandée : elle arrive avant que l'utilisateur atteigne le bas.
  static const double loadMoreThreshold = 600;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  FeedController get _feed => ref.read(feedControllerProvider.notifier);

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical &&
        notification.metrics.extentAfter < HomePage.loadMoreThreshold) {
      unawaited(_feed.loadMore());
    }
    return false;
  }

  /// Une première page plus courte que l'écran ne déclenche aucun
  /// défilement : on vérifie donc aussi après chaque affichage.
  void _loadMoreIfShort() {
    if (!mounted || !_scroll.hasClients) return;
    if (_scroll.position.extentAfter < HomePage.loadMoreThreshold) {
      unawaited(_feed.loadMore());
    }
  }

  void _openCategories() => unawaited(showCategorySheet(context, ref));

  void _openFilters() => unawaited(showFeedFilterSheet(context, ref));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(feedControllerProvider);

    // Actualisation ratée alors que des annonces sont affichées : un
    // simple message, les annonces restent visibles.
    ref.listen<Failure?>(
      feedControllerProvider.select((feed) => feed.refreshFailure),
      (previous, failure) {
        if (failure == null) return;
        context.showAppSnackBar(failure.message(context.l10n));
        _feed.refreshFailureShown();
      },
    );

    if (state.canLoadMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMoreIfShort());
    }

    final category = state.category;
    final locations =
        ref.watch(listingLocationsProvider).value ?? ListingLocations.empty;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _feed.refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              AppSliverHeader(
                title: AppLogo.brandName,
                titleWidget: const AppLogo(height: 32),
                leading: IconButton(
                  tooltip: l10n.menuTooltip,
                  icon: const Icon(AppIcons.list),
                  onPressed: () => unawaited(
                    showHomeMenu(context, onCategories: _openCategories),
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: l10n.myProfileTitle,
                    icon: const Icon(AppIcons.user),
                    onPressed: () => unawaited(context.push(AppRoutes.profile)),
                  ),
                ],
                search: AppSearchLauncher(
                  hint: l10n.searchHint,
                  onTap: () => unawaited(context.push(AppRoutes.search)),
                ),
                bottom: AppChipBar(
                  items: [
                    AppChipItem(
                      label: l10n.feedChipSell,
                      onTap: () => unawaited(context.push(AppRoutes.publish)),
                    ),
                    AppChipItem(
                      label: l10n.feedChipForYou,
                      selected: !state.isFiltered,
                      onTap: () => unawaited(_feed.clearFilters()),
                    ),
                    AppChipItem(
                      label: category == null
                          ? l10n.categoriesTitle
                          : userText(category.name),
                      selected: category != null,
                      hasDropdown: true,
                      onTap: _openCategories,
                    ),
                    AppChipItem(
                      label: feedFilterChipLabel(
                        state.filters,
                        locations,
                        l10n,
                      ),
                      selected: state.filters.isActive,
                      hasDropdown: true,
                      onTap: _openFilters,
                    ),
                  ],
                ),
              ),
              if (state.phase != FeedPhase.failed && !state.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: AppSectionHeader(
                      title: category == null
                          ? l10n.feedTodaysPicks
                          : userText(category.name),
                    ),
                  ),
                ),
              ..._content(state),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(FeedState state) {
    switch (state.phase) {
      case FeedPhase.loading:
        return const [SliverFillRemaining(child: ListingGridSkeleton())];
      case FeedPhase.failed:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppErrorState(
              failure: state.failure ?? const UnexpectedFailure(),
              onRetry: () => unawaited(_feed.refresh()),
            ),
          ),
        ];
      case FeedPhase.ready when state.items.isEmpty:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyFeed(
              reason: state.filters.isActive
                  ? _EmptyReason.filters
                  : state.category != null
                  ? _EmptyReason.category
                  : _EmptyReason.none,
              onShowAll: () => unawaited(_feed.clearFilters()),
            ),
          ),
        ];
      case FeedPhase.ready:
        final now = DateTime.now();
        return [
          SliverListingGrid(
            itemCount: state.items.length,
            itemBuilder: (context, index) =>
                _FeedCard(listing: state.items[index], now: now),
          ),
          SliverToBoxAdapter(
            child: _FeedFooter(state: state, onRetry: _feed.retryLoadMore),
          ),
        ];
    }
  }
}

/// Une annonce du fil.
class _FeedCard extends StatelessWidget {
  const new({required this.listing, required this.now});

  final ListingSummary listing;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return ListingCard(
      key: ValueKey(listing.id),
      title: listing.title,
      price: listing.price,
      oldPrice: listing.previousPrice,
      imageUrl: listing.imageUrl,
      badges: [if (listing.isRecentAt(now)) AppBadgeType.recent],
      status: listingCardStatusOf(
        isSold: listing.isSold,
        isReserved: listing.isReserved,
      ),
      onTap: () => unawaited(context.push(AppRoutes.listing(listing.id))),
    );
  }
}

/// Bas du fil : chargement de la page suivante, ou son erreur.
class _FeedFooter extends StatelessWidget {
  const new({required this.state, required this.onRetry});

  final FeedState state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = state.loadMoreFailure;
    if (failure != null) {
      return AppErrorState(
        failure: failure,
        compact: true,
        onRetry: () => unawaited(onRetry()),
      );
    }
    if (state.isLoadingMore) return const AppLoadMoreIndicator();
    return const SizedBox(height: AppSpacing.xl);
  }
}

/// Pourquoi le fil est vide.
enum _EmptyReason {
  /// Aucune annonce du tout.
  none,

  /// Aucune annonce dans la catégorie choisie.
  category,

  /// Aucune annonce avec ces filtres (quartier, prix...).
  filters,
}

/// Fil vide : une invitation à agir, jamais un simple « Aucun résultat ».
class _EmptyFeed extends StatelessWidget {
  const new({required this.reason, required this.onShowAll});

  final _EmptyReason reason;

  /// Retire catégorie et filtres.
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    switch (reason) {
      case _EmptyReason.filters:
        return AppEmptyState(
          icon: AppIcons.mapPin,
          title: l10n.feedEmptyFiltersTitle,
          message: l10n.feedEmptyFiltersMessage,
          actionLabel: l10n.feedShowAll,
          onAction: onShowAll,
        );
      case _EmptyReason.category:
        return AppEmptyState(
          icon: AppIcons.squaresFour,
          title: l10n.feedEmptyCategoryTitle,
          message: l10n.feedEmptyCategoryMessage,
          actionLabel: l10n.feedShowAll,
          onAction: onShowAll,
        );
      case _EmptyReason.none:
        break;
    }
    return AppEmptyState(
      icon: AppIcons.shoppingBag,
      title: l10n.feedEmptyTitle,
      message: l10n.feedEmptyMessage,
      actionLabel: l10n.feedEmptyAction,
      onAction: () => unawaited(context.push(AppRoutes.publish)),
    );
  }
}
