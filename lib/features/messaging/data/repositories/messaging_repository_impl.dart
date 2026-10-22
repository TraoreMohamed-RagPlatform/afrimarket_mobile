import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_guard.dart';
import 'package:afrimarket_mobile/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/chat_message.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/cursor_page.dart';
import 'package:afrimarket_mobile/features/messaging/domain/repositories/messaging_repository.dart';

/// Implémentation du contrat [MessagingRepository].
class MessagingRepositoryImpl implements MessagingRepository {
  const new(this._remote);

  final MessagingRemoteDataSource _remote;

  @override
  Future<Result<void>> messageSeller({
    required String listingId,
    required String message,
  }) {
    return guardApiCall(
      () => _remote.messageSeller(listingId: listingId, message: message),
    );
  }

  @override
  Future<Result<CursorPage<ConversationSummary>>> conversations({
    required ConversationRole role,
    String? cursor,
  }) => guardApiCall(() => _remote.conversations(role: role, cursor: cursor));

  @override
  Future<Result<ConversationSummary>> conversation(String id) =>
      guardApiCall(() => _remote.conversation(id));

  @override
  Future<Result<CursorPage<ChatMessage>>> messages(
    String conversationId, {
    String? before,
  }) => guardApiCall(() => _remote.messages(conversationId, before: before));

  @override
  Future<Result<ChatMessage>> send({
    required String conversationId,
    required String text,
  }) => guardApiCall(
    () => _remote.send(conversationId: conversationId, text: text),
  );
}
