import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/features/listings/data/models/listing_categories_model.dart';
import 'package:afrimarket_mobile/features/listings/data/models/listing_detail_model.dart';
import 'package:afrimarket_mobile/features/listings/data/models/listing_json.dart';
import 'package:afrimarket_mobile/features/listings/data/models/listing_locations_model.dart';
import 'package:afrimarket_mobile/features/listings/data/models/listing_page_model.dart';
import 'package:afrimarket_mobile/features/listings/data/models/seller_contact_model.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/feed_filters.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_locations.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/report_reason.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/seller_contact.dart';
import 'package:dio/dio.dart';

/// Source distante : annonces, catégories, détail, contact, signalement.
class ListingsRemoteDataSource {
  const new(this._dio);

  final Dio _dio;

  /// `GET /api/listings?page=&limit=&categoryId=&city=&district=&sort=`
  /// `&minPrice=&maxPrice=` (seuls les filtres choisis sont envoyés).
  Future<ListingPage> fetchFeed({
    required int page,
    required int limit,
    String? categoryId,
    FeedFilters filters = FeedFilters.none,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.listings,
      queryParameters: {
        'page': page,
        'limit': limit,
        'categoryId': ?categoryId,
        'city': ?filters.city,
        'district': ?filters.district,
        if (filters.sort != FeedSort.newest) 'sort': filters.sort.apiValue,
        'minPrice': ?filters.minPrice,
        'maxPrice': ?filters.maxPrice,
      },
    );
    return ListingPageModel.fromJson(_body(response), baseUrl: _baseUrl);
  }

  /// `GET /api/filters` : seules les catégories sont utilisées ici.
  Future<List<ListingCategory>> fetchCategories() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.filters);
    return ListingCategoriesModel.fromJson(_body(response));
  }

  /// `GET /api/listings/:id`.
  Future<ListingDetail> fetchListing(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.listing(id),
    );
    return ListingDetailModel.fromJson(_body(response), baseUrl: _baseUrl);
  }

  /// `GET /api/listings/:id/similar`.
  Future<List<ListingSummary>> fetchSimilar(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.similarListings(id),
    );
    return ListingJson.summaries(_body(response)['listings'], _baseUrl);
  }

  /// `GET /api/filters` : villes et quartiers.
  Future<ListingLocations> fetchLocations() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.filters);
    return ListingLocationsModel.fromJson(_body(response));
  }

  /// `GET /api/listings/:id/contact` (connexion requise).
  Future<SellerContact> fetchSellerContact(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.listingContact(id),
    );
    return SellerContactModel.fromJson(_body(response));
  }

  /// `POST /api/listings/:id/report` (connexion requise).
  ///
  /// 409 (déjà signalée par cette personne) : considéré comme réussi.
  Future<void> reportListing({
    required String id,
    required ReportReason reason,
    String? details,
  }) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.reportListing(id),
        data: {'reason': reason.apiValue, 'details': ?details},
      );
    } on DioException catch (exception) {
      if (exception.response?.statusCode == 409) return;
      rethrow;
    }
  }

  Uri get _baseUrl => Uri.parse(_dio.options.baseUrl);

  static Map<String, dynamic> _body(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) throw const FormatException('Réponse vide');
    return data;
  }
}
