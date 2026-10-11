import 'package:afrimarket_mobile/features/auth/domain/validation/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email', () {
    test('valide (espaces ignorés)', () {
      expect(AuthValidators.email('  awa@example.com '), isNull);
    });

    test('vide ou absent : obligatoire', () {
      expect(AuthValidators.email(null), AuthFieldIssue.empty);
      expect(AuthValidators.email('   '), AuthFieldIssue.empty);
    });

    test('mal formé ou trop long : invalide', () {
      for (final value in [
        'awa',
        'awa@',
        '@example.com',
        'awa@example',
        'a wa@example.com',
        '${'a' * 250}@example.com',
      ]) {
        expect(
          AuthValidators.email(value),
          AuthFieldIssue.invalidEmail,
          reason: value,
        );
      }
    });
  });

  group('currentPassword (connexion)', () {
    test('obligatoire, sans règle de longueur', () {
      expect(AuthValidators.currentPassword(null), AuthFieldIssue.empty);
      expect(AuthValidators.currentPassword(''), AuthFieldIssue.empty);
      expect(AuthValidators.currentPassword('court'), isNull);
    });
  });

  group('newPassword', () {
    test('8 caractères minimum', () {
      expect(AuthValidators.newPassword(''), AuthFieldIssue.empty);
      expect(
        AuthValidators.newPassword('Abc-123'),
        AuthFieldIssue.passwordTooShort,
      );
      expect(AuthValidators.newPassword('Abc-1234'), isNull);
    });

    test('les espaces comptent (jamais retirés)', () {
      expect(AuthValidators.newPassword('        '), isNull);
    });

    test('72 octets maximum (limite bcrypt)', () {
      expect(AuthValidators.newPassword('a' * 72), isNull);
      expect(
        AuthValidators.newPassword('a' * 73),
        AuthFieldIssue.passwordTooLong,
      );
      // « é » = 2 octets : 37 × 2 = 74 octets.
      expect(
        AuthValidators.newPassword('é' * 37),
        AuthFieldIssue.passwordTooLong,
      );
    });
  });

  group('confirmation', () {
    test('identique au mot de passe', () {
      expect(AuthValidators.confirmation('Abc-1234', 'Abc-1234'), isNull);
      expect(
        AuthValidators.confirmation('Abc-1235', 'Abc-1234'),
        AuthFieldIssue.passwordMismatch,
      );
      expect(AuthValidators.confirmation('', 'Abc-1234'), AuthFieldIssue.empty);
    });
  });

  group('username', () {
    test('valide', () {
      expect(AuthValidators.username('awa.traore_2-b'), isNull);
    });

    test('longueur', () {
      expect(AuthValidators.username(' '), AuthFieldIssue.empty);
      expect(AuthValidators.username('aw'), AuthFieldIssue.usernameTooShort);
      expect(AuthValidators.username('a' * 31), AuthFieldIssue.usernameTooLong);
    });

    test('caractères interdits', () {
      for (final value in ['awa traore', 'awa<b>', 'àwa', 'awa@x']) {
        expect(
          AuthValidators.username(value),
          AuthFieldIssue.usernameInvalid,
          reason: value,
        );
      }
    });
  });

  group('fullName', () {
    test('obligatoire, 100 caractères maximum', () {
      expect(AuthValidators.fullName('Awa Traoré'), isNull);
      expect(AuthValidators.fullName('  '), AuthFieldIssue.empty);
      expect(AuthValidators.fullName('a' * 101), AuthFieldIssue.nameTooLong);
    });
  });

  group('resetCode', () {
    test('exactement 6 chiffres', () {
      expect(AuthValidators.resetCode(' 123456 '), isNull);
      expect(AuthValidators.resetCode(''), AuthFieldIssue.empty);
      for (final value in ['12345', '1234567', '12a456', '١٢٣٤٥٦']) {
        expect(
          AuthValidators.resetCode(value),
          AuthFieldIssue.codeInvalid,
          reason: value,
        );
      }
    });
  });
}
