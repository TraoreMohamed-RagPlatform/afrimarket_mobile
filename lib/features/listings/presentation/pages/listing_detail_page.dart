import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/platform/external_actions.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/core/theme/app_typography.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/manage_own_listing_usecase.dart';
import 'package:afrimarket_mobile/features/listings/listings_providers.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/listing_detail_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/listing_card_status_of.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/listing_detail_skeleton.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/listing_details_section.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/listing_message_box.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/listing_owner_panel.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/listing_photo_gallery.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/listing_seller_tile.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/report_listing_sheet.dart';
import 'package:afrimarket_mobile/features/messaging/messaging_providers.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/snackbar_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/listing_age_formatter.dart';
import 'package:afrimarket_mobile/shared/formatters/price_formatter.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:afrimarket_mobile/shared/widgets/app_badge.dart';
import 'package:afrimarket_mobile/shared/widgets/app_empty_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_error_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_round_action.dart';
import 'package:afrimarket_mobile/shared/widgets/app_section_header.dart';
import 'package:afrimarket_mobile/shared/widgets/listing_card.dart';
import 'package:afrimarket_mobile/shared/widgets/sliver_listing_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Détail d'une annonce (adresse `/listings/:id`, ouverte depuis le fil,
/// les annonces similaires ou un lien partagé).
///
/// Maquette « Détail d'une annonce » (style Facebook Marketplace) :
/// photos, titre, prix (ancien prix barré, « Négociable »), date et lieu,
/// message au vendeur, actions (WhatsApp, Appeler, Enregistrer, Partager),
/// détails, vendeur, conseils de sécurité, signalement, annonces
/// similaires.
///
/// Consultation sans compte (ADR 0002) : la page est publique ; écrire,
/// appeler, enregistrer et signaler demandent une connexion, puis
/// ramènent ici.
class ListingDetailPage extends ConsumerWidget {
  const new({required this.listingId, super.key});

  /// Identifiant de l'annonce (déjà validé par `RouteAccessPolicy`).
  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(listingDetailProvider(listingId));

    return switch (detail) {
      AsyncData(value: Ok(:final value)) => _ListingDetailView(listing: value),
      AsyncData(value: Err(failure: NotFoundFailure())) =>
        const _NotFoundView(),
      AsyncData(value: Err(:final failure)) => _FailureView(
        failure: failure,
        onRetry: () => ref.invalidate(listingDetailProvider(listingId)),
      ),
      AsyncError() => _FailureView(
        failure: const UnexpectedFailure(),
        onRetry: () => ref.invalidate(listingDetailProvider(listingId)),
      ),
      _ => const _LoadingView(),
    };
  }
}

/// Retour : page précédente, ou le fil si la page a été ouverte par un
/// lien (aucune page derrière).
void _goBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.home);
  }
}

class _ListingDetailView extends ConsumerStatefulWidget {
  const new({required this.listing});

  final ListingDetail listing;

  @override
  ConsumerState<_ListingDetailView> createState() => _ListingDetailViewState();
}

class _ListingDetailViewState extends ConsumerState<_ListingDetailView> {
  ListingDetail get _listing => widget.listing;

  /// Action du vendeur en cours (réserver, vendre).
  bool _ownerBusy = false;

  /// Vrai si connecté ; sinon ouvre la connexion, qui ramènera ici.
  bool _ensureSignedIn() {
    if (ref.read(sessionProvider) == SessionStatus.authenticated) return true;
    context.go(AppRoutes.loginWithReturn(AppRoutes.listing(_listing.id)));
    return false;
  }

  void _show(String message) => context.showAppSnackBar(message);

  /// Message d'échec d'une action sur l'annonce. Le serveur refuse avec
  /// une erreur de validation les actions sur sa propre annonce.
  String _actionFailure(Failure failure) {
    final l10n = context.l10n;
    return failure is ValidationFailure
        ? l10n.listingOwnListingError
        : failure.message(l10n);
  }

