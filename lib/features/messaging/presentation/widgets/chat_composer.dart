import 'dart:async';

import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/messaging/domain/message_rules.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Champ « Écrire un message… » et bouton d'envoi (bas de la discussion).
///
/// Le bouton n'est actif que si le texte n'est pas vide ; le champ est
/// limité à [MessageRules.maxLength] caractères.
class ChatComposer extends StatefulWidget {
  const new({required this.onSend, super.key});

  final ValueChanged<String> onSend;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final hasText = MessageRules.clean(_controller.text) != null;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _send() {
    final text = _controller.text;
    if (MessageRules.clean(text) == null) return;
    unawaited(HapticFeedback.lightImpact());
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: MessageRules.maxLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) => null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.chatInputHint,
                    filled: true,
                    fillColor: colors.surfaceMuted,
                    border: const OutlineInputBorder(
                      borderRadius: AppRadius.pill,
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: AppRadius.pill,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.pill,
                      borderSide: BorderSide(color: colors.brand),
                    ),
                    contentPadding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                tooltip: l10n.chatSend,
                onPressed: _hasText ? _send : null,
                style: IconButton.styleFrom(
                  backgroundColor: colors.brand,
                  foregroundColor: colors.onBrand,
                  minimumSize: const Size.square(48),
                ),
                icon: const Icon(AppIcons.paperPlaneRight, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
