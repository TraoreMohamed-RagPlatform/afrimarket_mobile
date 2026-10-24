import 'package:afrimarket_mobile/core/platform/photo_picker.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Résultat d'un ajout de photos (message à afficher).
enum PhotoAddOutcome {
  /// Photos ajoutées, ou choix annulé.
  ok,

  /// Galerie ou appareil photo inaccessible (autorisation refusée...).
  unavailable,

  /// Déjà 10 photos.
  full,
}

/// Actions du formulaire d'annonce (`ListingForm`), communes aux écrans
/// « Publier » et « Modifier ».
abstract interface class ListingFormActions {
  Future<PhotoAddOutcome> addFromGallery();
  Future<PhotoAddOutcome> takePhoto();
  void removePhoto(int index);
  void makeMainPhoto(int index);
  void setTitle(String title);
  void setPrice(String text);
  void setCategory(ListingCategory category);
  void setDistrict(String district);
  void setCondition(ListingCondition condition);
  void setDescription(String text);
  void setNegotiable({required bool value});
  void setDeliveryMode(DeliveryMode mode);
}

/// Saisie d'une annonce, partagée par les contrôleurs de « Publier » et
/// « Modifier » : chacun dit où lire et ranger la saisie.
mixin ListingDraftEditor<S> on Notifier<S> implements ListingFormActions {
  /// Saisie en cours.
  ListingDraft get formDraft;

  /// Range la nouvelle saisie (et la catégorie choisie, si elle change).
  void emitDraft(ListingDraft draft, {ListingCategory? category});

  void _update(ListingDraft draft) => emitDraft(draft);

  /// Photos de la galerie, ajoutées après celles déjà choisies.
  @override
  Future<PhotoAddOutcome> addFromGallery() async {
    final room = ListingDraft.maxPhotos - formDraft.photos.length;
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
  @override
  Future<PhotoAddOutcome> takePhoto() async {
    if (formDraft.photos.length >= ListingDraft.maxPhotos) {
      return PhotoAddOutcome.full;
    }
    final (path, error) = await ref.read(photoPickerProvider).takePhoto();
    if (!ref.mounted) return PhotoAddOutcome.ok;
    if (error == PhotoPickError.unavailable) return PhotoAddOutcome.unavailable;
    if (path != null) _addPhotos([path]);
    return PhotoAddOutcome.ok;
  }

  void _addPhotos(List<String> paths) {
    final draft = formDraft;
    final known = {for (final photo in draft.localPhotos) photo.path};
    final added = [
      for (final path in paths)
        if (known.add(path)) LocalPhoto(path),
    ];
    _update(
      draft.copyWith(
        photos: [
          ...draft.photos,
          ...added,
        ].take(ListingDraft.maxPhotos).toList(),
      ),
    );
  }

  @override
  void removePhoto(int index) {
    final photos = formDraft.photos;
    if (index < 0 || index >= photos.length) return;
    _update(formDraft.copyWith(photos: [...photos]..removeAt(index)));
  }

  /// La photo [index] devient la photo principale (en premier).
  @override
  void makeMainPhoto(int index) {
    final photos = [...formDraft.photos];
    if (index <= 0 || index >= photos.length) return;
    final photo = photos.removeAt(index);
    _update(formDraft.copyWith(photos: [photo, ...photos]));
  }

  @override
  void setTitle(String title) => _update(formDraft.copyWith(title: title));

  /// Prix saisi (chiffres seuls) ; vide = pas de prix.
  @override
  void setPrice(String text) =>
      _update(formDraft.copyWith(price: () => int.tryParse(text.trim())));

  @override
  void setCategory(ListingCategory category) => emitDraft(
    formDraft.copyWith(categoryId: category.id),
    category: category,
  );

  @override
  void setDistrict(String district) =>
      _update(formDraft.copyWith(district: district));

  @override
  void setCondition(ListingCondition condition) =>
      _update(formDraft.copyWith(condition: condition));

  @override
  void setDescription(String text) =>
      _update(formDraft.copyWith(description: text));

  @override
  void setNegotiable({required bool value}) =>
      _update(formDraft.copyWith(isNegotiable: value));

  @override
  void setDeliveryMode(DeliveryMode mode) =>
      _update(formDraft.copyWith(deliveryMode: mode));
}
