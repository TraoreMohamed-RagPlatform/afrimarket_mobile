import 'dart:async';
import 'dart:io';

import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/text/text_fold.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_locations.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/listing_detail_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/listing_form_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/category_icon.dart';
import 'package:afrimarket_mobile/features/listings/presentation/widgets/listing_details_section.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/snackbar_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:afrimarket_mobile/shared/widgets/app_error_state.dart';
import 'package:afrimarket_mobile/shared/widgets/app_network_image.dart';
import 'package:afrimarket_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Formulaire d'annonce, commun aux écrans « Publier » et « Modifier »
/// (une seule page, comme Facebook Marketplace) : photos en haut, puis
/// titre, prix, catégorie, quartier, état, description, négociable,
/// remise.
///
/// Les champs texte partent de [draft] à la création du formulaire
/// (annonce vide, ou annonce à modifier) ; la saisie remonte par
/// [actions]. Changer la `key` recrée le formulaire (saisie relue).
class ListingForm extends StatefulWidget {
  const new({
    required this.draft,
    required this.category,
    required this.problems,
    required this.actions,
    super.key,
  });

  final ListingDraft draft;

  /// Catégorie choisie (pour afficher son nom et son icône).
  final ListingCategory? category;

  /// Problèmes à signaler sous les champs.
  final Set<DraftProblem> problems;

  final ListingFormActions actions;

  @override
  State<ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends State<ListingForm> {
  late final _title = TextEditingController(text: widget.draft.title);
  late final _price = TextEditingController(
    text: widget.draft.price?.toString() ?? '',
  );
  late final _description = TextEditingController(
    text: widget.draft.description,
  );

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PhotosSection(
          draft: widget.draft,
          problems: widget.problems,
          actions: widget.actions,
        ),
        const SizedBox(height: AppSpacing.lg),
        _Fields(
          draft: widget.draft,
          category: widget.category,
          problems: widget.problems,
          actions: widget.actions,
          title: _title,
          price: _price,
          description: _description,
        ),
      ],
    );
  }
}

