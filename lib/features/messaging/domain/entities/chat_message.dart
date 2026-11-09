import 'package:meta/meta.dart';

/// Photo d'un message (une par message, comme Messenger).
///
/// L'image elle-même est privée : elle se lit avec l'identifiant du
/// message, connexion requise. Les dimensions réservent sa place avant
/// le chargement.
@immutable
final class MessagePhoto {
  const new({this.width, this.height});

  final int? width;
  final int? height;

  /// Rapport largeur / hauteur, borné (photo très haute ou très large) ;
  /// carré si les dimensions sont inconnues.
  double get aspectRatio {
    final w = width;
    final h = height;
    if (w == null || h == null || w <= 0 || h <= 0) return 1;
    return (w / h).clamp(minAspectRatio, maxAspectRatio);
  }

  static const double minAspectRatio = 0.5;
  static const double maxAspectRatio = 2;
}

/// Un message d'une discussion : un texte ou une photo.
@immutable
final class ChatMessage {
  const new({
    required this.id,
    required this.text,
    required this.isMine,
    required this.sentAt,
    this.photo,
    this.readAt,
  });

  final String id;

  /// Texte ; vide pour une photo.
  final String text;

  /// Photo, si le message en est une.
  final MessagePhoto? photo;

  /// Envoyé par la personne connectée.
  final bool isMine;

  final DateTime sentAt;

  /// Lu par le destinataire (« Vu »), si c'est le cas.
  final DateTime? readAt;
}
