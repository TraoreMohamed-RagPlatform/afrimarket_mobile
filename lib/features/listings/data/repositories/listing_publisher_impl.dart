import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/network/api_guard.dart';
import 'package:afrimarket_mobile/features/listings/data/models/listing_json.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_changes.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listing_publisher.dart';
import 'package:dio/dio.dart';

/// Publication via l'API :
/// - `POST /api/listings` (statut `INACTIVE`) ;
/// - `POST /api/listings/:id/images` (multipart, champ `images`) ;
/// - `PUT /api/listings/:id` (`status: ACTIVE`) ;
/// - `DELETE /api/listings/:id` ;
/// - `PUT /api/listings/:id` (`RESERVED` / `ACTIVE`), `PUT /:id/mark-sold` ;
/// - modification : `PUT /api/listings/:id` (champs modifiés),
///   `DELETE /:id/images/:imageId`, `PUT /:id/images/order`.
class ListingPublisherImpl implements ListingPublisher {
  const new(this._dio);

  /// Envoi des photos : plus long qu'une requête ordinaire (réseau mobile).
  static const uploadTimeout = Duration(seconds: 90);

  final Dio _dio;

  static const Map<ListingCondition, String> _conditions = {
    ListingCondition.brandNew: 'NEW',
    ListingCondition.likeNew: 'LIKE_NEW',
    ListingCondition.good: 'GOOD',
    ListingCondition.fair: 'FAIR',
    ListingCondition.poor: 'POOR',
  };

  static const Map<DeliveryMode, String> _deliveryModes = {
    DeliveryMode.pickup: 'PICKUP',
    DeliveryMode.delivery: 'DELIVERY',
    DeliveryMode.both: 'BOTH',
  };

  /// Corps de `POST /api/listings` (textes nettoyés des espaces autour).
  static Map<String, Object?> createBody(ListingDraft draft) => {
    'title': draft.title.trim(),
    'description': draft.description.trim(),
    'price': draft.price,
    'categoryId': draft.categoryId,
    'city': draft.city,
    'district': draft.district,
    'condition': _conditions[draft.condition],
    'isNegotiable': draft.isNegotiable,
    'deliveryMode': _deliveryModes[draft.deliveryMode],
    'status': 'INACTIVE',
  };

  @override
  Future<Result<String>> createHidden(ListingDraft draft) {
    return guardApiCall(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.listings,
        data: createBody(draft),
      );
      final listing = response.data?['listing'];
      final id = listing is Map<String, dynamic>
          ? ListingJson.safeId(listing['id'])
          : null;
      if (id == null) throw const FormatException('Identifiant invalide');
      return id;
    });
  }

  /// Corps de `PUT /api/listings/:id` : seulement les champs modifiés.
  static Map<String, Object?> updateBody(ListingChanges changes) => {
    'title': ?changes.title,
    'description': ?changes.description,
    'price': ?changes.price,
    'categoryId': ?changes.categoryId,
    'district': ?changes.district,
    'condition': ?_conditions[changes.condition],
    'isNegotiable': ?changes.isNegotiable,
    'deliveryMode': ?_deliveryModes[changes.deliveryMode],
  };

  @override
  Future<Result<void>> update(String listingId, ListingChanges changes) {
    return guardApiCall(() async {
      await _dio.put<void>(
        ApiEndpoints.listing(listingId),
        data: updateBody(changes),
      );
    });
  }

  @override
  Future<Result<void>> deletePhoto(String listingId, String photoId) {
    return guardApiCall(() async {
      await _dio.delete<void>(ApiEndpoints.listingImage(listingId, photoId));
    });
  }

  @override
  Future<Result<void>> reorderPhotos(String listingId, List<String> photoIds) {
    return guardApiCall(() async {
      await _dio.put<void>(
        ApiEndpoints.listingImagesOrder(listingId),
        data: {'imageIds': photoIds},
      );
    });
  }

  @override
  Future<Result<List<RemotePhoto>>> uploadPhotos(
    String listingId,
    List<LocalPhoto> photos,
  ) {
    return guardApiCall(() async {
      final form = FormData();
      for (final (index, photo) in photos.indexed) {
        final isPng = photo.path.toLowerCase().endsWith('.png');
        form.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              photo.path,
              // Nom neutre : le nom du fichier sur le téléphone n'est pas
              // envoyé (il peut contenir des informations personnelles).
              filename: 'photo-${index + 1}.${isPng ? 'png' : 'jpg'}',
              contentType: DioMediaType('image', isPng ? 'png' : 'jpeg'),
            ),
          ),
        );
      }
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.listingImages(listingId),
        data: form,
        options: Options(
          sendTimeout: uploadTimeout,
          receiveTimeout: uploadTimeout,
        ),
      );
      return ListingJson.remotePhotos(
        response.data?['images'],
        Uri.parse(_dio.options.baseUrl),
      );
    });
  }

  @override
  Future<Result<void>> publish(String listingId) {
    return guardApiCall(() async {
      await _dio.put<void>(
        ApiEndpoints.listing(listingId),
        data: {'status': 'ACTIVE'},
      );
    });
  }

  @override
  Future<Result<void>> setReserved(String listingId, {required bool reserved}) {
    return guardApiCall(() async {
      await _dio.put<void>(
        ApiEndpoints.listing(listingId),
        data: {'status': reserved ? 'RESERVED' : 'ACTIVE'},
      );
    });
  }

  @override
  Future<Result<void>> markSold(String listingId) {
    return guardApiCall(() async {
      await _dio.put<void>(ApiEndpoints.markListingSold(listingId));
    });
  }

  @override
  Future<Result<void>> delete(String listingId) {
    return guardApiCall(() async {
      await _dio.delete<void>(ApiEndpoints.listing(listingId));
    });
  }
}
