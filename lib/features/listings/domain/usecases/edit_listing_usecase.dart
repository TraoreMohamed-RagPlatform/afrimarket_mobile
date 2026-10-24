import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_changes.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listing_publisher.dart';

/// Étape en cours (affichée pendant l'enregistrement).
enum EditStep { details, photos }

/// Cas d'usage : enregistrer la modification d'une annonce en ligne.
///
/// 1. les champs modifiés (et seulement eux) ;
/// 2. les photos : retraits, ajouts, puis le nouvel ordre.
///
/// L'annonce n'est jamais sans photo (le serveur le refuse) ni au-delà de
/// 10 photos : si toutes les photos sont remplacées, une ancienne reste en
/// place jusqu'à l'arrivée des nouvelles.
class EditListingUseCase {
  const new(this._publisher);

  final ListingPublisher _publisher;

  /// [original] : l'annonce telle qu'elle est en ligne ; [edited] : la
  /// saisie. [onApplied] est appelé dès qu'un changement est enregistré
  /// (un échec ensuite laisse donc l'annonce à moitié modifiée).
  Future<Result<void>> call({
    required String listingId,
    required ListingDraft original,
    required ListingDraft edited,
    void Function(EditStep step)? onStep,
    void Function()? onApplied,
  }) async {
    if (!edited.isReady) return const Err(ValidationFailure());

    final changes = ListingChanges.between(original, edited);
    if (!changes.isEmpty) {
      onStep?.call(EditStep.details);
      final updated = await _publisher.update(listingId, changes);
      if (updated case Err(:final failure)) return Err(failure);
      onApplied?.call();
    }

    return await _savePhotos(
      listingId,
      original: original,
      edited: edited,
      onStep: onStep,
      onApplied: onApplied,
    );
  }

  Future<Result<void>> _savePhotos(
    String listingId, {
    required ListingDraft original,
    required ListingDraft edited,
    void Function(EditStep step)? onStep,
    void Function()? onApplied,
  }) async {
    // Photos en ligne, dans l'ordre du serveur, tenu à jour étape par étape.
    final online = [
      for (final photo in original.photos)
        if (photo is RemotePhoto) photo.id,
    ];
    final kept = {
      for (final photo in edited.photos)
        if (photo is RemotePhoto) photo.id,
    };
    final removed = [
      for (final id in online)
        if (!kept.contains(id)) id,
    ];
    final added = edited.localPhotos;

    List<String> wanted(List<String> uploaded) {
      final next = uploaded.iterator;
      return [
        for (final photo in edited.photos)
          switch (photo) {
            RemotePhoto(:final id) => id,
            LocalPhoto() => (next..moveNext()).current,
          },
      ];
    }

    if (removed.isEmpty && added.isEmpty && _same(wanted(const []), online)) {
      return const Ok(null);
    }
    onStep?.call(EditStep.photos);

    // Toutes remplacées : une ancienne photo reste jusqu'aux nouvelles.
    final anchor = kept.isEmpty && removed.isNotEmpty ? removed.first : null;

    Future<Failure?> remove(String id) async {
      final result = await _publisher.deletePhoto(listingId, id);
      if (result case Err(:final failure)) return failure;
      online.remove(id);
      onApplied?.call();
      return null;
    }

    final uploaded = <String>[];
    Future<Failure?> upload(List<LocalPhoto> photos) async {
      if (photos.isEmpty) return null;
      final result = await _publisher.uploadPhotos(listingId, photos);
      switch (result) {
        case Err(:final failure):
          return failure;
        case Ok(:final value):
          onApplied?.call();
          if (value.length != photos.length) return const UnexpectedFailure();
          final ids = [for (final photo in value) photo.id];
          online.addAll(ids);
          uploaded.addAll(ids);
          return null;
      }
    }

    for (final id in removed) {
      if (id == anchor) continue;
      if (await remove(id) case final failure?) return Err(failure);
    }
    final room = ListingDraft.maxPhotos - online.length;
    if (await upload(added.take(room).toList()) case final failure?) {
      return Err(failure);
    }
    if (anchor != null) {
      if (await remove(anchor) case final failure?) return Err(failure);
    }
    if (await upload(added.skip(room).toList()) case final failure?) {
      return Err(failure);
    }

    final order = wanted(uploaded);
    if (!_same(order, online)) {
      final reordered = await _publisher.reorderPhotos(listingId, order);
      if (reordered case Err(:final failure)) return Err(failure);
      onApplied?.call();
    }
    return const Ok(null);
  }

  static bool _same(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
