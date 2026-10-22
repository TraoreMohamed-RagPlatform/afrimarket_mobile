import 'package:meta/meta.dart';

/// Une page d'éléments, et de quoi demander la suivante.
@immutable
final class CursorPage<T> {
  const new({required this.items, this.nextCursor});

  final List<T> items;

  /// À renvoyer pour la page suivante ; `null` : c'était la dernière.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
