import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:dio/dio.dart';

/// Source distante : `/api/messages` (connexion requise).
class MessagingRemoteDataSource {
  const new(this._dio);

  /// Identifiant de discussion accepté (cuid du serveur).
  static final RegExp _safeId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  final Dio _dio;

  /// `POST /api/messages/conversations` (discussion de l'annonce, ouverte
  /// si besoin) puis `POST /api/messages`.
  ///
  /// L'acheteur et le vendeur sont déduits par le serveur : seule
  /// l'annonce est envoyée.
  Future<void> messageSeller({
    required String listingId,
    required String message,
  }) async {
    final conversation = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.conversations,
      data: {'listingId': listingId},
    );
    final id = conversation.data?['id'];
    if (id is! String || !_safeId.hasMatch(id)) {
      throw const FormatException('Discussion invalide');
    }

    await _dio.post<void>(
      ApiEndpoints.messages,
      data: {'conversationId': id, 'content': message},
    );
  }
}
