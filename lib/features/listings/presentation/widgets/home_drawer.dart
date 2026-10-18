import 'dart:async';

import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/dev_tools.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_motion.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/auth/presentation/controllers/sign_out.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Ouvre le menu ☰ par-dessus toute l'app (barre du bas comprise).
///
/// Le menu est une page du navigateur principal, et non le `drawer`
/// d'un `Scaffold` imbriqué dans un onglet : le bouton Retour d'Android
/// (retour prédictif, Android 14 et plus) le ferme au lieu de quitter
/// l'app.
Future<void> showHomeMenu(
  BuildContext context, {
  required VoidCallback onCategories,
}) {
  final isRtl = Directionality.of(context) == TextDirection.rtl;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5),
    transitionDuration: AppMotion.resolve(context, AppMotion.normal),
    pageBuilder: (context, animation, secondaryAnimation) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: HomeDrawer(onCategories: onCategories),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position:
            Tween<Offset>(
              begin: Offset(isRtl ? 1 : -1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: AppMotion.standardCurve,
              ),
            ),
        child: child,
      );
    },
  );
}

/// Menu ☰ du fil : catégories, profil, paramètres, aide, connexion.
///
/// Chaque entrée ferme d'abord le menu, puis ouvre sa page.
class HomeDrawer extends ConsumerWidget {
  const new({required this.onCategories, super.key});

  /// Ouvre la liste des catégories (même liste que la pastille du fil).
  final VoidCallback onCategories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isSignedIn =
        ref.watch(sessionProvider) == SessionStatus.authenticated;
    final showDevTools = devToolsVisible(ref.watch(appConfigProvider).flavor);

    // Ferme le menu, puis exécute `action`.
    VoidCallback close(VoidCallback action) => () {
      Navigator.of(context).pop();
      action();
    };

    return Drawer(
      semanticLabel: l10n.menuTooltip,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppLogo(height: 32),
              ),
            ),
            _Entry(
              icon: AppIcons.squaresFour,
              label: l10n.categoriesTitle,
              onTap: close(onCategories),
            ),
            _Entry(
              icon: AppIcons.user,
              label: l10n.myProfileTitle,
              onTap: close(() => unawaited(context.push(AppRoutes.profile))),
            ),
            _Entry(
              icon: AppIcons.gear,
              label: l10n.settingsTitle,
              onTap: close(() => unawaited(context.push(AppRoutes.settings))),
            ),
            _Entry(
              icon: AppIcons.question,
              label: l10n.helpTitle,
              onTap: close(() => unawaited(context.push(AppRoutes.help))),
            ),
            const Divider(),
            if (isSignedIn)
              _Entry(
                icon: AppIcons.signOut,
                label: l10n.logoutTooltip,
                onTap: close(() => unawaited(ref.read(signOutProvider)())),
              )
            else
              _Entry(
                icon: AppIcons.signIn,
                label: l10n.signInAction,
                onTap: close(
                  () => unawaited(
                    context.push(AppRoutes.loginWithReturn(AppRoutes.home)),
                  ),
                ),
              ),
            if (showDevTools) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Text(
                  l10n.devToolsSection,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              _Entry(
                icon: AppIcons.wrench,
                label: l10n.devDiagnosticsButton,
                onTap: close(() => context.go(AppRoutes.diagnostics)),
              ),
              _Entry(
                icon: AppIcons.palette,
                label: l10n.devGalleryButton,
                onTap: close(() => unawaited(context.push(AppRoutes.gallery))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const new({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
  }
}
