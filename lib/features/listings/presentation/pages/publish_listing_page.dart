import 'dart:async';

import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/publish_listing_usecase.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/publish_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/listing_form.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/snackbar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Publication d'une annonce (plein écran, par-dessus les onglets).
///
/// Une seule page, comme Facebook Marketplace : le formulaire commun
/// (`ListingForm`), puis « Publier » en bas.
///
/// - réservée aux utilisateurs connectés (garde de navigation) ;
/// - les champs à compléter ne sont signalés qu'après un premier essai ;
/// - quitter avec une saisie en cours demande confirmation ;
/// - publiée : ouverture de l'annonce, le fil est actualisé.
class PublishListingPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PublishListingPage> createState() => _PublishListingPageState();
}

class _PublishListingPageState extends ConsumerState<PublishListingPage> {
  PublishController get _controller =>
      ref.read(publishControllerProvider.notifier);

  /// Ferme l'écran ; ouvert seul (après une connexion), retour au fil.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _confirmLeave() async {
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.publishDiscardTitle),
        content: Text(l10n.publishDiscardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.publishDiscardCancel),
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

  void _onPublished(String id) {
    unawaited(HapticFeedback.mediumImpact());
    // La nouvelle annonce apparaît en tête du fil.
    unawaited(ref.read(feedControllerProvider.notifier).refresh());
    context.showAppSnackBar(context.l10n.publishSuccess);
    context.pushReplacement(AppRoutes.listing(id));
  }

  Future<void> _publish() async {
    FocusScope.of(context).unfocus();
    await _controller.publish();
    if (!mounted) return;
    final state = ref.read(publishControllerProvider);
    if (!state.isPublishing &&
        state.publishedId == null &&
        state.failure == null &&
        !state.draft.isReady) {
      context.showAppSnackBar(context.l10n.publishFixProblems);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(publishControllerProvider);

    ref.listen(publishControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure != null && previous?.failure == null) {
        context.showAppSnackBar(failure.message(context.l10n));
        _controller.failureShown();
      }
      final id = next.publishedId;
      if (id != null && previous?.publishedId == null) _onPublished(id);
    });

    final canLeave = state.draft.isEmpty && !state.isPublishing;

    return PopScope(
      canPop: canLeave && context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || state.isPublishing) return;
        canLeave ? _leave() : unawaited(_confirmLeave());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.publishCloseTooltip,
            icon: const Icon(AppIcons.x),
            onPressed: state.isPublishing
                ? null
                : () => canLeave ? _leave() : unawaited(_confirmLeave()),
          ),
          title: Text(l10n.publishTitle),
        ),
        body: AbsorbPointer(
          absorbing: state.isPublishing,
          // Défilement simple (pas de liste paresseuse) : un champ qui sort
          // de l'écran garde sa saisie.
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListingForm(
                  draft: state.draft,
                  category: state.category,
                  problems: state.visibleProblems,
                  actions: _controller,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _PublishBar(state: state, onPublish: _publish),
      ),
    );
  }
}

// ---------------------------------------------------------------- Bas

class _PublishBar extends StatelessWidget {
  const new({required this.state, required this.onPublish});

  final PublishState state;
  final Future<void> Function() onPublish;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final step = state.step;
    return ListingSubmitBar(
      buttonKey: const Key('publish-submit'),
      busy: step != null,
      label: switch (step) {
        null => l10n.publishSubmit,
        PublishStep.creating => l10n.publishStepCreating,
        PublishStep.uploadingPhotos => l10n.publishStepPhotos,
        PublishStep.publishing => l10n.publishStepPublishing,
      },
      onPressed: step == null ? () => unawaited(onPublish()) : null,
    );
  }
}
