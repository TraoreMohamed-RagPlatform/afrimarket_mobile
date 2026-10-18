import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/feed_filters.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_locations.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/listing_detail_controller.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ville proposée par défaut dans les filtres (lancement à Casablanca).
const String defaultFeedCity = 'casablanca';

/// Ouvre la feuille « Filtres » (quartier, tri, prix) et applique le
/// choix au fil. La catégorie choisie est conservée.
///
/// Ouverte sur le navigateur principal : au-dessus de la barre du bas, et
/// le bouton Retour d'Android la ferme.
Future<void> showFeedFilterSheet(BuildContext context, WidgetRef ref) async {
  final current = ref.read(feedControllerProvider).filters;
  final choice = await showModalBottomSheet<FeedFilters>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => FeedFilterSheet(initial: current),
  );
  if (choice == null || !context.mounted) return;
  await ref.read(feedControllerProvider.notifier).applyFilters(choice);
}

/// Libellé d'un tri.
String feedSortLabel(FeedSort sort, AppLocalizations l10n) {
  return switch (sort) {
    FeedSort.newest => l10n.feedSortNewest,
    FeedSort.priceAsc => l10n.feedSortPriceAsc,
    FeedSort.priceDesc => l10n.feedSortPriceDesc,
  };
}

/// Libellé de la pastille « Filtres » du fil :
/// - aucun filtre : « Filtres » ;
/// - seulement un quartier : son nom (« Maârif ») ;
/// - sinon : « Filtres · 2 ».
String feedFilterChipLabel(
  FeedFilters filters,
  ListingLocations locations,
  AppLocalizations l10n,
) {
  if (!filters.isActive) return l10n.feedFiltersTitle;
  final district = filters.district;
  if (district != null && filters.activeCount == 1) {
    final name = locations
        .districtsOf(filters.city ?? defaultFeedCity)
        .where((item) => item.slug == district);
    if (name.isNotEmpty) return name.first.name;
  }
  return l10n.feedFiltersCount(filters.activeCount);
}

/// Contenu de la feuille « Filtres ».
///
/// Rien n'est appliqué avant « Afficher les annonces » : fermer la
/// feuille garde les filtres précédents.
class FeedFilterSheet extends ConsumerStatefulWidget {
  const new({required this.initial, super.key});

  final FeedFilters initial;

  /// Prix saisi : 9 chiffres au plus (999 999 999 DH).
  static const int maxPriceDigits = 9;

  @override
  ConsumerState<FeedFilterSheet> createState() => _FeedFilterSheetState();
}

class _FeedFilterSheetState extends ConsumerState<FeedFilterSheet> {
  late String? _district = widget.initial.district;
  late FeedSort _sort = widget.initial.sort;
  late final _minPrice = TextEditingController(
    text: _priceText(widget.initial.minPrice),
  );
  late final _maxPrice = TextEditingController(
    text: _priceText(widget.initial.maxPrice),
  );

  static String _priceText(num? price) => price?.toInt().toString() ?? '';

  static int? _parse(String text) => int.tryParse(text.trim());

  @override
  void dispose() {
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  FeedFilters get _filters => FeedFilters(
    city: _district == null ? null : defaultFeedCity,
    district: _district,
    sort: _sort,
    minPrice: _parse(_minPrice.text),
    maxPrice: _parse(_maxPrice.text),
  );

  void _reset() {
    setState(() {
      _district = null;
      _sort = FeedSort.newest;
      _minPrice.clear();
      _maxPrice.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final locations =
        ref.watch(listingLocationsProvider).value ?? ListingLocations.empty;
    final cityName = locations.cityName(defaultFeedCity);
    final districts = locations.districtsOf(defaultFeedCity);
    final filters = _filters;
    final priceError = filters.hasValidPrices
        ? null
        : l10n.feedFiltersPriceError;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.page,
                    0,
                    AppSpacing.page,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.feedFiltersTitle,
                          style: styles.titleLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(l10n.feedFiltersDistrict),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _Choice(
                            label: cityName == null
                                ? l10n.feedFiltersAllDistricts
                                : l10n.feedFiltersAllCity(cityName),
                            selected: _district == null,
                            onSelected: () => setState(() => _district = null),
                          ),
                          for (final district in districts)
                            _Choice(
                              label: district.name,
                              selected: _district == district.slug,
                              onSelected: () =>
                                  setState(() => _district = district.slug),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(l10n.feedFiltersSort),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final sort in FeedSort.values)
                            _Choice(
                              label: feedSortLabel(sort, l10n),
                              selected: _sort == sort,
                              onSelected: () => setState(() => _sort = sort),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(l10n.feedFiltersPrice),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _PriceField(
                              key: const Key('feed-filter-min-price'),
                              controller: _minPrice,
                              label: l10n.feedFiltersPriceMin,
                              onChanged: () => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _PriceField(
                              key: const Key('feed-filter-max-price'),
                              controller: _maxPrice,
                              label: l10n.feedFiltersPriceMax,
                              errorText: priceError,
                              onChanged: () => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.page,
                  AppSpacing.sm,
                  AppSpacing.page,
                  AppSpacing.page,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _reset,
                        child: Text(l10n.feedFiltersReset),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: priceError == null
                            ? () => Navigator.of(context).pop(filters)
                            : null,
                        child: Text(l10n.feedFiltersApply),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const new(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(label, style: context.textStyles.titleSmall),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
    );
  }
}

/// Prix en dirhams : chiffres seulement.
class _PriceField extends StatelessWidget {
  const new({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(FeedFilterSheet.maxPriceDigits),
      ],
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        suffixText: context.l10n.feedFiltersCurrency,
        errorText: errorText,
        errorMaxLines: 2,
      ),
    );
  }
}