/// Message sous un champ pour un problème, s'il est signalé.
String? _problemText(
  Set<DraftProblem> problems,
  DraftProblem problem,
  AppLocalizations l10n,
) {
  if (!problems.contains(problem)) return null;
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

class _PhotosSection extends StatelessWidget {
  const new({
    required this.draft,
    required this.problems,
    required this.actions,
  });

  final ListingDraft draft;
  final Set<DraftProblem> problems;
  final ListingFormActions actions;

  /// Côté d'une vignette.
  static const double tileSize = 96;

  Future<void> _add(BuildContext context) async {
    final l10n = context.l10n;
    final controller = actions;
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

  Future<void> _photoActions(BuildContext context, int index) async {
    final l10n = context.l10n;
    final controller = actions;
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final styles = context.textStyles;
    final photos = draft.photos;
    final error = _problemText(problems, DraftProblem.noPhoto, l10n);
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
                  onTap: () => unawaited(_add(context)),
                ),
              for (final (index, photo) in photos.indexed)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.sm,
                  ),
                  child: _PhotoTile(
                    key: ValueKey(photo.key),
                    photo: photo,
                    size: tileSize,
                    isMain: index == 0,
                    label: l10n.publishPhotoLabel(index + 1, photos.length),
                    onTap: () => unawaited(_photoActions(context, index)),
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

  final DraftPhoto photo;
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
                switch (photo) {
                  // Vignette réduite : pas de photo pleine taille en mémoire.
                  LocalPhoto(:final path) => Image(
                    image: ResizeImage(FileImage(File(path)), width: pixels),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => ColoredBox(
                      color: colors.surfaceMuted,
                      child: Icon(
                        AppIcons.imageBroken,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  RemotePhoto(:final url) => AppNetworkImage(url: url),
                },
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
  const new({
    required this.draft,
    required this.category,
    required this.problems,
    required this.actions,
    required this.title,
    required this.price,
    required this.description,
  });

  final ListingDraft draft;
  final ListingCategory? category;
  final Set<DraftProblem> problems;
  final ListingFormActions actions;
  final TextEditingController title;
  final TextEditingController price;
  final TextEditingController description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = actions;
    final priceProblem =
        _problemText(problems, DraftProblem.noPrice, l10n) ??
        _problemText(problems, DraftProblem.priceTooHigh, l10n);
    final locations =
        ref.watch(listingLocationsProvider).value ?? ListingLocations.empty;
    final districtName = draft.district == null
        ? null
        : locations
              .districtsOf(draft.city)
              .where((item) => item.slug == draft.district)
              .map((item) => item.name)
              .firstOrNull;
    final category = this.category;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const Key('publish-title'),
          controller: title,
          label: l10n.publishFieldTitle,
          hint: l10n.publishTitleHint,
          maxLength: ListingDraft.titleMaxLength,
          textInputAction: TextInputAction.next,
          errorText: _problemText(problems, DraftProblem.titleTooShort, l10n),
          onChanged: controller.setTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const Key('publish-price'),
          controller: price,
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
          errorText: _problemText(problems, DraftProblem.noCategory, l10n),
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
          errorText: _problemText(problems, DraftProblem.noDistrict, l10n),
          onTap: () => unawaited(_pickDistrict(context, ref)),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ChoiceGroup<ListingCondition>(
          label: l10n.listingConditionLabel,
          values: ListingCondition.values,
          selected: draft.condition,
          labelOf: (value) => ListingDetailsSection.conditionLabel(value, l10n),
          errorText: _problemText(problems, DraftProblem.noCondition, l10n),
          onSelected: controller.setCondition,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          key: const Key('publish-description'),
          controller: description,
          label: l10n.publishFieldDescription,
          hint: l10n.publishDescriptionHint,
          maxLength: ListingDraft.descriptionMaxLength,
          minLines: 4,
          maxLines: 10,
          keyboardType: TextInputType.multiline,
          showCounter: false,
          errorText: _problemText(
            problems,
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
      builder: (context) => _CategoryPicker(selectedId: category?.id),
    );
    if (choice != null) actions.setCategory(choice);
  }

  Future<void> _pickDistrict(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) =>
          _DistrictPicker(city: draft.city, selected: draft.district),
    );
    if (choice != null) actions.setDistrict(choice);
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
class _DistrictPicker extends ConsumerStatefulWidget {
  const new({required this.city, required this.selected});

  final String city;
  final String? selected;

  @override
  ConsumerState<_DistrictPicker> createState() => _DistrictPickerState();
}

/// Liste des quartiers avec recherche (sans tenir compte des accents :
/// « ain » trouve « Aïn Chock »).
class _DistrictPickerState extends ConsumerState<_DistrictPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final locations = ref.watch(listingLocationsProvider);
    final all =
        locations.value?.districtsOf(widget.city) ??
        const <({String slug, String name})>[];
    final query = foldText(_query);
    final districts = query.isEmpty
        ? all
        : [
            for (final district in all)
              if (foldText(district.name).contains(query)) district,
          ];

    final Widget body;
    if (locations.isLoading) {
      body = const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (all.isEmpty) {
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
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              key: const Key('district-search'),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.publishSearchDistrict,
                prefixIcon: const Icon(AppIcons.magnifyingGlass),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Flexible(
            child: districts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      l10n.publishNoDistrictMatch,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final district in districts)
                        ListTile(
                          title: Text(district.name),
                          selected: district.slug == widget.selected,
                          selectedColor: colors.brand,
                          trailing: district.slug == widget.selected
                              ? Icon(AppIcons.check, color: colors.brand)
                              : null,
                          onTap: () => Navigator.of(context).pop(district.slug),
                        ),
                    ],
                  ),
          ),
        ],
      );
    }

    final cityName = locations.value?.cityName(widget.city);
    return Padding(
      // Le clavier de la recherche ne cache pas la liste.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _PickerSheet(
        title: cityName == null
            ? l10n.publishFieldDistrict
            : '${l10n.publishFieldDistrict} · $cityName',
        body: body,
      ),
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

/// Bouton du bas des écrans « Publier » et « Modifier » ; pendant
/// l'envoi, l'étape en cours s'affiche à côté d'un indicateur.
class ListingSubmitBar extends StatelessWidget {
  const new({
    required this.buttonKey,
    required this.label,
    required this.busy,
    required this.onPressed,
    super.key,
  });

  final Key buttonKey;
  final String label;
  final bool busy;

  /// `null` : bouton désactivé.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
            key: buttonKey,
            onPressed: onPressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy) ...[
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
