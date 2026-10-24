import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/edit_listing_usecase.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/edit_listing_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/listing_detail_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/listing_form.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/snackbar_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_empty_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Modification d'une annonce par son vendeur (plein écran, adresse
/// `/listings/:id/edit`), comme Facebook Marketplace.
///
/// - formulaire de « Publier », rempli avec l'annonce en ligne ;
/// - « Enregistrer » actif seulement s'il y a un changement ; seuls les
///   changements sont envoyés ;
/// - quitter avec des changements demande confirmation ;
/// - enregistrée : retour à l'annonce (et au fil) à jour.
class EditListingPage extends ConsumerStatefulWidget {
  const new({required this.listingId, super.key});

  final String listingId;

  @override
  ConsumerState<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends ConsumerState<EditListingPage> {
  NotifierProvider<EditListingController, EditListingState> get _provider =>
      editListingControllerProvider(widget.listingId);

  EditListingController get _controller => ref.read(_provider.notifier);

  /// Ferme l'écran ; ouvert seul (lien), retour à l'annonce.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.listing(widget.listingId));
    }
  }

  Future<void> _confirmLeave() async {
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editDiscardTitle),
        content: Text(l10n.editDiscardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.editDiscardCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.publishDiscardConfirm),
          ),
        ],
      ),
    );
    if ((leave ?? false) && mounted) _leave();
  }

  void _onSaved() {
    unawaited(HapticFeedback.mediumImpact());
    // Annonce et fil à jour (titre, prix, photo principale).
    ref.invalidate(listingDetailProvider(widget.listingId));
    unawaited(ref.read(feedControllerProvider.notifier).refresh());
    context.showAppSnackBar(context.l10n.editListingSaved);
    _leave();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    await _controller.save();
    if (!mounted) return;
    final state = ref.read(_provider);
    if (!state.saved && !state.isSaving && !state.draft.isReady) {
      context.showAppSnackBar(context.l10n.publishFixProblems);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(_provider);

    ref.listen(_provider, (previous, next) {
      final failure = next.failure;
      if (failure != null && previous?.failure == null) {
        context.showAppSnackBar(
          next.partiallySaved
              ? l10n.editListingPartial
              : failure.message(context.l10n),
        );
        _controller.failureShown();
      }
      if (next.saved && !(previous?.saved ?? false)) _onSaved();
    });

    final canLeave = !state.hasChanges && !state.isSaving;

    return PopScope(
      canPop: canLeave && context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || state.isSaving) return;
        canLeave ? _leave() : unawaited(_confirmLeave());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.publishCloseTooltip,
            icon: const Icon(AppIcons.x),
            onPressed: state.isSaving
                ? null
                : () => canLeave ? _leave() : unawaited(_confirmLeave()),
          ),
          title: Text(l10n.editListingTitle),
        ),
        body: switch (state.phase) {
          EditPhase.loading => const Center(child: CircularProgressIndicator()),
          EditPhase.unavailable => AppEmptyState(
            icon: AppIcons.warningCircle,
            title: l10n.editListingUnavailable,
          ),
          EditPhase.sold => AppEmptyState(
            icon: AppIcons.checkCircle,
            title: l10n.editListingSold,
          ),
          EditPhase.failed => AppErrorState(
            failure: state.loadFailure ?? const UnexpectedFailure(),
            onRetry: () => unawaited(_controller.retry()),
          ),
          EditPhase.ready => AbsorbPointer(
            absorbing: state.isSaving,
            // Défilement simple (pas de liste paresseuse) : un champ qui
            // sort de l'écran garde sa saisie.
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              child: ListingForm(
                key: ValueKey(state.revision),
                draft: state.draft,
                category: state.category,
                problems: state.visibleProblems,
                actions: _controller,
              ),
            ),
          ),
        },
        bottomNavigationBar: state.phase == EditPhase.ready
            ? ListingSubmitBar(
                buttonKey: const Key('edit-save'),
                busy: state.isSaving,
                label: switch (state.step) {
                  null => l10n.editListingSave,
                  EditStep.details => l10n.editListingSaving,
                  EditStep.photos => l10n.publishStepPhotos,
                },
                onPressed: state.hasChanges && !state.isSaving
                    ? () => unawaited(_save())
                    : null,
              )
            : null,
      ),
    );
  }
}
