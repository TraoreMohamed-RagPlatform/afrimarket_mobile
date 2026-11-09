import 'dart:typed_data';

import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/features/messaging/data/models/messaging_json.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/chat_message.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:dio/dio.dart';

/// Source distante : `/api/messages` (connexion requise).
class MessagingRemoteDataSource {
  const new(this._dio);

  /// Envoi d'une photo : plus long qu'un texte sur un réseau mobile lent.
  static const uploadTimeout = Duration(seconds: 90);

  /// Taille maximale d'une image reçue (le serveur envoie ≤ 1600 px).
  static const int maxPhotoBytes = 8 * 1024 * 1024;

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

  /// `POST /api/messages/photos` (multipart : `conversationId`, `photo`).
  Future<ChatMessage> sendPhoto({
    required String conversationId,
    required String path,
  }) async {
    final isPng = path.toLowerCase().endsWith('.png');
    final form = FormData.fromMap({
      'conversationId': conversationId,
      'photo': await MultipartFile.fromFile(
        path,
        // Nom neutre : le nom du fichier sur le téléphone n'est pas envoyé
        // (il peut contenir des informations personnelles).
        filename: isPng ? 'photo.png' : 'photo.jpg',
        contentType: DioMediaType('image', isPng ? 'png' : 'jpeg'),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.messagePhotos,
      data: form,
      options: Options(
        sendTimeout: uploadTimeout,
        receiveTimeout: uploadTimeout,
      ),
    );
    final message = MessagingJson.message(response.data);
    if (message == null || message.photo == null) {
      throw const FormatException('Message invalide');
    }
    return message;
  }

  /// `GET /api/messages/photos/:messageId` : image JPEG (connexion
  /// requise ; le jeton est ajouté par le client Dio).
  ///
  /// Sécurité : seule une image JPEG de taille raisonnable est acceptée.
  Future<Uint8List> photo(String messageId) async {
    final response = await _dio.get<List<int>>(
      ApiEndpoints.messagePhoto(messageId),
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || !isJpeg(bytes) || bytes.length > maxPhotoBytes) {
      throw const FormatException('Photo invalide');
    }
    return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  }

  /// Le contenu commence-t-il comme un JPEG (FF D8 FF) ?
  static bool isJpeg(List<int> bytes) =>
      bytes.length > 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF;
}
