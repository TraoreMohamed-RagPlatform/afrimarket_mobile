import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/core/theme/app_theme.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/snackbar_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_badge.dart';
import 'package:afrimarket_mobile/shared/widgets/app_bottom_nav_bar.dart';
import 'package:afrimarket_mobile/shared/widgets/app_chip_bar.dart';
import 'package:afrimarket_mobile/shared/widgets/app_empty_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_error_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_load_more_indicator.dart';
import 'package:afrimarket_mobile/shared/widgets/app_rating_summary.dart';
import 'package:afrimarket_mobile/shared/widgets/app_round_action.dart';
import 'package:afrimarket_mobile/shared/widgets/app_search_launcher.dart';
import 'package:afrimarket_mobile/shared/widgets/app_section_header.dart';
import 'package:afrimarket_mobile/shared/widgets/app_skeleton.dart';
import 'package:afrimarket_mobile/shared/widgets/app_text_field.dart';
import 'package:afrimarket_mobile/shared/widgets/listing_card.dart';
import 'package:afrimarket_mobile/shared/widgets/listing_card_status.dart';
import 'package:afrimarket_mobile/shared/widgets/price_text.dart';
import 'package:afrimarket_mobile/shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';

/// Galerie du design system (outil de développement).
///
/// Affiche toutes les briques partagées, chacune avec son nom et son
/// usage : documentation vivante, toujours à jour puisque c'est le vrai
/// code qui s'affiche. Commandes : clair / sombre, FR / EN / AR, texte ×2.
///
/// Les textes de documentation ne sont pas traduits : outil réservé aux
/// développeurs, retiré du binaire de production (devToolsVisible).
///
/// Tout nouveau widget partagé DOIT être ajouté ici : il est alors
/// contrôlé automatiquement par le test d'accessibilité de la galerie.
class GalleryPage extends StatefulWidget {
  const new({
    this.initialDark = false,
    this.initialLocale = const Locale('fr'),
    this.initialLargeText = false,
    super.key,
  });

