import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/platform/photo_picker.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/publish_listing_usecase.dart';
import 'package:afrimarket_mobile/features/listings/listings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Résultat d'un ajout de photos (message à afficher).
enum PhotoAddOutcome {
  /// Photos ajoutées, ou choix annulé.
  ok,

  /// Galerie ou appareil photo inaccessible (autorisation refusée...).
  unavailable,

  /// Déjà 10 photos.
  full,
}

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
class PublishController extends Notifier<PublishState> {
  @override
  PublishState build() => const PublishState();

  ListingDraft get _draft => state.draft;

  void _update(ListingDraft draft) => state = state._copy(draft: draft);

  /// Photos de la galerie, ajoutées après celles déjà choisies.
  Future<PhotoAddOutcome> addFromGallery() async {
    final room = ListingDraft.maxPhotos - _draft.photos.length;
    if (room <= 0) return PhotoAddOutcome.full;
    final paths = await ref
        .read(photoPickerProvider)
        .pickFromGallery(limit: room);
    if (!ref.mounted) return PhotoAddOutcome.ok;
    if (paths == null) return PhotoAddOutcome.unavailable;
    _addPhotos(paths);
    return PhotoAddOutcome.ok;
  }

  /// Photo prise avec l'appareil photo.
  Future<PhotoAddOutcome> takePhoto() async {
    if (_draft.photos.length >= ListingDraft.maxPhotos) {
      return PhotoAddOutcome.full;
    }
    final (path, error) = await ref.read(photoPickerProvider).takePhoto();
    if (!ref.mounted) return PhotoAddOutcome.ok;
    if (error == PhotoPickError.unavailable) return PhotoAddOutcome.unavailable;
    if (path != null) _addPhotos([path]);
    return PhotoAddOutcome.ok;
  }

  void _addPhotos(List<String> paths) {
    final known = {for (final photo in _draft.photos) photo.path};
    final added = [
      for (final path in paths)
        if (known.add(path)) LocalPhoto(path),
    ];
    _update(
      _draft.copyWith(
        photos: [
          ..._draft.photos,
          ...added,
        ].take(ListingDraft.maxPhotos).toList(),
      ),
    );
  }

  void removePhoto(int index) {
    if (index < 0 || index >= _draft.photos.length) return;
    _update(_draft.copyWith(photos: [..._draft.photos]..removeAt(index)));
  }

  /// La photo [index] devient la photo principale (en premier).
  void makeMainPhoto(int index) {
    if (index <= 0 || index >= _draft.photos.length) return;
    final photos = [..._draft.photos];
    final photo = photos.removeAt(index);
    _update(_draft.copyWith(photos: [photo, ...photos]));
  }

  void setTitle(String title) => _update(_draft.copyWith(title: title));

  /// Prix saisi (chiffres seuls) ; vide = pas de prix.
  void setPrice(String text) =>
      _update(_draft.copyWith(price: () => int.tryParse(text.trim())));

  void setCategory(ListingCategory category) {
    state = state._copy(
      draft: _draft.copyWith(categoryId: category.id),
      category: category,
    );
  }

  void setDistrict(String district) =>
      _update(_draft.copyWith(district: district));

  void setCondition(ListingCondition condition) =>
      _update(_draft.copyWith(condition: condition));

  void setDescription(String text) =>
      _update(_draft.copyWith(description: text));

  void setNegotiable({required bool value}) =>
      _update(_draft.copyWith(isNegotiable: value));

  void setDeliveryMode(DeliveryMode mode) =>
      _update(_draft.copyWith(deliveryMode: mode));

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
