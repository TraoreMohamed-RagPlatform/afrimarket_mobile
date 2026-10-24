import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/publish_listing_usecase.dart';
import 'package:afrimarket_mobile/features/listings/listings_providers.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/listing_form_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// État de l'écran « Publier ».
@immutable
final class PublishState {
  const new({
    this.draft = ListingDraft.empty,
    this.category,
    this.showProblems = false,
    this.step,
    this.failure,
    this.publishedId,
  });

  final ListingDraft draft;

  /// Catégorie choisie (pour afficher son nom).
  final ListingCategory? category;

  /// Vrai après une première tentative : les champs à compléter sont
  /// signalés (jamais avant, pour ne pas gronder pendant la saisie).
  final bool showProblems;

  /// Étape de publication en cours ; null = pas en cours.
  final PublishStep? step;

  /// Échec de la dernière publication (message à afficher une fois).
  final Failure? failure;

  /// Annonce publiée : la page ouvre son détail.
  final String? publishedId;

  bool get isPublishing => step != null;

  /// Problèmes à afficher sous les champs.
  Set<DraftProblem> get visibleProblems =>
      showProblems ? draft.problems : const {};

  PublishState _copy({
    ListingDraft? draft,
    ListingCategory? category,
    bool? showProblems,
    PublishStep? Function()? step,
    Failure? Function()? failure,
    String? publishedId,
  }) {
    return PublishState(
      draft: draft ?? this.draft,
      category: category ?? this.category,
      showProblems: showProblems ?? this.showProblems,
      step: step == null ? this.step : step(),
      failure: failure == null ? this.failure : failure(),
      publishedId: publishedId ?? this.publishedId,
    );
  }
}

/// Pilote l'écran « Publier » : saisie, photos, publication.
///
/// Libéré à la fermeture de l'écran : une annonce commencée n'est pas
/// conservée (le brouillon arrivera plus tard, backlog C1).
class PublishController extends Notifier<PublishState>
    with ListingDraftEditor<PublishState> {
  @override
  PublishState build() => const PublishState();

  ListingDraft get _draft => state.draft;

  @override
  ListingDraft get formDraft => state.draft;

  @override
  void emitDraft(ListingDraft draft, {ListingCategory? category}) =>
      state = state._copy(draft: draft, category: category);

  /// Publie l'annonce. Incomplète : les champs à revoir sont signalés,
  /// sans appel au serveur.
  Future<void> publish() async {
    if (state.isPublishing || state.publishedId != null) return;
    if (!_draft.isReady) {
      state = state._copy(showProblems: true);
      return;
    }

    state = state._copy(
      showProblems: true,
      step: () => PublishStep.creating,
      failure: () => null,
    );
    final result = await ref.read(publishListingUseCaseProvider)(
      _draft,
      onStep: (step) {
        if (ref.mounted) state = state._copy(step: () => step);
      },
    );
    if (!ref.mounted) return;

    switch (result) {
      case Ok(:final value):
        state = state._copy(step: () => null, publishedId: value);
      case Err(:final failure):
        state = state._copy(step: () => null, failure: () => failure);
    }
  }

  /// Le message d'échec a été affiché.
  void failureShown() => state = state._copy(failure: () => null);
}

final NotifierProvider<PublishController, PublishState>
publishControllerProvider =
    NotifierProvider.autoDispose<PublishController, PublishState>(
      PublishController.new,
    );
