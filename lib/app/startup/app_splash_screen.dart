import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/core/constants/app_assets.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_theme.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

class AppSplashScreen extends ConsumerStatefulWidget {
  const AppSplashScreen({super.key});
  @override
  ConsumerState<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends ConsumerState<AppSplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  /// Restores the stored session while the brand mark is on screen, then
  /// opens the dashboard or the login screen.
  Future<void> _start() async {
    final session = ref.read(sessionControllerProvider.notifier);
    await Future.wait([
      session.restore(),
      Future<void>.delayed(const Duration(milliseconds: 1100)),
    ]);
    if (!mounted) return;
    context.go(
      ref.read(sessionControllerProvider).isAuthenticated ? '/home' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: AppTheme.systemOverlay.copyWith(
      systemNavigationBarColor: AppColors.primary,
    ),
    child: Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Semantics(
          label: 'PaySplit',
          image: true,
          child: const AppSvgIcon(AppAssets.logo, size: 80),
        ),
      ),
    ),
  );
}
