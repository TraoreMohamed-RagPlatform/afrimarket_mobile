import 'package:meta/meta.dart';

/// Un message d'une discussion (texte seul).
@immutable
final class ChatMessage {
  const new({
    required this.id,
    required this.text,
    required this.isMine,
    required this.sentAt,
    this.readAt,
  });

  final String id;
  final String text;

  /// Envoyé par la personne connectée.
  final bool isMine;

  final DateTime sentAt;

  /// Lu par le destinataire (« Vu »), si c'est le cas.
  final DateTime? readAt;
}
