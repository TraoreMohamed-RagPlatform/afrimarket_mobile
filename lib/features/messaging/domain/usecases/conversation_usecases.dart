import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/chat_message.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:afrimarket_mobile/features/messaging/domain/message_rules.dart';
import 'package:afrimarket_mobile/features/messaging/domain/repositories/messaging_repository.dart';

/// Cas d'usage : mes discussions (onglet Achat ou Vente).
class GetConversationsUseCase {
  const new(this._repository);

  final MessagingRepository _repository;

  Future<Result<CursorPage<ConversationSummary>>> call({
    required ConversationRole role,
    String? cursor,
  }) => _repository.conversations(role: role, cursor: cursor);
}

/// Cas d'usage : en-tête d'une discussion.
class GetConversationUseCase {
  const new(this._repository);

  final MessagingRepository _repository;

  Future<Result<ConversationSummary>> call(String id) =>
      _repository.conversation(id);
}

/// Cas d'usage : messages d'une discussion, page par page.
class GetMessagesUseCase {
  const new(this._repository);

  final MessagingRepository _repository;

  Future<Result<CursorPage<ChatMessage>>> call(
    String conversationId, {
    String? before,
  }) => _repository.messages(conversationId, before: before);
}

/// Cas d'usage : envoyer un message dans une discussion.
class SendMessageUseCase {
  const new(this._repository);

  final MessagingRepository _repository;

  /// Vide ou trop long : [ValidationFailure], sans appel au serveur.
  /// Refus du serveur : [ConflictFailure] si l'autre personne ne peut plus
  /// recevoir de messages (`MessagingConflicts.recipientUnavailable`).
  Future<Result<ChatMessage>> call({
    required String conversationId,
    required String text,
  }) {
    final clean = MessageRules.clean(text);
    if (clean == null) {
      return Future.value(const Err(ValidationFailure()));
    }
    return _repository.send(conversationId: conversationId, text: clean);
  }
}
