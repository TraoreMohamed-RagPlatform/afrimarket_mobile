import 'dart:async';

import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';

/// Bloc « Envoyer un message au vendeur » (comme Marketplace) : un
/// message proposé, modifiable, et le bouton « Envoyer ».
///
/// [onSend] reçoit le texte saisi et dit si l'envoi a réussi ; le bouton
/// est désactivé pendant l'envoi (pas de double message).
class ListingMessageBox extends StatefulWidget {
  const new({required this.onSend, super.key});

  final Future<bool> Function(String message) onSend;

  @override
  State<ListingMessageBox> createState() => _ListingMessageBoxState();
}

class _ListingMessageBoxState extends State<ListingMessageBox> {
  TextEditingController? _controller;
  bool _sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Le message proposé dépend de la langue : créé une seule fois.
    _controller ??= TextEditingController(
      text: context.l10n.listingMessageDefault,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final controller = _controller;
    if (_sending || controller == null) return;
    setState(() => _sending = true);
    await widget.onSend(controller.text);
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final styles = context.textStyles;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: AppRadius.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(AppIcons.chatCircle, size: 20, color: colors.brand),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.listingMessageTitle,
                      style: styles.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_sending,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => unawaited(_send()),
                    decoration: InputDecoration(
                      labelText: l10n.listingMessageFieldLabel,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: _sending ? null : () => unawaited(_send()),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  child: _sending
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: l10n.loadingLabel,
                          ),
                        )
                      : Text(l10n.listingMessageSend),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
