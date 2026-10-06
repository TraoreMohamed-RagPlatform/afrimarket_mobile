import 'package:afrimarket_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

String? _minThree(String? value) =>
    (value ?? '').length < 3 ? 'Trop court' : null;

Widget _form({bool isPassword = false}) => Center(
  child: SizedBox(
    width: 320,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          label: isPassword ? 'Mot de passe' : 'Titre',
          validator: _minThree,
          isPassword: isPassword,
        ),
        const AppTextField(label: 'Autre champ'),
      ],
    ),
  ),
);

void main() {
  group('Validation au bon moment', () {
    testWidgets('pas d’erreur pendant la première saisie', (tester) async {
      await tester.pumpWidget(localizedApp(_form()));

      await tester.enterText(find.byType(TextFormField).first, 'a');
      await tester.pump();

      expect(find.text('Trop court'), findsNothing);
    });

    testWidgets('erreur en quittant le champ, puis disparition', (
      tester,
    ) async {
      await tester.pumpWidget(localizedApp(_form()));
      final field = find.byType(TextFormField).first;

      await tester.enterText(field, 'ab');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(find.text('Trop court'), findsOneWidget);

      await tester.enterText(field, 'abcd');
      await tester.pump();
      expect(find.text('Trop court'), findsNothing);
    });
  });

  group('Mot de passe', () {
    testWidgets('masqué par défaut, puis affiché avec le bouton', (
      tester,
    ) async {
      await tester.pumpWidget(localizedApp(_form(isPassword: true)));

      EditableText editable() =>
          tester.widget<EditableText>(find.byType(EditableText).first);
      expect(editable().obscureText, isTrue);

      await tester.tap(find.byTooltip(fr.passwordShow));
      await tester.pump();

      expect(editable().obscureText, isFalse);
      expect(find.byTooltip(fr.passwordHide), findsOneWidget);
    });

    testWidgets('clavier : ni suggestions, ni apprentissage (MASVS)', (
      tester,
    ) async {
      await tester.pumpWidget(localizedApp(_form(isPassword: true)));

      final editable = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(editable.enableSuggestions, isFalse);
      expect(editable.autocorrect, isFalse);
      expect(editable.enableIMEPersonalizedLearning, isFalse);
    });
  });

  testWidgets('libellé annoncé aux lecteurs d’écran', (tester) async {
    await tester.pumpWidget(localizedApp(_form()));

    expect(find.bySemanticsLabel(RegExp('Titre')), findsOneWidget);
  });

  testWidgets('arabe, mode sombre et texte doublé', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: localizedApp(
          _form(isPassword: true),
          locale: const Locale('ar'),
          themeMode: ThemeMode.dark,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
