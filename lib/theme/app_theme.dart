import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';

abstract final class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
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
      headlineSmall: AppTypography.title,
      titleLarge: AppTypography.heading,
      bodyMedium: AppTypography.body,
      bodyLarge: AppTypography.input,
      labelLarge: AppTypography.button,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: systemOverlay,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.action,
      selectionColor: AppColors.primaryBorder,
      selectionHandleColor: AppColors.action,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
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
