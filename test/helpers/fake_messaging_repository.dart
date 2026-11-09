import 'dart:typed_data';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/chat_message.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:afrimarket_mobile/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:afrimarket_mobile/features/messaging/messaging_providers.dart';
import 'package:flutter_riverpod/misc.dart';

/// Faux dépôt de messagerie : réponses configurables, appels mémorisés.
/// Par défaut : aucune discussion, aucun message.
class FakeMessagingRepository implements MessagingRepository {
  /// Messages envoyés depuis une annonce : (annonce, texte).
  final sent = <(String, String)>[];
  Result<void> answer = const Ok(null);

  /// Discussions par onglet ; `conversationsAnswer` remplace la réponse.
  final conversationsByRole =
      <ConversationRole, CursorPage<ConversationSummary>>{};
  Result<CursorPage<ConversationSummary>>? conversationsAnswer;

  /// Appels de liste : (onglet, curseur).
  final conversationCalls = <(ConversationRole, String?)>[];

  /// En-tête d'une discussion.
  Result<ConversationSummary> conversationAnswer = const Err(NotFoundFailure());

  /// Messages : réponses successives (la dernière est reprise).
  final messagesAnswers = <Result<CursorPage<ChatMessage>>>[
    const Ok(CursorPage(items: [])),
  ];

  /// Appels de messages : curseur `before`.
  final messagesCalls = <String?>[];

  /// Messages envoyés dans une discussion : (discussion, texte).
  final sentInConversation = <(String, String)>[];
  Result<ChatMessage>? sendAnswer;

  /// Photos envoyées : (discussion, fichier).
  final sentPhotos = <(String, String)>[];
  Result<ChatMessage>? sendPhotoAnswer;

  /// Images des photos ; par défaut un petit JPEG factice.
  Result<Uint8List> photoAnswer = Ok(Uint8List.fromList(fakeJpegBytes));
  final photoCalls = <String>[];

  @override
  Future<Result<void>> messageSeller({
    required String listingId,
    required String message,
  }) async {
    sent.add((listingId, message));
    return answer;
  }

  @override
  Future<Result<CursorPage<ConversationSummary>>> conversations({
    required ConversationRole role,
    String? cursor,
  }) async {
    conversationCalls.add((role, cursor));
    return conversationsAnswer ??
        Ok(conversationsByRole[role] ?? const CursorPage(items: []));
  }

  @override
  Future<Result<ConversationSummary>> conversation(String id) async =>
      conversationAnswer;

  @override
  Future<Result<CursorPage<ChatMessage>>> messages(
    String conversationId, {
    String? before,
  }) async {
    messagesCalls.add(before);
    return messagesAnswers.length > 1
        ? messagesAnswers.removeAt(0)
        : messagesAnswers.first;
  }

  @override
  Future<Result<ChatMessage>> send({
    required String conversationId,
    required String text,
  }) async {
    sentInConversation.add((conversationId, text));
    return sendAnswer ??
        Ok(
          ChatMessage(
            id: 'sent-${sentInConversation.length}',
            text: text,
            isMine: true,
            sentAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<Result<ChatMessage>> sendPhoto({
    required String conversationId,
    required String path,
  }) async {
    sentPhotos.add((conversationId, path));
    return sendPhotoAnswer ??
        Ok(
          ChatMessage(
            id: 'photo-${sentPhotos.length}',
            text: '',
            photo: const MessagePhoto(width: 1600, height: 1200),
            isMine: true,
            sentAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<Result<Uint8List>> photo(String messageId) async {
    photoCalls.add(messageId);
    return photoAnswer;
  }
}

/// Début d'un JPEG (non décodable : l'image affiche son état d'erreur).
const fakeJpegBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10];

/// Remplace la messagerie de l'app : aucun test n'appelle le vrai serveur.
List<Override> messagingOverrides([FakeMessagingRepository? repository]) => [
  messagingRepositoryProvider.overrideWithValue(
    repository ?? FakeMessagingRepository(),
  ),
];

/// Discussion de démonstration (onglet Achat, annonce en ligne).
ConversationSummary sampleConversation({
  String id = 'conv-1',
  ConversationRole role = ConversationRole.buying,
  String? name = 'Aminata K.',
  int unread = 0,
  ConversationListingStatus status = ConversationListingStatus.available,
  bool withListing = true,
  bool canReceive = true,
  String preview = 'Oui, toujours disponible.',
  bool lastIsMine = false,
  DateTime? sentAt,
  bool blockedByMe = false,
  bool lastIsPhoto = false,
}) {
  return ConversationSummary(
    id: id,
    role: role,
    otherUser: ConversationPerson(
      id: 'user-$id',
      name: name,
      isIdentityVerified: true,
      canReceiveMessages: canReceive,
    ),
    listing: withListing
        ? ConversationListing(
            id: 'listing-1',
            title: 'Canapé 3 places',
            price: 1200,
            status: status,
          )
        : null,
    lastMessage: MessagePreview(
      text: lastIsPhoto ? '' : preview,
      hasPhoto: lastIsPhoto,
      isMine: lastIsMine,
      sentAt: sentAt ?? DateTime.now(),
    ),
    unreadCount: unread,
    blockedByMe: blockedByMe,
  );
}

/// Message de démonstration.
ChatMessage sampleMessage(
  String id, {
  bool mine = false,
  String? text,
  DateTime? sentAt,
  DateTime? readAt,
  MessagePhoto? photo,
}) => ChatMessage(
  id: id,
  text: photo == null ? text ?? 'Message $id' : '',
  photo: photo,
  isMine: mine,
  sentAt: sentAt ?? DateTime.now(),
  readAt: readAt,
);
