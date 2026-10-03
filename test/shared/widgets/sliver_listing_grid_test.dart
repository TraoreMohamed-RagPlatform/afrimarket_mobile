import 'package:afrimarket_mobile/shared/widgets/listing_card.dart';
import 'package:afrimarket_mobile/shared/widgets/sliver_listing_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

Widget _grid() {
  return CustomScrollView(
    slivers: [
      SliverListingGrid(
        itemCount: 4,
        itemBuilder: (context, index) => ListingCard(
          title: 'Annonce $index',
          price: 100 * (index + 1),
          onTap: () {},
        ),
      ),
    ],
  );
}

void main() {
  testWidgets('affiche les annonces sur 2 colonnes', (tester) async {
    await tester.pumpWidget(localizedApp(_grid()));

    expect(find.byType(ListingCard), findsNWidgets(4));

    final first = tester.getTopLeft(find.byType(ListingCard).at(0));
    final second = tester.getTopLeft(find.byType(ListingCard).at(1));
    expect(first.dy, second.dy);
    expect(second.dx, greaterThan(first.dx));
  });

  testWidgets('aucun débordement avec un texte doublé', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: localizedApp(_grid()),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
