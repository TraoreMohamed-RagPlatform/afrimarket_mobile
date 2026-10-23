import 'package:meta/meta.dart';

/// Ce qui a déclenché une notification (texte et icône dans l'app).
enum NotificationKind {
  /// Quelqu'un a enregistré mon annonce.
  listingInterest,

  /// J'ai reçu un avis.
  ratingReceived,

  /// Mon annonce est marquée comme vendue.
  listingSold,

  /// Mon annonce a été mise à jour.
  listingUpdated,

  /// Nouveau message.
  message,

  /// Message de l'équipe AfriMarket (texte du serveur), ou type inconnu.
  system,
}

/// Disponibilité de l'annonce d'une notification.
enum NotificationListingStatus { available, reserved, sold, unavailable }

/// Annonce liée à une notification.
@immutable
final class NotificationListing {
  const new({
    required this.id,
    required this.title,
    required this.status,
    this.photoUrl,
  });

  final String id;
  final String title;
  final NotificationListingStatus status;
  final String? photoUrl;
}

/// Une notification de l'onglet Notifications.
@immutable
final class AppNotification {
  const new({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.title = '',
    this.message = '',
    this.read = false,
    this.listing,
  });

  final String id;
  final NotificationKind kind;
  final DateTime createdAt;

  /// Texte du serveur (en français) : affiché seulement pour
  /// [NotificationKind.system] ; les autres types sont traduits par l'app.
  final String title;
  final String message;

  /// Touchée : plus surlignée.
  final bool read;

  /// `null` : pas d'annonce, ou annonce supprimée.
  final NotificationListing? listing;

  AppNotification markedRead() => read
      ? this
      : AppNotification(
          id: id,
          kind: kind,
          createdAt: createdAt,
          title: title,
          message: message,
          read: true,
          listing: listing,
        );
}
