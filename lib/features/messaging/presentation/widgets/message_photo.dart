import 'dart:io';
import 'dart:typed_data';

import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/controllers/message_photo_provider.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Image d'une photo de message : le fichier du téléphone (photo que je
/// viens d'envoyer) ou l'image privée lue sur le serveur.
///
/// - fond neutre pendant le chargement ;
/// - échec : icône et « Touchez pour réessayer » ;
/// - image décodée à la taille affichée (économie de mémoire), sauf en
///   plein écran ([fullSize]).
class MessagePhotoImage extends ConsumerWidget {
  const new({
    this.messageId,
    this.localPath,
    this.fit = BoxFit.cover,
    this.fullSize = false,
    super.key,
  }) : assert(
         messageId != null || localPath != null,
         'Une photo vient du serveur ou du téléphone',
       );

  /// Message dont la photo est lue sur le serveur.
  final String? messageId;

  /// Fichier du téléphone (prioritaire : déjà là, pas de téléchargement).
  final String? localPath;

  final BoxFit fit;
  final bool fullSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cacheWidth = fullSize || !width.isFinite
            ? null
            : (width * MediaQuery.devicePixelRatioOf(context)).round();

        final path = localPath;
        if (path != null) {
          return Image.file(
            File(path),
            fit: fit,
            cacheWidth: cacheWidth,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            errorBuilder: (context, _, _) =>
                const _PhotoPlaceholder(icon: AppIcons.imageBroken),
          );
        }

        final id = messageId!;
        final photo = ref.watch(messagePhotoProvider(id));
        return switch (photo) {
          AsyncData(value: Ok<Uint8List>(:final value)) => Image.memory(
            value,
            fit: fit,
            cacheWidth: cacheWidth,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            errorBuilder: (context, _, _) =>
                const _PhotoPlaceholder(icon: AppIcons.imageBroken),
          ),
          AsyncData() || AsyncError() => _PhotoPlaceholder(
            icon: AppIcons.imageBroken,
            label: context.l10n.chatPhotoRetry,
            onTap: () => ref.invalidate(messagePhotoProvider(id)),
          ),
          AsyncLoading() => const _PhotoPlaceholder(),
        };
      },
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const new({this.icon, this.label, this.onTap});

  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final placeholderIcon = icon;
    final text = label;
    final content = ColoredBox(
      color: colors.imagePlaceholder,
      child: placeholderIcon == null
          ? const SizedBox.expand()
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(placeholderIcon, color: colors.textSecondary),
                    if (text != null)
                      Flexible(
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.fade,
                          style: context.textStyles.labelSmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
    final tap = onTap;
    if (tap == null) return content;
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tap,
        child: content,
      ),
    );
  }
}

/// Photo d'un message en grand (pincer pour zoomer), comme Messenger.
class MessagePhotoViewerPage extends StatelessWidget {
  const new({this.messageId, this.localPath, super.key});

  final String? messageId;
  final String? localPath;

  /// Ouvre la photo en plein écran, par-dessus les onglets.
  static Future<void> open(
    BuildContext context, {
    String? messageId,
    String? localPath,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) =>
            MessagePhotoViewerPage(messageId: messageId, localPath: localPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        leading: IconButton(
          key: const Key('photo-viewer-close'),
          tooltip: l10n.chatPhotoViewerClose,
          icon: const Icon(AppIcons.x),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Semantics(
          image: true,
          label: l10n.messagesPhotoPreview,
          child: InteractiveViewer(
            maxScale: 4,
            child: Center(
              child: MessagePhotoImage(
                messageId: messageId,
                localPath: localPath,
                fit: BoxFit.contain,
                fullSize: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
