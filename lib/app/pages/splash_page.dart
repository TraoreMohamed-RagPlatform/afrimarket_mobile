import 'package:afrimarket_mobile/app/router/splash_intro.dart';
import 'package:afrimarket_mobile/core/theme/app_logo_colors.dart';
import 'package:afrimarket_mobile/core/theme/app_motion.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_logo_intro.dart';
import 'package:afrimarket_mobile/shared/widgets/bogolan_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran de démarrage : le logo s'anime pendant que la session est
/// vérifiée (ADR 0011).
///
/// - Même fond que l'écran natif d'Android et l'icône de l'app : la
///   transition se fait sans saut.
/// - « Réduire les animations » : le logo s'affiche directement.
/// - À la fin de l'animation, le routeur ouvre la page suivante dès que
///   la session est connue.
class SplashPage extends ConsumerStatefulWidget {
  const new({super.key});

  /// Hauteur du symbole du logo.
  static const double logoHeight = 72;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppLogoIntro.duration,
  )..addStatusListener(_onStatus);

  late final CurvedAnimation _motif = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.75, 1),
  );

  bool _started = false;
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduceMotion(context)) {
      // Logo affiché directement, sans mouvement.
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (!status.isCompleted || _finished) return;
    _finished = true;
    // Après l'image en cours : on ne modifie jamais l'état de l'app
    // pendant la construction de l'écran.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(splashIntroFinishedProvider.notifier).markFinished();
      }
    });
  }

  @override
  void dispose() {
    _motif.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppLogoColors.of(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: colors.canvas,
      body: Semantics(
        label: context.l10n.splashLoading,
        liveRegion: true,
        child: Stack(
          children: [
            Center(child: AppLogoIntro(animation: _controller)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: FadeTransition(
                  opacity: _motif,
                  child: BogolanStrip(
                    color: colors.cloth.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