  Future<bool> _sendMessage(String message) async {
    final l10n = context.l10n;
    if (message.trim().isEmpty) {
      _show(l10n.listingMessageEmpty);
      return false;
    }
    if (!_ensureSignedIn()) return false;

    final result = await ref.read(messageSellerUseCaseProvider)(
      sellerId: _listing.seller.id,
      message: message,
    );
    if (!mounted) return false;
    switch (result) {
      case Ok():
        unawaited(HapticFeedback.lightImpact());
        _show(l10n.listingMessageSent);
        return true;
      case Err(:final failure):
        _show(_actionFailure(failure));
        return false;
    }
  }

  Future<void> _contact({required bool whatsapp}) async {
    if (!_ensureSignedIn()) return;
    final l10n = context.l10n;
    final result = await ref.read(getSellerContactUseCaseProvider)(_listing.id);
    if (!mounted) return;

    switch (result) {
      case Err(failure: NotFoundFailure()):
        _show(l10n.listingContactUnavailable);
      case Err(:final failure):
        _show(failure.message(l10n));
      case Ok(:final value):
        final actions = ref.read(externalActionsProvider);
        if (whatsapp) {
          if (!value.whatsapp) {
            _show(l10n.listingContactUnavailable);
            return;
          }
          final opened = await actions.openWhatsApp(
            value.whatsappNumber,
            message: l10n.listingWhatsappMessage(
              stripBidiControls(_listing.title),
            ),
          );
          if (!opened && mounted) _show(l10n.listingWhatsappFailed);
        } else {
          final opened = await actions.dial(value.phone);
          if (!opened && mounted) _show(l10n.listingCallFailed);
        }
    }
  }

  Future<void> _toggleSaved() async {
    if (!_ensureSignedIn()) return;
    final l10n = context.l10n;
    final controller = ref.read(
      favoriteControllerProvider(_listing.id).notifier,
    );
    unawaited(HapticFeedback.lightImpact());
    final failure = await controller.toggle();
    if (!mounted) return;
    if (failure != null) {
      _show(failure.message(l10n));
      return;
    }
    final saved = ref.read(favoriteControllerProvider(_listing.id)).saved;
    _show(saved ? l10n.listingSavedMessage : l10n.listingUnsavedMessage);
  }

  Future<void> _share() {
    final l10n = context.l10n;
    final title = stripBidiControls(_listing.title);
    return ref
        .read(externalActionsProvider)
        .share(
          l10n.listingShareText(title, formatPrice(_listing.price, l10n)),
          subject: title,
        );
  }

  Future<void> _report() async {
    if (!_ensureSignedIn()) return;
    final report = await showReportListingSheet(context);
    if (report == null || !mounted) return;

    final result = await ref.read(reportListingUseCaseProvider)(
      listingId: _listing.id,
      reason: report.reason,
      details: report.details,
    );
    if (!mounted) return;
    switch (result) {
      case Ok():
        _show(context.l10n.reportSent);
      case Err(:final failure):
        _show(_actionFailure(failure));
    }
  }

  /// Réservée ↔ disponible (vendeur).
  Future<void> _toggleReserved() async {
    final reserved = !_listing.isReserved;
    await _ownerAction(
      (useCase) => useCase.setReserved(_listing.id, reserved: reserved),
      reserved
          ? context.l10n.ownerReservedDone
          : context.l10n.ownerAvailableDone,
    );
  }

