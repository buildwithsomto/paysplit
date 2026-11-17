import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';

abstract final class AppTheme {
  static final light = ThemeData(
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.action,
      onPrimary: AppColors.white,
      surface: AppColors.background,
      error: AppColors.error,
    ),
    textTheme: const TextTheme(
      bodyMedium: AppTypography.body,
      bodyLarge: AppTypography.input,
      labelLarge: AppTypography.button,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.sheet,
      modalBackgroundColor: AppColors.sheet,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.action,
      selectionColor: AppColors.primaryBorder,
      selectionHandleColor: AppColors.action,
    ),
  );

  static const systemOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}
