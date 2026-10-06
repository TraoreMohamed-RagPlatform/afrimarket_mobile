import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('userText', () {
    test('isole le texte (FSI ... PDI)', () {
      expect(
        userText('iPhone 11, très bon état!'),
        '\u2068iPhone 11, très bon état!\u2069',
      );
    });

    test('texte vide : isolation vide', () {
      expect(userText(''), '\u2068\u2069');
    });

    test('supprime un forçage de sens (CWE-451, Trojan Source)', () {
      final shown = userText('Vendeur officiel \u202Efdp.exe');

      expect(shown, isNot(contains('\u202E')));
      expect(shown, '\u2068Vendeur officiel fdp.exe\u2069');
    });

    test('un utilisateur ne peut pas refermer l’isolation lui-même', () {
      // Un PDI injecté ferait « sortir » la suite du texte de l'isolation.
      final shown = userText('titre\u2069 suite');

      expect('\u2069'.allMatches(shown).length, 1);
      expect(shown.endsWith('\u2069'), isTrue);
    });
  });

  group('stripBidiControls', () {
    test('supprime tous les caractères de contrôle bidirectionnels', () {
      const controls = '\u202A\u202B\u202C\u202D\u202E\u2066\u2067\u2068\u2069';

      expect(stripBidiControls('a${controls}b'), 'ab');
    });

    test('conserve le texte normal, latin et arabe', () {
      expect(
        stripBidiControls('Appartement شقة 2 000 DH'),
        'Appartement شقة 2 000 DH',
      );
    });
  });
}
