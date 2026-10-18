import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/report_reason.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/get_similar_listings_usecase.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/report_listing_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_listings_repository.dart';

void main() {
  test('similaires : l’annonce elle-même n’est jamais proposée', () async {
    final repository = FakeListingsRepository()
      ..similar = Ok([sampleListing(1), sampleListing(2)]);

    final result = await GetSimilarListingsUseCase(repository)('l1');

    expect((result as Ok<List<ListingSummary>>).value.map((l) => l.id), ['l2']);
  });

  group('Signalement', () {
    test('détail nettoyé ; vide : non envoyé', () async {
      final repository = FakeListingsRepository();
      final report = ReportListingUseCase(repository);

      await report(
        listingId: 'l1',
        reason: ReportReason.scam,
        details: '  Demande un acompte  ',
      );
      await report(listingId: 'l1', reason: ReportReason.spam, details: '  ');

      expect(repository.reports, [
        ('l1', ReportReason.scam, 'Demande un acompte'),
        ('l1', ReportReason.spam, null),
      ]);
    });

    test('détail trop long : coupé sans casser un caractère', () async {
      final repository = FakeListingsRepository();
      final long = '😀' * (ReportReason.maxDetailsLength + 10);

      await ReportListingUseCase(repository)(
        listingId: 'l1',
        reason: ReportReason.other,
        details: long,
      );

      final sent = repository.reports.single.$3!;
      expect(sent.runes.length, ReportReason.maxDetailsLength);
      expect(sent.runes.every((rune) => rune == '😀'.runes.first), isTrue);
    });

    test('valeurs envoyées au serveur', () {
      expect(ReportReason.values.map((r) => r.apiValue), [
        'SCAM',
        'PROHIBITED_ITEM',
        'OFFENSIVE',
        'MISLEADING',
        'SPAM',
        'ALREADY_SOLD',
        'OTHER',
      ]);
    });
  });
}
