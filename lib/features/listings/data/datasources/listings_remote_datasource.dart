import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/features/listings/data/models/listing_categories_model.dart';
import 'package:afrimarket_mobile/features/listings/data/models/listing_page_model.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';
import 'package:dio/dio.dart';

/// Source distante : annonces et catégories (lecture publique).
class ListingsRemoteDataSource {
  const new(this._dio);

  final Dio _dio;

  /// `GET /api/listings?page=&limit=&categoryId=`.
  Future<ListingPage> fetchFeed({
    required int page,
    required int limit,
    String? categoryId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.listings,
      queryParameters: {
        'page': page,
        'limit': limit,
        'categoryId': ?categoryId,
      },
    );
    return ListingPageModel.fromJson(
      _body(response),
      baseUrl: Uri.parse(_dio.options.baseUrl),
    );
  }

  /// `GET /api/filters` : seules les catégories sont utilisées ici.
  Future<List<ListingCategory>> fetchCategories() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.filters);
    return ListingCategoriesModel.fromJson(_body(response));
  }

  static Map<String, dynamic> _body(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) throw const FormatException('Réponse vide');
    return data;
  }
}
