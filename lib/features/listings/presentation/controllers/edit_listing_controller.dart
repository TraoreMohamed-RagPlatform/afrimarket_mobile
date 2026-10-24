import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:afrimarket_mobile/features/listings/domain/listing_conflicts.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/edit_listing_usecase.dart';
import 'package:afrimarket_mobile/features/listings/listings_providers.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/listing_form_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:meta/meta.dart';

/// Étape de l'écran « Modifier ».
enum EditPhase {
  /// Lecture de l'annonce.
  loading,

  /// Formulaire affiché.
  ready,

  /// Introuvable, ou pas une annonce de la personne connectée.
  unavailable,

  /// Vendue : plus modifiable.
  sold,

  /// Lecture impossible (réseau...) : « Réessayer ».
  failed,
}

/// État de l'écran « Modifier ».
@immutable
final class EditListingState {
  const new({
    this.phase = EditPhase.loading,
    this.loadFailure,
    this.original = ListingDraft.empty,
    this.draft = ListingDraft.empty,
    this.category,
    this.revision = 0,
    this.showProblems = false,
    this.step,
    this.failure,
    this.partiallySaved = false,
    this.saved = false,
  });

  final EditPhase phase;
  final Failure? loadFailure;

  /// L'annonce telle qu'elle est en ligne.
  final ListingDraft original;

  /// La saisie.
  final ListingDraft draft;
  final ListingCategory? category;

  /// Change quand la saisie est relue depuis le serveur : le formulaire
  /// est alors recréé.
  final int revision;

  /// Vrai après un essai d'enregistrement incomplet.
  final bool showProblems;

  /// Enregistrement en cours ; null = pas en cours.
  final EditStep? step;

  /// Échec du dernier enregistrement (message à afficher une fois).
  final Failure? failure;

  /// L'échec est arrivé après un premier changement enregistré : la saisie
  /// a été relue depuis le serveur.
  final bool partiallySaved;

  /// Tout est enregistré : la page se ferme.
  final bool saved;

  bool get isSaving => step != null;

  /// Quelque chose à enregistrer.
  bool get hasChanges => phase == EditPhase.ready && draft != original;

  Set<DraftProblem> get visibleProblems =>
      showProblems ? draft.problems : const {};

  EditListingState _copy({
    EditPhase? phase,
    Failure? Function()? loadFailure,
    ListingDraft? original,
    ListingDraft? draft,
    ListingCategory? category,
    int? revision,
    bool? showProblems,
    EditStep? Function()? step,
    Failure? Function()? failure,
    bool? partiallySaved,
    bool? saved,
  }) {
    return EditListingState(
      phase: phase ?? this.phase,
      loadFailure: loadFailure == null ? this.loadFailure : loadFailure(),
      original: original ?? this.original,
      draft: draft ?? this.draft,
      category: category ?? this.category,
      revision: revision ?? this.revision,
      showProblems: showProblems ?? this.showProblems,
      step: step == null ? this.step : step(),
      failure: failure == null ? this.failure : failure(),
      partiallySaved: partiallySaved ?? this.partiallySaved,
      saved: saved ?? this.saved,
    );
  }
}

/// Pilote l'écran « Modifier l'annonce » (comme Facebook Marketplace) :
/// formulaire de « Publier » rempli avec l'annonce, seuls les changements
/// sont enregistrés.
class EditListingController extends Notifier<EditListingState>
    with ListingDraftEditor<EditListingState> {
  new(this.listingId);

  final String listingId;

  @override
  EditListingState build() {
    unawaited(Future.microtask(_load));
    return const EditListingState();
  }

  @override
  ListingDraft get formDraft => state.draft;

  @override
  void emitDraft(ListingDraft draft, {ListingCategory? category}) =>
      state = state._copy(draft: draft, category: category);

  /// « Réessayer » après un échec de lecture.
  Future<void> retry() {
    state = state._copy(phase: EditPhase.loading, loadFailure: () => null);
    return _load();
  }

  /// Lit l'annonce en ligne ; [afterFailure] : relecture après un
  /// enregistrement interrompu (l'échec reste à afficher).
  Future<void> _load({Failure? afterFailure}) async {
    final result = await ref.read(getListingDetailUseCaseProvider)(listingId);
    if (!ref.mounted) return;

    switch (result) {
      case Ok(:final value) when !value.isOwner:
        state = state._copy(phase: EditPhase.unavailable);
      case Ok(:final value) when value.isSold:
        state = state._copy(phase: EditPhase.sold);
      case Ok(:final value):
        final draft = ListingDraft.fromDetail(value);
        state = EditListingState(
          phase: EditPhase.ready,
          original: draft,
          draft: draft,
          category: value.category,
          revision: state.revision + 1,
          failure: afterFailure,
          partiallySaved: afterFailure != null,
        );
      case Err(failure: NotFoundFailure()):
        state = state._copy(phase: EditPhase.unavailable);
      case Err(:final failure):
        // Après un enregistrement interrompu, la saisie reste affichée.
        state = afterFailure != null
            ? state._copy(failure: () => afterFailure, step: () => null)
            : state._copy(phase: EditPhase.failed, loadFailure: () => failure);
    }
  }

  /// Enregistre les changements. Incomplet : les champs à revoir sont
  /// signalés, sans appel au serveur.
  Future<void> save() async {
    final current = state;
    if (!current.hasChanges || current.isSaving) return;
    if (!current.draft.isReady) {
      state = current._copy(showProblems: true);
      return;
    }

    state = current._copy(
      showProblems: true,
      step: () => EditStep.details,
      failure: () => null,
      partiallySaved: false,
    );
    var applied = false;
    final result = await ref.read(editListingUseCaseProvider)(
      listingId: listingId,
      original: current.original,
      edited: current.draft,
      onStep: (step) {
        if (ref.mounted) state = state._copy(step: () => step);
      },
      onApplied: () => applied = true,
    );
    if (!ref.mounted) return;

    switch (result) {
      case Ok():
        state = state._copy(
          step: () => null,
          original: state.draft,
          saved: true,
        );
      case Err(failure: ConflictFailure(code: ListingConflicts.sold)):
        state = state._copy(step: () => null, phase: EditPhase.sold);
      case Err(:final failure) when applied:
        // À moitié enregistrée : on repart de l'annonce en ligne.
        await _load(afterFailure: failure);
      case Err(:final failure):
        state = state._copy(step: () => null, failure: () => failure);
    }
  }

  /// Le message d'échec a été affiché.
  void failureShown() =>
      state = state._copy(failure: () => null, partiallySaved: false);
}

/// Écran « Modifier » d'une annonce ; libéré à sa fermeture.
final NotifierProviderFamily<EditListingController, EditListingState, String>
editListingControllerProvider = NotifierProvider.autoDispose
    .family<EditListingController, EditListingState, String>(
      EditListingController.new,
    );
