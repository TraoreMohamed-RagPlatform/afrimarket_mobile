import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/features/messaging/data/models/messaging_json.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/chat_message.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/cursor_page.dart';
import 'package:dio/dio.dart';

/// Source distante : `/api/messages` (connexion requise).
class MessagingRemoteDataSource {
  const new(this._dio);

  final Dio _dio;

  Uri get _baseUrl => Uri.parse(_dio.options.baseUrl);

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
    final id = MessagingJson.safeId(conversation.data?['id']);
    if (id == null) throw const FormatException('Discussion invalide');

    await _dio.post<void>(
      ApiEndpoints.messages,
      data: {'conversationId': id, 'content': message},
    );
  }

  /// `GET /api/messages/conversations?role=&cursor=`.
  Future<CursorPage<ConversationSummary>> conversations({
    required ConversationRole role,
    String? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.conversations,
      queryParameters: {'role': role.wireName, 'cursor': ?cursor},
    );
    return MessagingJson.page(
      response.data,
      'conversations',
      (item) => MessagingJson.conversation(item, _baseUrl),
    );
  }

  /// `GET /api/messages/conversations/:id`.
  Future<ConversationSummary> conversation(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.conversation(id),
    );
    final conversation = MessagingJson.conversation(response.data, _baseUrl);
    if (conversation == null) throw const FormatException('Discussion');
    return conversation;
  }

  /// `GET /api/messages/:id?before=`.
  Future<CursorPage<ChatMessage>> messages(
    String conversationId, {
    String? before,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.conversationMessages(conversationId),
      queryParameters: {'before': ?before},
    );
    return MessagingJson.page(response.data, 'messages', MessagingJson.message);
  }

  /// `POST /api/messages`.
  Future<ChatMessage> send({
    required String conversationId,
    required String text,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.messages,
      data: {'conversationId': conversationId, 'content': text},
    );
    final message = MessagingJson.message(response.data);
    if (message == null) throw const FormatException('Message invalide');
    return message;
  }
}
