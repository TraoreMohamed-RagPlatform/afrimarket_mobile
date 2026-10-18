import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:dio/dio.dart';

/// Source distante : `/api/favorites` (connexion requise).
class FavoritesRemoteDataSource {
  const new(this._dio);

  final Dio _dio;

  /// `GET /api/favorites/check/:listingId`.
  Future<bool> isFavorite(String listingId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.favoriteCheck(listingId),
    );
    final data = response.data;
    if (data == null) throw const FormatException('Réponse vide');
    return data['isFavorite'] == true;
  }

  /// `POST /api/favorites`. 400 « déjà dans vos favoris » : réussi.
  Future<void> add(String listingId) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.favorites,
        data: {'listingId': listingId},
      );
    } on DioException catch (exception) {
      if (exception.response?.statusCode == 400) return;
      rethrow;
    }
  }

  /// `DELETE /api/favorites/:listingId`. 404 (déjà retirée) : réussi.
  Future<void> remove(String listingId) async {
    try {
      await _dio.delete<void>(ApiEndpoints.favorite(listingId));
    } on DioException catch (exception) {
      if (exception.response?.statusCode == 404) return;
      rethrow;
    }
  }
}
