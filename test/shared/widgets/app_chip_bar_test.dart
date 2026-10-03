import 'package:afrimarket_mobile/shared/widgets/app_chip_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

List<AppChipItem> _items({void Function(String)? onTap}) => [
  for (final (label, selected) in [
    ('Vendre', false),
    ('Acheter', true),
    ('Catégorie', false),
    ('Gratuit', false),
    ('Près de moi', false),
  ])
    AppChipItem(
      label: label,
      selected: selected,
      hasDropdown: label == 'Catégorie',
      onTap: () => onTap?.call(label),
    ),
];

Widget _bar({void Function(String)? onTap}) => SizedBox(
  width: 320,
  child: AppChipBar(
    items: _items(onTap: onTap),
    trailing: IconButton(
      tooltip: 'Localisation',
      icon: const Icon(Icons.place_outlined),
      onPressed: () {},
    ),
  ),
);

void main() {
  testWidgets('affiche les pastilles et l’action fixe', (tester) async {
    await tester.pumpWidget(localizedApp(Center(child: _bar())));

    expect(find.byType(ChoiceChip), findsNWidgets(5));
    expect(find.byTooltip('Localisation'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });

  testWidgets('toucher une pastille appelle son action', (tester) async {
    String? tapped;
    await tester.pumpWidget(
      localizedApp(Center(child: _bar(onTap: (label) => tapped = label))),
    );

    await tester.tap(find.text('Vendre'));

    expect(tapped, 'Vendre');
  });

  testWidgets('la pastille active est annoncée « sélectionnée »', (
    tester,
  ) async {
    await tester.pumpWidget(localizedApp(Center(child: _bar())));

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Acheter'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('zones tactiles d’au moins 48 px', (tester) async {
    await tester.pumpWidget(localizedApp(Center(child: _bar())));

    final size = tester.getSize(find.byType(ChoiceChip).first);
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('arabe, mode sombre et texte doublé : défile sans déborder', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: localizedApp(
          Center(child: _bar()),
          locale: const Locale('ar'),
          themeMode: ThemeMode.dark,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
