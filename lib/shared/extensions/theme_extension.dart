import 'package:afrimarket_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Raccourcis : `context.colors.brand`, `context.textStyles.titleMedium`.
extension ThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  TextTheme get textStyles => Theme.of(this).textTheme;
}
