import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:meta/meta.dart';

/// Une page du fil d'annonces (défilement infini).
@immutable
final class ListingPage {
  const new({required this.items, required this.page, required this.hasMore});

  final List<ListingSummary> items;

  /// Numéro de cette page (à partir de 1).
  final int page;

  /// Vrai s'il reste des pages à charger après celle-ci.
  final bool hasMore;
}