  /// Vendue, après confirmation (vendeur).
  Future<void> _markSold() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ownerSoldConfirmTitle),
        content: Text(l10n.ownerSoldConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.ownerCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.ownerMarkSold),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;
    await _ownerAction(
      (useCase) => useCase.markSold(_listing.id),
      l10n.ownerSoldDone,
    );
  }

  Future<void> _ownerAction(
    Future<Result<void>> Function(ManageOwnListingUseCase useCase) action,
    String success,
  ) async {
    if (_ownerBusy) return;
    setState(() => _ownerBusy = true);
    final result = await action(ref.read(manageOwnListingUseCaseProvider));
    if (!mounted) return;
    setState(() => _ownerBusy = false);
    switch (result) {
      case Ok():
        unawaited(HapticFeedback.lightImpact());
        _show(success);
        // Page et fil à jour (badge « Réservé », annonce vendue).
        ref.invalidate(listingDetailProvider(_listing.id));
        unawaited(ref.read(feedControllerProvider.notifier).refresh());
      case Err(:final failure):
        _show(failure.message(context.l10n));
    }
  }

  Future<void> _openMoreMenu() async {
    final l10n = context.l10n;
    final choice = await showModalBottomSheet<VoidCallback>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.shareNetwork),
              title: Text(l10n.listingActionShare),
              onTap: () => Navigator.of(sheetContext).pop(_share),
            ),
            if (!_listing.isOwner)
              ListTile(
                leading: const Icon(AppIcons.flag),
                title: Text(l10n.listingReportAction),
                onTap: () => Navigator.of(sheetContext).pop(_report),
              ),
          ],
        ),
      ),
    );
    choice?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final listing = _listing;
    final seller = listing.seller;
    final saved = ref.watch(
      favoriteControllerProvider(listing.id).select((state) => state.saved),
    );
    final isOwner = listing.isOwner;
    // Le vendeur ne s'écrit pas à lui-même.
    final canContact = !listing.isSold && !isOwner;

    return Scaffold(
      // Sous la barre d'état : le texte ne passe jamais sous l'heure et la
      // batterie en faisant défiler la page.
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ListingPhotoGallery(
                imageUrls: listing.imageUrls,
                greyscale: listing.isSold,
                leading: ListingPhotoButton(
                  icon: AppIcons.arrowLeft,
                  tooltip: l10n.listingBackTooltip,
                  onPressed: () => _goBack(context),
                ),
                actions: [
                  ListingPhotoButton(
                    icon: AppIcons.shareNetwork,
                    tooltip: l10n.listingActionShare,
                    onPressed: () => unawaited(_share()),
                  ),
                  ListingPhotoButton(
                    icon: AppIcons.dotsThree,
                    tooltip: l10n.listingMoreTooltip,
                    onPressed: () => unawaited(_openMoreMenu()),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.page),
              sliver: SliverList.list(
                children: [
                  _Summary(listing: listing),
                  if (isOwner) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ListingOwnerPanel(
                      listing: listing,
                      busy: _ownerBusy,
                      onToggleReserved: () => unawaited(_toggleReserved()),
                      onMarkSold: () => unawaited(_markSold()),
                    ),
                  ],
                  if (canContact) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ListingMessageBox(onSend: _sendMessage),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppRoundActionRow(
                    actions: [
                      if (canContact && seller.canWhatsapp)
                        AppRoundAction(
                          icon: AppIcons.whatsappLogo,
                          label: l10n.listingActionWhatsapp,
                          onTap: () => unawaited(_contact(whatsapp: true)),
                        ),
                      if (canContact && seller.canCall)
                        AppRoundAction(
                          icon: AppIcons.phone,
                          label: l10n.listingActionCall,
                          onTap: () => unawaited(_contact(whatsapp: false)),
                        ),
                      if (!isOwner)
                        AppRoundAction(
                          icon: AppIcons.bookmarkSimple,
                          activeIcon: AppIconsFill.bookmarkSimple,
                          label: l10n.listingActionSave,
                          activeLabel: l10n.listingActionSaved,
                          active: saved,
                          onTap: () => unawaited(_toggleSaved()),
                        ),
                      AppRoundAction(
                        icon: AppIcons.shareNetwork,
                        label: l10n.listingActionShare,
                        onTap: () => unawaited(_share()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const _Band(),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.page),
              sliver: SliverToBoxAdapter(
                child: ListingDetailsSection(listing: listing),
              ),
            ),
            const _Band(),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.page),
              sliver: SliverList.list(
                children: [
                  AppSectionHeader(title: l10n.listingSellerTitle),
                  ListingSellerTile(seller: seller),
                ],
              ),
            ),
            const _Band(),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.page),
              sliver: SliverList.list(
                children: [
                  const _SafetyTips(),
                  if (!isOwner) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _ReportLink(onTap: () => unawaited(_report())),
                  ],
                ],
              ),
            ),
            _SimilarListings(listingId: listing.id),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}

