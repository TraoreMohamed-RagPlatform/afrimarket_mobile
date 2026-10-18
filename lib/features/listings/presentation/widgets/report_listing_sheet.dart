import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/report_reason.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';

/// Signalement choisi dans la feuille.
typedef ListingReport = ({ReportReason reason, String details});

/// Ouvre la feuille « Signaler cette annonce » : un motif (obligatoire)
/// et un détail facultatif. Renvoie null si l'utilisateur la ferme.
///
/// Ouverte sur le navigateur principal : le bouton Retour d'Android la
/// ferme sans quitter la page.
Future<ListingReport?> showReportListingSheet(BuildContext context) {
  return showModalBottomSheet<ListingReport>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _ReportListingSheet(),
  );
}

/// Libellé d'un motif de signalement.
String reportReasonLabel(ReportReason reason, AppLocalizations l10n) {
  return switch (reason) {
    ReportReason.scam => l10n.reportReasonScam,
    ReportReason.prohibitedItem => l10n.reportReasonProhibited,
    ReportReason.offensive => l10n.reportReasonOffensive,
    ReportReason.misleading => l10n.reportReasonMisleading,
    ReportReason.spam => l10n.reportReasonSpam,
    ReportReason.alreadySold => l10n.reportReasonSold,
    ReportReason.other => l10n.reportReasonOther,
  };
}

class _ReportListingSheet extends StatefulWidget {
  const new();

  @override
  State<_ReportListingSheet> createState() => _ReportListingSheetState();
}

class _ReportListingSheetState extends State<_ReportListingSheet> {
  final _details = TextEditingController();
  ReportReason? _reason;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason;
    if (reason == null) return;
    Navigator.of(context)
        .pop<ListingReport>((reason: reason, details: _details.text));
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
                child: Text(l10n.listingReportAction, style: styles.titleLarge),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.reportSheetQuestion, style: styles.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              for (final reason in ReportReason.values)
                Semantics(
                  inMutuallyExclusiveGroup: true,
                  selected: reason == _reason,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(reportReasonLabel(reason, l10n)),
                    trailing: reason == _reason
                        ? Icon(AppIcons.check, color: colors.brand)
                        : null,
                    onTap: () => setState(() => _reason = reason),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _details,
                minLines: 2,
                maxLines: 4,
                maxLength: ReportReason.maxDetailsLength,
                decoration: InputDecoration(labelText: l10n.reportDetailsLabel),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
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
