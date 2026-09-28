import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reproduit l'usage réel : chaque Failure doit avoir un traitement.
/// Si un nouveau type est ajouté sans être traité ici, le code
/// ne compile plus : c'est la garantie apportée par `sealed`.
String describe(Failure failure) {
  return switch (failure) {
    NetworkFailure() => 'network',
    TimeoutFailure() => 'timeout',
    UnauthorizedFailure() => 'unauthorized',
    ForbiddenFailure() => 'forbidden',
    NotFoundFailure() => 'not_found',
    ValidationFailure() => 'validation',
    RateLimitFailure() => 'rate_limit',
    AccountLockedFailure() => 'account_locked',
    ServerFailure() => 'server',
    StorageFailure() => 'storage',
    UnexpectedFailure() => 'unexpected',
  };
}

void main() {
  group('Failure', () {
    test('chaque type est identifié par un switch exhaustif', () {
      expect(describe(const NetworkFailure()), 'network');
      expect(describe(const RateLimitFailure()), 'rate_limit');
      expect(describe(const UnexpectedFailure()), 'unexpected');
    });

    test('ValidationFailure conserve les erreurs par champ', () {
      const failure = ValidationFailure(
        fieldErrors: {
          'email': ['Email invalide'],
        },
      );

      expect(failure.fieldErrors['email'], ['Email invalide']);
    });

    test('ValidationFailure a une liste vide par défaut', () {
      const failure = ValidationFailure();

      expect(failure.fieldErrors, isEmpty);
    });

    test('RateLimitFailure et AccountLockedFailure portent un délai', () {
      const rateLimit = RateLimitFailure(retryAfter: Duration(minutes: 15));
      const locked = AccountLockedFailure(retryAfter: Duration(minutes: 15));

      expect(rateLimit.retryAfter, const Duration(minutes: 15));
      expect(locked.retryAfter, const Duration(minutes: 15));
    });

    test('ServerFailure conserve le code HTTP', () {
      const failure = ServerFailure(statusCode: 503);

      expect(failure.statusCode, 503);
    });
  });
}
