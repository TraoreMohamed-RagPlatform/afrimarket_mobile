import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/person_report_reason.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';

/// Confirmation avant de bloquer [name] (ce que fait le blocage, dit
/// simplement). Vrai si la personne confirme.
Future<bool> confirmBlock(BuildContext context, String name) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.safetyBlockTitle(name)),
      content: Text(l10n.safetyBlockMessage(name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.safetyCancel),
        ),
        TextButton(
          key: const Key('safety-block-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.safetyBlockConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Signalement choisi dans la feuille.
typedef PersonReport = ({
  PersonReportReason reason,
  String details,
  bool alsoBlock,
});

/// Libellé d'un motif de signalement d'une personne.
String personReportReasonLabel(
  PersonReportReason reason,
  AppLocalizations l10n,
) {
  return switch (reason) {
    PersonReportReason.scam => l10n.safetyReasonScam,
    PersonReportReason.harassment => l10n.safetyReasonHarassment,
    PersonReportReason.spam => l10n.safetyReasonSpam,
    PersonReportReason.offensive => l10n.safetyReasonOffensive,
    PersonReportReason.fakeProfile => l10n.safetyReasonFakeProfile,
    PersonReportReason.other => l10n.safetyReasonOther,
  };
}

/// Feuille « Signaler [name] » : motif (obligatoire), détail facultatif,
/// mention des messages joints, et « Bloquer aussi » (proposé, comme
/// Facebook) sauf si la personne est déjà bloquée. Null si fermée.
Future<PersonReport?> showReportPersonSheet(
  BuildContext context, {
  required String name,
  required bool alreadyBlocked,
}) {
  return showModalBottomSheet<PersonReport>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) =>
        _ReportPersonSheet(name: name, alreadyBlocked: alreadyBlocked),
  );
}

class _ReportPersonSheet extends StatefulWidget {
  const new({required this.name, required this.alreadyBlocked});

  final String name;
  final bool alreadyBlocked;

  @override
  State<_ReportPersonSheet> createState() => _ReportPersonSheetState();
}

class _ReportPersonSheetState extends State<_ReportPersonSheet> {
  final _details = TextEditingController();
  PersonReportReason? _reason;
  bool _alsoBlock = true;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason;
    if (reason == null) return;
    Navigator.of(context).pop<PersonReport>((
      reason: reason,
      details: _details.text,
      alsoBlock: !widget.alreadyBlocked && _alsoBlock,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final styles = context.textStyles;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.page,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.safetyReportTitle(widget.name),
                  style: styles.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.safetyReportQuestion, style: styles.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              for (final reason in PersonReportReason.values)
                Semantics(
                  inMutuallyExclusiveGroup: true,
                  selected: reason == _reason,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(personReportReasonLabel(reason, l10n)),
                    trailing: reason == _reason
                        ? Icon(AppIcons.check, color: colors.brand)
                        : null,
                    onTap: () => setState(() => _reason = reason),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('safety-report-details'),
                controller: _details,
                minLines: 2,
                maxLines: 4,
                maxLength: PersonReportReason.maxDetailsLength,
                decoration: InputDecoration(labelText: l10n.reportDetailsLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(AppIcons.info, size: 18, color: colors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.safetyReportMessagesNotice(
                        PersonReportReason.copiedMessages,
                      ),
                      style: styles.bodySmall,
                    ),
                  ),
                ],
              ),
              if (!widget.alreadyBlocked)
                CheckboxListTile(
                  key: const Key('safety-report-also-block'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l10n.safetyReportAlsoBlock(widget.name)),
                  value: _alsoBlock,
                  onChanged: (value) =>
                      setState(() => _alsoBlock = value ?? false),
                ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const Key('safety-report-submit'),
                onPressed: _reason == null ? null : _submit,
                child: Text(l10n.reportSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
