import 'dart:async';

import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Paramètres (menu ☰). Accessible sans compte : langue et thème.
///
/// - connecté : « Confidentialité et sécurité » → Personnes bloquées ;
/// - PROVISOIRE : le choix de la langue et du thème arrive avec la
///   fonctionnalité Paramètres.
class SettingsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final signedIn = ref.watch(sessionProvider) == SessionStatus.authenticated;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          if (signedIn) ...[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.page,
                AppSpacing.lg,
                AppSpacing.page,
                AppSpacing.xs,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.settingsPrivacySection,
                  style: context.textStyles.titleSmall,
                ),
              ),
            ),
            ListTile(
              key: const Key('settings-blocked-people'),
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.page,
              ),
              leading: const Icon(AppIcons.prohibit),
              title: Text(l10n.safetyBlockedPeopleTitle),
              trailing: const Icon(AppIcons.caretRight),
              onTap: () => unawaited(context.push(AppRoutes.blockedPeople)),
            ),
            const Divider(height: AppSpacing.xl),
          ],
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(l10n.settingsComingSoon, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
