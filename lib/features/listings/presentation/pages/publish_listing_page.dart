import 'dart:async';
import 'dart:io';

import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_locations.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/publish_listing_usecase.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/listing_detail_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/publish_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/category_icon.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/listing_details_section.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/snackbar_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:afrimarket_mobile/shared/widgets/app_error_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Publication d'une annonce (plein écran, par-dessus les onglets).
///
/// Une seule page, comme Facebook Marketplace : photos en haut, puis
/// titre, prix, catégorie, quartier, état, description, négociable,
/// remise ; « Publier » en bas.
///
/// - réservée aux utilisateurs connectés (garde de navigation) ;
/// - les champs à compléter ne sont signalés qu'après un premier essai ;
/// - quitter avec une saisie en cours demande confirmation ;
/// - publiée : ouverture de l'annonce, le fil est actualisé.
class PublishListingPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PublishListingPage> createState() => _PublishListingPageState();
}

class _PublishListingPageState extends ConsumerState<PublishListingPage> {
  PublishController get _controller =>
      ref.read(publishControllerProvider.notifier);

  Future<void> _confirmLeave() async {
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.publishDiscardTitle),
        content: Text(l10n.publishDiscardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.publishDiscardCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.publishDiscardConfirm),
          ),
        ],
      ),
    );
    if ((leave ?? false) && mounted) context.pop();
  }

  void _onPublished(String id) {
    unawaited(HapticFeedback.mediumImpact());
    // La nouvelle annonce apparaît en tête du fil.
    unawaited(ref.read(feedControllerProvider.notifier).refresh());
    context.showAppSnackBar(context.l10n.publishSuccess);
    context.pushReplacement(AppRoutes.listing(id));
  }

  Future<void> _publish() async {
    FocusScope.of(context).unfocus();
    await _controller.publish();
    if (!mounted) return;
    final state = ref.read(publishControllerProvider);
    if (!state.isPublishing &&
        state.publishedId == null &&
        state.failure == null &&
        !state.draft.isReady) {
      context.showAppSnackBar(context.l10n.publishFixProblems);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(publishControllerProvider);

    ref.listen(publishControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure != null && previous?.failure == null) {
        context.showAppSnackBar(failure.message(context.l10n));
        _controller.failureShown();
      }
      final id = next.publishedId;
      if (id != null && previous?.publishedId == null) _onPublished(id);
    });

    final canLeave = state.draft.isEmpty && !state.isPublishing;

    return PopScope(
      canPop: canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || state.isPublishing) return;
        unawaited(_confirmLeave());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.publishCloseTooltip,
            icon: const Icon(AppIcons.x),
            onPressed: state.isPublishing
                ? null
                : () => canLeave ? context.pop() : unawaited(_confirmLeave()),
          ),
          title: Text(l10n.publishTitle),
        ),
        body: AbsorbPointer(
          absorbing: state.isPublishing,
          // Défilement simple (pas de liste paresseuse) : un champ qui sort
          // de l'écran garde sa saisie.
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PhotosSection(state: state),
                const SizedBox(height: AppSpacing.lg),
                _Fields(state: state),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _PublishBar(state: state, onPublish: _publish),
      ),
    );
  }
}

/// Message sous un champ pour un problème, s'il est signalé.
String? _problemText(
  PublishState state,
  DraftProblem problem,
  AppLocalizations l10n,
) {
  if (!state.visibleProblems.contains(problem)) return null;
  return switch (problem) {
    DraftProblem.noPhoto => l10n.publishErrorPhoto,
    DraftProblem.titleTooShort => l10n.publishErrorTitle,
    DraftProblem.noPrice => l10n.publishErrorPrice,
    DraftProblem.priceTooHigh => l10n.publishErrorPriceTooHigh,
    DraftProblem.noCategory => l10n.publishErrorCategory,
    DraftProblem.noDistrict => l10n.publishErrorDistrict,
    DraftProblem.noCondition => l10n.publishErrorCondition,
    DraftProblem.descriptionTooShort => l10n.publishErrorDescription,
  };
}

// ---------------------------------------------------------------- Photos

class _PhotosSection extends ConsumerWidget {
  const new({required this.state});

  final PublishState state;

