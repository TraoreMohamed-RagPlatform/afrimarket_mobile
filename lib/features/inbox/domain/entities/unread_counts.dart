import 'package:meta/meta.dart';

/// Messages et notifications non lus (pastilles de la barre du bas).
@immutable
final class UnreadCounts {
  const new({this.messages = 0, this.notifications = 0});

  static const zero = UnreadCounts();

  final int messages;
  final int notifications;

  @override
  bool operator ==(Object other) =>
      other is UnreadCounts &&
      other.messages == messages &&
      other.notifications == notifications;

  @override
  int get hashCode => Object.hash(messages, notifications);
}
