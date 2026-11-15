import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/constants/app_assets.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_theme.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({this.advance = true, super.key});
  final bool advance;
  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    if (widget.advance) {
      _timer = Timer(const Duration(milliseconds: 1100), () {
        if (mounted) context.go('/login');
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
