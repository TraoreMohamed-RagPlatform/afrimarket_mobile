import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/chat_message.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/cursor_page.dart';

/// Contrat : messagerie entre acheteurs et vendeurs (connexion requise).
///
/// Une discussion est liée à une annonce : une seule par annonce et par
/// acheteur (comme Facebook Marketplace).
abstract interface class MessagingRepository {
  /// Envoie [message] au vendeur de l'annonce [listingId], dans la
  /// discussion de la personne connectée pour cette annonce (ouverte si
  /// besoin).
  Future<Result<void>> messageSeller({
    required String listingId,
    required String message,
  });

  /// Mes discussions en tant qu'acheteur ou vendeur, dernier message en
  /// premier. [cursor] : page suivante.
  Future<Result<CursorPage<ConversationSummary>>> conversations({
    required ConversationRole role,
    String? cursor,
  });

  /// Une discussion (en-tête : annonce, autre personne).
  Future<Result<ConversationSummary>> conversation(String id);

  /// Messages d'une discussion, les plus récents d'abord. [before] :
  /// messages plus anciens que celui-ci. La première page marque les
  /// messages reçus comme lus.
  Future<Result<CursorPage<ChatMessage>>> messages(
    String conversationId, {
    String? before,
  });

  /// Envoie [text] dans la discussion [conversationId].
  Future<Result<ChatMessage>> send({
    required String conversationId,
    required String text,
  });
}
