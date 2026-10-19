import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/platform/photo_picker.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listing_publisher.dart';
import 'package:afrimarket_mobile/features/listings/listings_providers.dart';
import 'package:flutter_riverpod/misc.dart';

/// Faux service de publication : réponses configurables, appels mémorisés.
///
/// Par défaut : tout réussit, l'annonce créée s'appelle « new-1 ».
class FakeListingPublisher implements ListingPublisher {
  Result<String> created = const Ok('new-1');
  Result<void> uploaded = const Ok(null);
  Result<void> published = const Ok(null);
  Result<void> deleted = const Ok(null);
  Result<void> reserved = const Ok(null);
  Result<void> sold = const Ok(null);

  /// Appels dans l'ordre : « create », « upload:new-1:2 », « publish:new-1 »...
  final calls = <String>[];
  final drafts = <ListingDraft>[];
  final uploadedPhotos = <List<LocalPhoto>>[];

  @override
  Future<Result<String>> createHidden(ListingDraft draft) async {
    calls.add('create');
    drafts.add(draft);
    return created;
  }

  @override
  Future<Result<void>> uploadPhotos(
    String listingId,
    List<LocalPhoto> photos,
  ) async {
    calls.add('upload:$listingId:${photos.length}');
    uploadedPhotos.add(photos);
    return uploaded;
  }

  @override
  Future<Result<void>> publish(String listingId) async {
    calls.add('publish:$listingId');
    return published;
  }

  @override
  Future<Result<void>> delete(String listingId) async {
    calls.add('delete:$listingId');
    return deleted;
  }

  @override
  Future<Result<void>> setReserved(
    String listingId, {
    required bool reserved,
  }) async {
    calls.add('reserved:$listingId:$reserved');
    return this.reserved;
  }

  @override
  Future<Result<void>> markSold(String listingId) async {
    calls.add('sold:$listingId');
    return sold;
  }
}

/// Faux sélecteur de photos : renvoie des chemins prévus à l'avance.
class FakePhotoPicker implements PhotoPicker {
  /// Réponse de la galerie ; `null` = accès refusé.
  List<String>? gallery = const ['/photos/a.jpg', '/photos/b.jpg'];

  /// Réponse de l'appareil photo.
  (String?, PhotoPickError) camera = (
    '/photos/camera.jpg',
    PhotoPickError.none,
  );

  final limits = <int>[];

  @override
  Future<List<String>?> pickFromGallery({required int limit}) async {
    limits.add(limit);
    return gallery?.take(limit).toList();
  }

  @override
  Future<(String?, PhotoPickError)> takePhoto() async => camera;
}

/// Remplace la publication et le choix des photos de l'app.
List<Override> publishOverrides({
  FakeListingPublisher? publisher,
  FakePhotoPicker? picker,
}) => [
  listingPublisherProvider.overrideWithValue(
    publisher ?? FakeListingPublisher(),
  ),
  photoPickerProvider.overrideWithValue(picker ?? FakePhotoPicker()),
];
