import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/category_icon.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:afrimarket_mobile/shared/widgets/app_error_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la liste des catégories et applique le choix au fil.
///
/// Utilisée par la pastille « Catégories » et par le menu ☰.
Future<void> showCategorySheet(BuildContext context, WidgetRef ref) async {
  final current = ref.read(feedControllerProvider).category;
  final choice = await showModalBottomSheet<_CategoryChoice>(
    context: context,
    // Au-dessus de la barre du bas ; le bouton Retour la ferme.
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => CategorySheet(selectedId: current?.id),
  );
  if (choice == null || !context.mounted) return;
  await ref
      .read(feedControllerProvider.notifier)
      .selectCategory(choice.category);
}

/// Choix fait dans la feuille : une catégorie, ou `null` pour toutes.
@immutable
class _CategoryChoice {
  const new(this.category);

  final ListingCategory? category;
}

/// Liste des catégories : « Toutes les catégories », puis celles du
/// serveur. La catégorie active est cochée.
class CategorySheet extends ConsumerWidget {
  const new({required this.selectedId, super.key});

  /// Catégorie active ; `null` = toutes.
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(listingCategoriesProvider);

    final body = switch (categories) {
      AsyncData(value: Ok(:final value)) => _CategoryList(
        categories: value,
        selectedId: selectedId,
      ),
      AsyncData(value: Err(:final failure)) => _Error(failure: failure),
      AsyncError() => const _Error(failure: UnexpectedFailure()),
      _ => const _Loading(),
    };

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.categoriesTitle,
                  style: context.textStyles.titleLarge,
                ),
              ),
            ),
            Flexible(child: body),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const new({required this.categories, required this.selectedId});

  final List<ListingCategory> categories;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        _CategoryTile(
          label: context.l10n.categoriesAll,
          icon: AppIcons.squaresFour,
          selected: selectedId == null,
          onTap: () => Navigator.of(context).pop(const _CategoryChoice(null)),
        ),
        for (final category in categories)
          _CategoryTile(
            label: userText(category.name),
            icon: categoryIcon(category.icon),
            selected: category.id == selectedId,
            onTap: () => Navigator.of(context).pop(_CategoryChoice(category)),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const new({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      selected: selected,
      child: ListTile(
        leading: ExcludeSemantics(
          child: Icon(icon, color: selected ? colors.brand : null),
        ),
        title: Text(
          label,
          style: selected ? TextStyle(color: colors.brand) : null,
        ),
        trailing: selected ? Icon(AppIcons.check, color: colors.brand) : null,
        onTap: onTap,
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: AppSkeletonPulse(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 4; i++)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: AppSkeletonBox(height: AppSpacing.lg),
              ),
          ],
        ),
      ),
    );
  }
}

class _Error extends ConsumerWidget {
  const new({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: AppErrorState(
        failure: failure,
        compact: true,
        onRetry: () => ref.invalidate(listingCategoriesProvider),
      ),
    );
  }
}