  final bool initialDark;
  final Locale initialLocale;
  final bool initialLargeText;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late bool _dark = widget.initialDark;
  late Locale _locale = widget.initialLocale;
  late bool _largeText = widget.initialLargeText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.devGalleryButton)),
      body: Column(
        children: [
          AppChipBar(
            items: [
              AppChipItem(
                label: 'Clair',
                selected: !_dark,
                onTap: () => setState(() => _dark = false),
              ),
              AppChipItem(
                label: 'Sombre',
                selected: _dark,
                onTap: () => setState(() => _dark = true),
              ),
              for (final code in ['fr', 'en', 'ar'])
                AppChipItem(
                  label: code.toUpperCase(),
                  selected: _locale.languageCode == code,
                  onTap: () => setState(() => _locale = Locale(code)),
                ),
              AppChipItem(
                label: 'Texte ×2',
                selected: _largeText,
                onTap: () => setState(() => _largeText = !_largeText),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: Theme(
              data: _dark ? AppTheme.dark() : AppTheme.light(),
              child: Localizations.override(
                context: context,
                locale: _locale,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: _largeText
                        ? const TextScaler.linear(2)
                        : MediaQuery.textScalerOf(context),
                  ),
                  child: Builder(
                    builder: (context) => Material(
                      color: context.colors.background,
                      child: const GalleryCatalog(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le catalogue des briques, dans le thème et la langue choisis.
class GalleryCatalog extends StatelessWidget {
  const new({super.key});

  static const double _cardWidth = 160;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textStyles;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _Section(
          name: 'AppColors',
          usage: 'Couleurs sémantiques ; contraste WCAG AA testé.',
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final (name, color) in [
                ('brand', colors.brand),
                ('onBrand', colors.onBrand),
                ('brandSoft', colors.brandSoft),
                ('onBrandSoft', colors.onBrandSoft),
                ('accent', colors.accent),
                ('onAccent', colors.onAccent),
                ('background', colors.background),
                ('surface', colors.surface),
                ('surfaceMuted', colors.surfaceMuted),
                ('textPrimary', colors.textPrimary),
                ('textSecondary', colors.textSecondary),
                ('border', colors.border),
                ('success', colors.success),
                ('error', colors.error),
              ])
                _Swatch(name: name, color: color),
            ],
          ),
        ),
        _Section(
          name: 'AppTypography',
          usage: 'Police du système ; correspondance dans app_typography.dart.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (name, style) in [
                ('displaySmall', text.displaySmall),
                ('headlineSmall', text.headlineSmall),
                ('titleLarge', text.titleLarge),
                ('titleMedium', text.titleMedium),
                ('bodyLarge', text.bodyLarge),
                ('bodyMedium', text.bodyMedium),
                ('bodySmall', text.bodySmall),
                ('labelLarge', text.labelLarge),
                ('labelSmall', text.labelSmall),
              ])
                Text('$name · AfriMarket', style: style),
            ],
          ),
        ),
        const _Section(
          name: 'AppBadge',
          usage: 'Pastilles : Récent, Vérifié, Réservé.',
          child: Wrap(
            spacing: AppSpacing.sm,
            children: [
              AppBadge(AppBadgeType.recent),
              AppBadge(AppBadgeType.verified),
              AppBadge(AppBadgeType.reserved),
            ],
          ),
        ),
        const _Section(
          name: 'PriceText',
          usage: 'Prix local (DH / MAD / د.م.), ancien prix barré, Gratuit.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PriceText(price: 1400),
              PriceText(price: 800, oldPrice: 1200),
              PriceText(price: 0),
            ],
          ),
        ),
        _Section(
          name: 'ListingCard',
          usage: 'Grilles d’annonces. Badges, action et statut configurables.',
          child: Wrap(
            spacing: AppSpacing.gridGap,
            runSpacing: AppSpacing.md,
            children: [
              SizedBox(
                width: _cardWidth,
                child: ListingCard(
                  title: 'Garçonnière Maârif',
                  price: 1400,
                  badges: const [AppBadgeType.recent],
                  onTap: () {},
                ),
              ),
              SizedBox(
                width: _cardWidth,
                child: ListingCard(
                  title: 'Trottinette électrique',
                  price: 800,
                  oldPrice: 1200,
                  onTap: () {},
                  action: IconButton(
                    tooltip: 'Enregistrer',
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {},
                  ),
                ),
              ),
              SizedBox(
                width: _cardWidth,
                child: ListingCard(
                  title: 'Scooter Yamaha',
                  price: 3000,
                  status: ListingCardStatus.reserved,
                  onTap: () {},
                ),
              ),
              SizedBox(
                width: _cardWidth,
                child: ListingCard(
                  title: 'Lit 1 place',
                  price: 700,
                  status: ListingCardStatus.sold,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
        _Section(
          name: 'AppSearchLauncher · AppChipBar',
          usage: 'En-tête des pages de navigation (fil, recherche).',
          child: Column(
            children: [
              AppSearchLauncher(hint: l10n.searchHint, onTap: () {}),
              const SizedBox(height: AppSpacing.sm),
              AppChipBar(
                items: [
                  AppChipItem(label: 'Vendre', onTap: () {}),
                  AppChipItem(label: 'Acheter', selected: true, onTap: () {}),
                  AppChipItem(
                    label: 'Catégorie',
                    hasDropdown: true,
                    onTap: () {},
                  ),
                ],
                trailing: IconButton(
                  tooltip: 'Localisation',
                  icon: const Icon(Icons.place_outlined),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        _Section(
          name: 'AppRoundAction',
          usage: 'Actions rondes ; état actif annoncé comme interrupteur.',
          child: AppRoundActionRow(
            actions: [
              AppRoundAction(
                icon: Icons.chat_bubble_outline,
                label: l10n.navMessages,
                onTap: () {},
              ),
              AppRoundAction(
                icon: Icons.share_outlined,
                label: 'Partager',
                onTap: () {},
              ),
              AppRoundAction(
                icon: Icons.bookmark_border,
                activeIcon: Icons.bookmark,
                label: 'Enregistrer',
                activeLabel: 'Enregistré',
                active: true,
                onTap: () {},
              ),
            ],
          ),
        ),
        _Section(
          name: 'AppSectionHeader · UserAvatar · AppRatingSummary',
          usage: 'Détail et profil ; « Nouveau vendeur » sans avis.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: 'Description',
                actionLabel: l10n.seeMore,
                onAction: () {},
              ),
              AppSectionHeader(title: 'Vendeur', onTap: () {}),
              const Row(
                children: [
                  UserAvatar(name: 'Fatou Hmimid', verified: true),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: AppRatingSummary(average: 4.8, count: 12)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Row(
                children: [
                  UserAvatar(name: 'Moussa Traoré', size: AvatarSize.small),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: AppRatingSummary(average: 0, count: 0)),
                ],
              ),
            ],
          ),
        ),
        const _Section(
          name: 'AppTextField',
          usage: 'Libellé visible et annoncé ; mot de passe protégé (MASVS).',
          child: Column(
            children: [
              AppTextField(
                label: 'Titre de l’annonce',
                hint: 'Ex. Lit 1 place',
              ),
              SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Mot de passe', isPassword: true),
            ],
          ),
        ),
        _Section(
          name: 'AppEmptyState · AppErrorState',
          usage: 'Écran vide qui invite à agir ; erreur traduite + Réessayer.',
          child: Column(
            children: [
              AppEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Publiez votre première annonce',
                message: 'Vendez ce dont vous n’avez plus besoin.',
                actionLabel: l10n.navPublish,
                onAction: () {},
              ),
              AppErrorState(failure: const TimeoutFailure(), onRetry: () {}),
              AppErrorState(
                failure: const TimeoutFailure(),
                compact: true,
                onRetry: () {},
              ),
            ],
          ),
        ),
        const _Section(
          name: 'ListingGridSkeleton · AppLoadMoreIndicator',
          usage:
              'Premier chargement (squelettes) ; pages suivantes (indicateur).',
          child: Column(
            children: [
              SizedBox(height: 420, child: ListingGridSkeleton(itemCount: 4)),
              AppLoadMoreIndicator(),
            ],
          ),
        ),
        _Section(
          name: 'showUndoSnackBar',
          usage: 'Confirmation avec « Annuler ».',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Builder(
              builder: (context) => OutlinedButton(
                onPressed: () => context.showUndoSnackBar(
                  'Annonce enregistrée',
                  onUndo: () {},
                ),
                child: const Text('Afficher le message'),
              ),
            ),
          ),
        ),
        _Section(
          name: 'AppBottomNavBar',
          usage: 'Barre du bas : onglets, action centrale, compteurs.',
          child: AppBottomNavBar(
            currentIndex: 0,
            onSelect: (_) {},
            items: [
              AppNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: l10n.navHome,
              ),
              AppNavItem(
                icon: Icons.star_border,
                selectedIcon: Icons.star,
                label: l10n.navFavorites,
              ),
              AppNavItem(
                icon: Icons.chat_bubble_outline,
                selectedIcon: Icons.chat_bubble,
                label: l10n.navMessages,
                badgeCount: 3,
              ),
              AppNavItem(
                icon: Icons.notifications_none,
                selectedIcon: Icons.notifications,
                label: l10n.navNotifications,
                badgeCount: 250,
              ),
            ],
            centerAction: AppNavAction(
              icon: Icons.add,
              label: l10n.navPublish,
              onTap: () {},
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const new({required this.name, required this.usage, required this.child});

  final String name;
  final String usage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name, style: context.textStyles.titleMedium),
          Text(usage, style: context.textStyles.bodySmall),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const new({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.sm,
              border: Border.all(color: context.colors.border),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(name, style: context.textStyles.labelSmall),
        ],
      ),
    );
  }
}
