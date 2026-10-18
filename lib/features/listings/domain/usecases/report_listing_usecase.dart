import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/report_reason.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listings_repository.dart';

/// Cas d'usage : signaler une annonce à la modération.
class ReportListingUseCase {
  const new(this._repository);

  final ListingsRepository _repository;

  /// Le détail est nettoyé (espaces autour) ; vide, il n'est pas envoyé ;
  /// trop long, il est coupé à [ReportReason.maxDetailsLength].
  Future<Result<void>> call({
    required String listingId,
    required ReportReason reason,
    String? details,
  }) {
    final trimmed = details?.trim() ?? '';
    // Coupé par caractère (et non par unité UTF-16) : un emoji ou une
    // lettre composée n'est jamais coupé en deux.
    final limited = String.fromCharCodes(
      trimmed.runes.take(ReportReason.maxDetailsLength),
    );
    return _repository.reportListing(
      id: listingId,
      reason: reason,
      details: limited.isEmpty ? null : limited,
    );
  }
}
