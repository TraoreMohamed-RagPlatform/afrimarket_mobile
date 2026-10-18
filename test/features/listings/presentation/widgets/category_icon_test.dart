import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/category_icon.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/listing_card_status_of.dart';
import 'package:afrimarket_mobile/shared/widgets/listing_card_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('icônes des 7 catégories du serveur', () {
    expect(categoryIcon('house'), AppIcons.house);
    expect(categoryIcon('shoppingBag'), AppIcons.shoppingBag);
    expect(categoryIcon('wrench'), AppIcons.wrench);
    expect(categoryIcon('briefcase'), AppIcons.briefcase);
    expect(categoryIcon('car'), AppIcons.car);
    expect(categoryIcon('magnifyingGlass'), AppIcons.magnifyingGlass);
    expect(categoryIcon('megaphone'), AppIcons.megaphone);
  });

  test('nom inconnu ou absent : icône générique', () {
    expect(categoryIcon(null), AppIcons.squaresFour);
    expect(categoryIcon('rocket'), AppIcons.squaresFour);
  });

  test('statut de carte : « Vendu » l’emporte sur « Réservé »', () {
    expect(
      listingCardStatusOf(isSold: false, isReserved: false),
      ListingCardStatus.available,
    );
    expect(
      listingCardStatusOf(isSold: false, isReserved: true),
      ListingCardStatus.reserved,
    );
    expect(
      listingCardStatusOf(isSold: true, isReserved: true),
      ListingCardStatus.sold,
    );
  });
}
