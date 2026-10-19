import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Champ de saisie d'AfriMarket.
///
/// - Libellé toujours visible, annoncé par les lecteurs d'écran.
/// - Validation au bon moment : quand on quitte le champ, puis à chaque
///   frappe une fois une erreur affichée (elle disparaît dès qu'elle est
///   corrigée). Jamais pendant la toute première saisie.
/// - Sécurité (OWASP MASVS PRIVACY) : pour un champ sensible, suggestions,
///   correction automatique et apprentissage du clavier sont désactivés.
///   [isPassword] active aussi le masquage avec un bouton 👁.
///
/// Widget autonome : fournit sa propre surface Material.
class AppTextField extends StatefulWidget {
  const new({
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.isPassword = false,
    this.sensitive,
    this.enabled = true,
    this.prefixIcon,
    this.errorText,
    this.suffixText,
    this.minLines,
    this.inputFormatters,
    this.showCounter = true,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool isPassword;

  /// Champ sensible (par défaut : vrai pour un mot de passe).
  final bool? sensitive;
  final bool enabled;
  final Widget? prefixIcon;

  /// Erreur fournie par l'écran (par exemple après « Publier ») ; une
  /// erreur du [validator] reste prioritaire.
  final String? errorText;

  /// Unité affichée après la saisie (« DH »).
  final String? suffixText;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;

  /// Affiche le compteur « 12/100 » quand [maxLength] est fixé (par défaut).
  final bool showCounter;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  final _focusNode = FocusNode();
  bool _obscured = true;

  bool get _isSensitive => widget.sensitive ?? widget.isPassword;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  /// Valide le champ quand on le quitte (s'il a été rempli).
  void _onFocusChange() {
    if (_focusNode.hasFocus) return;
    final field = _fieldKey.currentState;
    if (field != null && (field.value ?? '').isNotEmpty) {
      field.validate();
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isPassword = widget.isPassword;

    return Material(
      type: MaterialType.transparency,
      child: TextFormField(
        key: _fieldKey,
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        maxLength: widget.maxLength,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        maxLines: isPassword ? 1 : widget.maxLines,
        minLines: isPassword ? null : widget.minLines,
        inputFormatters: widget.inputFormatters,
        keyboardType: isPassword
            ? TextInputType.visiblePassword
            : widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        obscureText: isPassword && _obscured,
        enableSuggestions: !_isSensitive,
        autocorrect: !_isSensitive,
        enableIMEPersonalizedLearning: !_isSensitive,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          labelText: widget.label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: widget.hint,
          helperText: widget.helper,
          helperMaxLines: 2,
          errorMaxLines: 3,
          errorText: widget.errorText,
          suffixText: widget.suffixText,
          counterText: widget.showCounter ? null : '',
          prefixIcon: widget.prefixIcon,
          suffixIcon: isPassword
              ? IconButton(
                  tooltip: _obscured ? l10n.passwordShow : l10n.passwordHide,
                  icon: Icon(_obscured ? AppIcons.eye : AppIcons.eyeSlash),
                  onPressed: () => setState(() => _obscured = !_obscured),
                )
              : null,
        ),
      ),
    );
  }
}
