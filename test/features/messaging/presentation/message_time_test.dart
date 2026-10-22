import 'package:afrimarket_mobile/features/messaging/presentation/message_time.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../helpers/l10n.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  final now = DateTime(2026, 10, 22, 15, 30);

  group('Liste des discussions', () {
    test('aujourd’hui : l’heure', () {
      expect(
        MessageTime.inList(DateTime(2026, 10, 22, 9, 5), fr, now: now),
        '09:05',
      );
    });

    test('hier', () {
      expect(
        MessageTime.inList(DateTime(2026, 10, 21, 23), fr, now: now),
        fr.messagesYesterday,
      );
    });

    test('cette semaine : le jour', () {
      expect(MessageTime.inList(DateTime(2026, 10, 19), fr, now: now), 'lun.');
    });

    test('cette année : jour et mois ; avant : avec l’année', () {
      expect(MessageTime.inList(DateTime(2026, 3, 2), fr, now: now), '2 mars');
      expect(
        MessageTime.inList(DateTime(2025, 12, 31), fr, now: now),
        contains('2025'),
      );
    });
  });

  group('Séparateur de jour', () {
    test('aujourd’hui, hier, date', () {
      expect(
        MessageTime.day(DateTime(2026, 10, 22, 8), fr, now: now),
        fr.chatToday,
      );
      expect(
        MessageTime.day(DateTime(2026, 10, 21, 8), fr, now: now),
        fr.messagesYesterday,
      );
      expect(
        MessageTime.day(DateTime(2026, 10, 12), fr, now: now),
        'lundi 12 octobre',
      );
      expect(
        MessageTime.day(DateTime(2024, 1, 5), fr, now: now),
        '5 janvier 2024',
      );
    });

    test('heure et même jour', () {
      expect(MessageTime.time(DateTime(2026, 10, 22, 7, 4), fr), '07:04');
      expect(
        MessageTime.sameDay(
          DateTime(2026, 10, 22, 1),
          DateTime(2026, 10, 22, 23),
        ),
        isTrue,
      );
    });
  });
}
