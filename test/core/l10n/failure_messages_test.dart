import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _allFailures = <Failure>[
  NetworkFailure(),
  TimeoutFailure(),
  UnauthorizedFailure(),
  ForbiddenFailure(),
  NotFoundFailure(),
  ValidationFailure(),
  RateLimitFailure(),
  AccountLockedFailure(),
  ServerFailure(statusCode: 503),
  StorageFailure(),
  UnexpectedFailure(),
];

void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));
  final ar = lookupAppLocalizations(const Locale('ar'));

  group('FailureMessage', () {
    test('chaque Failure a un message dans les 3 langues', () {
      for (final l10n in [fr, en, ar]) {
        for (final failure in _allFailures) {
          expect(failure.message(l10n), isNotEmpty);
        }
      }
    });

    test('le délai est affiché en minutes', () {
      const failure = RateLimitFailure(retryAfter: Duration(minutes: 15));

      expect(failure.message(fr), contains('15 minutes'));
      expect(failure.message(en), contains('15 minutes'));
    });

    test('le singulier est respecté pour 1 minute', () {
      const failure = RateLimitFailure(retryAfter: Duration(seconds: 30));

      expect(failure.message(fr), contains('1 minute.'));
    });

    test('les secondes sont arrondies à la minute supérieure', () {
      const failure = AccountLockedFailure(retryAfter: Duration(seconds: 61));

      expect(failure.message(fr), contains('2 minutes'));
    });

    test('l’arabe utilise la bonne forme de pluriel', () {
      const two = RateLimitFailure(retryAfter: Duration(minutes: 2));
      const three = RateLimitFailure(retryAfter: Duration(minutes: 3));

      expect(two.message(ar), contains('دقيقتين'));
      expect(three.message(ar), contains('دقائق'));
    });

    test('sans délai, un message générique est affiché', () {
      expect(const RateLimitFailure().message(fr), fr.errorRateLimit);
      expect(const AccountLockedFailure().message(fr), fr.errorAccountLocked);
    });

    test('aucun détail technique n’est affiché', () {
      final text = const ServerFailure(statusCode: 503).message(fr);

      expect(text, isNot(contains('503')));
    });
  });
}