  /// Côté d'une vignette.
  static const double tileSize = 96;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = ref.read(publishControllerProvider.notifier);
    final source = await showModalBottomSheet<_PhotoSource>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.camera),
              title: Text(l10n.publishTakePhoto),
              onTap: () => Navigator.of(context).pop(_PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(AppIcons.images),
              title: Text(l10n.publishPickGallery),
              onTap: () => Navigator.of(context).pop(_PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final outcome = switch (source) {
      _PhotoSource.camera => await controller.takePhoto(),
      _PhotoSource.gallery => await controller.addFromGallery(),
    };
    if (!context.mounted) return;
    switch (outcome) {
      case PhotoAddOutcome.ok:
        break;
      case PhotoAddOutcome.full:
        context.showAppSnackBar(context.l10n.publishPhotosFull);
      case PhotoAddOutcome.unavailable:
        context.showAppSnackBar(context.l10n.publishPhotosUnavailable);
    }
  }

  Future<void> _photoActions(
    BuildContext context,
    WidgetRef ref,
    int index,
  ) async {
    final l10n = context.l10n;
    final controller = ref.read(publishControllerProvider.notifier);
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0)
              ListTile(
                leading: const Icon(AppIcons.star),
                title: Text(l10n.publishMakeMain),
                onTap: () => Navigator.of(context).pop(_PhotoAction.makeMain),
              ),
            ListTile(
              leading: const Icon(AppIcons.trash),
              title: Text(l10n.publishRemovePhoto),
              onTap: () => Navigator.of(context).pop(_PhotoAction.remove),
            ),
          ],
        ),
      ),
    );
    switch (action) {
      case _PhotoAction.makeMain:
        controller.makeMainPhoto(index);
      case _PhotoAction.remove:
        controller.removePhoto(index);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final styles = context.textStyles;
    final photos = state.draft.photos;
    final error = _problemText(state, DraftProblem.noPhoto, l10n);
    final canAdd = photos.length < ListingDraft.maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(l10n.publishPhotosTitle, style: styles.titleMedium),
              ),
            ),
            Text(
              l10n.publishPhotosCount(photos.length, ListingDraft.maxPhotos),
              style: styles.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.publishPhotosHelper, style: styles.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: tileSize,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (canAdd)
                _AddPhotoTile(
                  key: const Key('publish-add-photos'),
                  size: tileSize,
                  hasError: error != null,
                  onTap: () => unawaited(_add(context, ref)),
                ),
              for (final (index, photo) in photos.indexed)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.sm,
                  ),
                  child: _PhotoTile(
                    key: ValueKey(photo.path),
                    photo: photo,
                    size: tileSize,
                    isMain: index == 0,
                    label: l10n.publishPhotoLabel(index + 1, photos.length),
                    onTap: () => unawaited(_photoActions(context, ref, index)),
                  ),
                ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(error, style: styles.bodySmall?.copyWith(color: colors.error)),
        ],
      ],
    );
  }
}

enum _PhotoSource { camera, gallery }

enum _PhotoAction { makeMain, remove }

class _AddPhotoTile extends StatelessWidget {
  const new({
    required this.size,
    required this.hasError,
    required this.onTap,
    super.key,
  });

