import 'package:meta/meta.dart';

/// Rôle de la personne connectée dans une discussion : onglet « Achat »
/// (elle a écrit au vendeur) ou « Vente » (on lui écrit sur son annonce).
enum ConversationRole {
  buying('buying'),
  selling('selling');

  new(this.wireName);

  /// Valeur attendue par l'API (`?role=`).
  final String wireName;
}

/// Disponibilité de l'annonce d'une discussion.
enum ConversationListingStatus {
  /// En ligne.
  available,

  /// Réservée par un acheteur.
  reserved,

  /// Vendue.
  sold,

  /// Masquée par le vendeur (ou statut inconnu).
  unavailable,
}

/// Annonce dont parle une discussion.
@immutable
final class ConversationListing {
  const new({
    required this.id,
    required this.title,
    required this.price,
    required this.status,
    this.photoUrl,
  });

  final String id;
  final String title;
  final num price;
  final ConversationListingStatus status;

  /// Photo principale (adresse http(s) vérifiée), si elle existe.
  final String? photoUrl;
}

/// L'autre personne de la discussion.
@immutable
final class ConversationPerson {
  const new({
    required this.id,
    this.name,
    this.avatarUrl,
    this.isIdentityVerified = false,
    this.canReceiveMessages = true,
  });

  final String id;

  /// Nom affiché ; `null` pour un compte supprimé.
  final String? name;

  final String? avatarUrl;
  final bool isIdentityVerified;

  /// Faux si son compte est suspendu ou supprimé : plus d'envoi possible.
  final bool canReceiveMessages;

  bool get isDeleted => name == null;
}

/// Dernier message d'une discussion (aperçu de la liste).
@immutable
final class MessagePreview {
  const new({required this.text, required this.isMine, required this.sentAt});

  /// Début du message (coupé par le serveur).
  final String text;
  final bool isMine;
  final DateTime sentAt;
}

/// Une discussion, vue par la personne connectée.
@immutable
final class ConversationSummary {
  const new({
    required this.id,
    required this.role,
    required this.otherUser,
    this.listing,
    this.lastMessage,
    this.unreadCount = 0,
  });

  final String id;
  final ConversationRole role;
  final ConversationPerson otherUser;

  /// `null` : annonce supprimée (la discussion reste).
  final ConversationListing? listing;

  /// `null` : aucun message encore.
  final MessagePreview? lastMessage;

  /// Messages reçus non lus.
  final int unreadCount;

  /// Copie marquée comme lue.
  ConversationSummary markedRead() => unreadCount == 0
      ? this
      : ConversationSummary(
          id: id,
          role: role,
          otherUser: otherUser,
          listing: listing,
          lastMessage: lastMessage,
        );
}