/// Titre, prix, badges, date de publication et lieu.
class _Summary extends ConsumerWidget {
  const new({required this.listing});

  final ListingDetail listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final styles = context.textStyles;
    final previous = listing.previousPrice;
    final location = ref
        .watch(listingLocationsProvider)
        .value
        ?.label(city: listing.city, district: listing.district);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(userText(listing.title), style: styles.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formatPrice(listing.price, l10n),
              style: styles.titleLarge?.copyWith(
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
            if (previous != null)
              Text(
                formatPrice(previous, l10n),
                style: styles.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            if (listing.isNegotiable && !listing.isSold)
              const AppBadge(AppBadgeType.negotiable),
            if (listing.isSold) const AppBadge(AppBadgeType.sold),
            if (listing.isReserved && !listing.isSold)
              const AppBadge(AppBadgeType.reserved),
          ],
        ),
        // Explication pour les acheteurs ; le vendeur a son propre encadré.
        if (listing.isReserved && !listing.isSold && !listing.isOwner) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.listingReservedHint, style: styles.bodySmall),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          [formatListingAge(listing.createdAt, l10n), ?location].join(' · '),
          style: styles.bodySmall,
        ),
      ],
    );
  }
}

/// Séparation épaisse entre deux sections (comme Marketplace).
class _Band extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ColoredBox(
        color: context.colors.surfaceMuted,
        child: const SizedBox(height: AppSpacing.sm),
      ),
    );
  }
}

class _SafetyTips extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final styles = context.textStyles;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(AppIcons.shieldCheck, color: colors.brand),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.listingSafetyTitle,
                    style: styles.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.listingSafetyText, style: styles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportLink extends StatelessWidget {
  const new({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: colors.textSecondary,
        alignment: AlignmentDirectional.centerStart,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
      ),
      icon: const Icon(AppIcons.flag, size: 20),
      label: Text(context.l10n.listingReportAction),
    );
  }
}

/// « Annonces similaires » : grille sous la page. Rien n'est affiché
/// pendant le chargement, en cas d'erreur, ou s'il n'y en a pas.
class _SimilarListings extends ConsumerWidget {
  const new({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = switch (ref.watch(similarListingsProvider(listingId))) {
      AsyncData(value: Ok(:final value)) => value,
      _ => const <ListingSummary>[],
    };
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final now = DateTime.now();
    return SliverMainAxisGroup(
      slivers: [
        const _Band(),
        SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.page,
            vertical: AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: AppSectionHeader(title: context.l10n.listingSimilarTitle),
          ),
        ),
        SliverListingGrid(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListingCard(
              key: ValueKey(item.id),
              title: item.title,
              price: item.price,
              oldPrice: item.previousPrice,
              imageUrl: item.imageUrl,
              badges: [if (item.isRecentAt(now)) AppBadgeType.recent],
              status: listingCardStatusOf(
                isSold: item.isSold,
                isReserved: item.isReserved,
              ),
              onTap: () => unawaited(context.push(AppRoutes.listing(item.id))),
            );
          },
        ),
      ],
    );
  }
}

/// Chargement : squelette, avec le bouton retour déjà disponible.
class _LoadingView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ListingDetailSkeleton(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: ListingPhotoButton(
                icon: AppIcons.arrowLeft,
                tooltip: context.l10n.listingBackTooltip,
                onPressed: () => _goBack(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Annonce introuvable (vendue, retirée, ou lien erroné).
class _NotFoundView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.listingBackTooltip,
          icon: const Icon(AppIcons.arrowLeft),
          onPressed: () => _goBack(context),
        ),
      ),
      body: AppEmptyState(
        icon: AppIcons.shoppingBag,
        title: l10n.listingNotFoundTitle,
        message: l10n.listingNotFoundMessage,
        actionLabel: l10n.listingNotFoundAction,
        onAction: () => context.go(AppRoutes.home),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const new({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: context.l10n.listingBackTooltip,
          icon: const Icon(AppIcons.arrowLeft),
          onPressed: () => _goBack(context),
        ),
      ),
      body: AppErrorState(failure: failure, onRetry: onRetry),
    );
  }
}