  final double size;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Semantics(
      button: true,
      label: l10n.publishAddPhotos,
      excludeSemantics: true,
      // Case de taille fixe : texte agrandi plafonné (le libellé complet
      // est lu par le lecteur d'écran).
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Material(
          color: colors.surfaceMuted,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.sm,
            side: BorderSide(color: hasError ? colors.error : colors.border),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.sm,
            child: SizedBox.square(
              dimension: size,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.camera, color: colors.brand),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Text(
                      l10n.publishAddPhotos,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const new({
    required this.photo,
    required this.size,
    required this.isMain,
    required this.label,
    required this.onTap,
    super.key,
  });

  final LocalPhoto photo;
  final double size;
  final bool isMain;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return Semantics(
      button: true,
      label: isMain ? '$label, ${l10n.publishPhotoMain}' : label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: AppRadius.sm,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Vignette réduite : pas de photo pleine taille en mémoire.
                Image(
                  image: ResizeImage(
                    FileImage(File(photo.path)),
                    width: pixels,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => ColoredBox(
                    color: colors.surfaceMuted,
                    child: Icon(
                      AppIcons.imageBroken,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                if (isMain)
                  // Bandeau de hauteur fixe : texte agrandi plafonné.
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    bottom: 0,
                    child: ColoredBox(
                      color: colors.brand,
                      child: MediaQuery.withClampedTextScaling(
                        maxScaleFactor: 1.3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            l10n.publishPhotoMain,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.labelSmall?.copyWith(
                              color: colors.onBrand,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Champs

class _Fields extends ConsumerWidget {
  const new({required this.state});

  final PublishState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(publishControllerProvider.notifier);
    final draft = state.draft;
    final priceProblem =
        _problemText(state, DraftProblem.noPrice, l10n) ??
        _problemText(state, DraftProblem.priceTooHigh, l10n);
    final locations =
        ref.watch(listingLocationsProvider).value ?? ListingLocations.empty;
    final districtName = draft.district == null
        ? null
        : locations
              .districtsOf(draft.city)
              .where((item) => item.slug == draft.district)
              .map((item) => item.name)
              .firstOrNull;
    final category = state.category;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const Key('publish-title'),
          label: l10n.publishFieldTitle,
          hint: l10n.publishTitleHint,
          maxLength: ListingDraft.titleMaxLength,
          textInputAction: TextInputAction.next,
          errorText: _problemText(state, DraftProblem.titleTooShort, l10n),
          onChanged: controller.setTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const Key('publish-price'),
          label: l10n.publishFieldPrice,
          helper: l10n.publishPriceHelper,
          suffixText: l10n.feedFiltersCurrency,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          errorText: priceProblem,
          onChanged: controller.setPrice,
        ),
        const SizedBox(height: AppSpacing.lg),
        _PickerField(
          key: const Key('publish-category'),
          label: l10n.listingCategoryLabel,
          value: category == null ? null : userText(category.name),
          icon: category == null ? null : categoryIcon(category.icon),
          errorText: _problemText(state, DraftProblem.noCategory, l10n),
          onTap: () => unawaited(_pickCategory(context, ref)),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PickerField(
          key: const Key('publish-district'),
          label: l10n.publishFieldDistrict,
          value: districtName == null
              ? null
              : [districtName, ?locations.cityName(draft.city)].join(', '),
          icon: AppIcons.mapPin,
          errorText: _problemText(state, DraftProblem.noDistrict, l10n),
          onTap: () => unawaited(_pickDistrict(context, ref)),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ChoiceGroup<ListingCondition>(
          label: l10n.listingConditionLabel,
          values: ListingCondition.values,
          selected: draft.condition,
          labelOf: (value) => ListingDetailsSection.conditionLabel(value, l10n),
          errorText: _problemText(state, DraftProblem.noCondition, l10n),
          onSelected: controller.setCondition,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          key: const Key('publish-description'),
          label: l10n.publishFieldDescription,
          hint: l10n.publishDescriptionHint,
          maxLength: ListingDraft.descriptionMaxLength,
          minLines: 4,
          maxLines: 10,
          keyboardType: TextInputType.multiline,
          showCounter: false,
          errorText: _problemText(
            state,
            DraftProblem.descriptionTooShort,
            l10n,
          ),
          onChanged: controller.setDescription,
        ),
        const SizedBox(height: AppSpacing.sm),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.publishNegotiable),
          subtitle: Text(l10n.publishNegotiableHelper),
          value: draft.isNegotiable,
          onChanged: (value) => controller.setNegotiable(value: value),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChoiceGroup<DeliveryMode>(
          label: l10n.listingDeliveryLabel,
          values: DeliveryMode.values,
          selected: draft.deliveryMode,
          labelOf: (value) => ListingDetailsSection.deliveryLabel(value, l10n),
          onSelected: controller.setDeliveryMode,
        ),
      ],
    );
  }

  Future<void> _pickCategory(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<ListingCategory>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _CategoryPicker(selectedId: state.category?.id),
    );
    if (choice != null) {
      ref.read(publishControllerProvider.notifier).setCategory(choice);
    }
  }

  Future<void> _pickDistrict(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _DistrictPicker(
        city: state.draft.city,
        selected: state.draft.district,
      ),
    );
    if (choice != null) {
      ref.read(publishControllerProvider.notifier).setDistrict(choice);
    }
  }
}

/// Champ « à choisir » (catégorie, quartier) : ouvre une liste.
class _PickerField extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.errorText,
    super.key,
  });

  final String label;
  final String? value;
  final IconData? icon;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final colors = context.colors;
    final value = this.value;

    return Semantics(
      button: true,
      label: '$label, ${value ?? context.l10n.publishChoose}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.sm,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            errorText: errorText,
            errorMaxLines: 2,
            prefixIcon: value == null || icon == null ? null : Icon(icon),
            suffixIcon: const Icon(AppIcons.caretDown),
          ),
          child: Text(
            value ?? context.l10n.publishChoose,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: value == null
                ? styles.bodyLarge?.copyWith(color: colors.textSecondary)
                : styles.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// Choix unique en pastilles (état, remise).
class _ChoiceGroup<T> extends StatelessWidget {
  const new({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.errorText,
  });

  final String label;
  final List<T> values;
  final T? selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final error = errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(label, style: styles.titleSmall)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final value in values)
              ChoiceChip(
                label: Text(labelOf(value)),
                selected: value == selected,
                showCheckmark: false,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            error,
            style: styles.bodySmall?.copyWith(color: context.colors.error),
          ),
        ],
      ],
    );
  }
}

/// Liste des catégories (choix obligatoire, pas de « toutes »).
class _CategoryPicker extends ConsumerWidget {
  const new({required this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final categories = ref.watch(listingCategoriesProvider);

    final body = switch (categories) {
      AsyncData(value: Ok(:final value)) => ListView(
        shrinkWrap: true,
        children: [
          for (final category in value)
            ListTile(
              leading: Icon(categoryIcon(category.icon)),
              title: Text(userText(category.name)),
              selected: category.id == selectedId,
              selectedColor: colors.brand,
              trailing: category.id == selectedId
                  ? Icon(AppIcons.check, color: colors.brand)
                  : null,
              onTap: () => Navigator.of(context).pop(category),
            ),
        ],
      ),
      AsyncData(value: Err(:final failure)) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppErrorState(
          failure: failure,
          compact: true,
          onRetry: () => ref.invalidate(listingCategoriesProvider),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
    };

    return _PickerSheet(title: context.l10n.listingCategoryLabel, body: body);
  }
}

/// Liste des quartiers de la ville, triés par nom.
class _DistrictPicker extends ConsumerWidget {
  const new({required this.city, required this.selected});

  final String city;
  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final locations = ref.watch(listingLocationsProvider);
    final districts =
        locations.value?.districtsOf(city) ??
        const <({String slug, String name})>[];

    final Widget body;
    if (locations.isLoading) {
      body = const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (districts.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.publishDistrictsUnavailable, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => ref.invalidate(listingLocationsProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    } else {
      body = ListView(
        shrinkWrap: true,
        children: [
          for (final district in districts)
            ListTile(
              title: Text(district.name),
              selected: district.slug == selected,
              selectedColor: colors.brand,
              trailing: district.slug == selected
                  ? Icon(AppIcons.check, color: colors.brand)
                  : null,
              onTap: () => Navigator.of(context).pop(district.slug),
            ),
        ],
      );
    }

    final cityName = locations.value?.cityName(city);
    return _PickerSheet(
      title: cityName == null
          ? l10n.publishFieldDistrict
          : '${l10n.publishFieldDistrict} · $cityName',
      body: body,
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const new({required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
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
                child: Text(title, style: context.textStyles.titleLarge),
              ),
            ),
            Flexible(child: body),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Bas

class _PublishBar extends StatelessWidget {
  const new({required this.state, required this.onPublish});

  final PublishState state;
  final Future<void> Function() onPublish;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final step = state.step;
    final label = switch (step) {
      null => l10n.publishSubmit,
      PublishStep.creating => l10n.publishStepCreating,
      PublishStep.uploadingPhotos => l10n.publishStepPhotos,
      PublishStep.publishing => l10n.publishStepPublishing,
    };

    return Material(
      color: colors.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.sm,
          ),
          child: FilledButton(
            key: const Key('publish-submit'),
            onPressed: step == null ? () => unawaited(onPublish()) : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (step != null) ...[
                  SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
