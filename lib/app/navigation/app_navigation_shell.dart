import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:paysplit/app/navigation/app_navigation_insets.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_glass.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

/// The outer Scaffold resizes the body for the keyboard; GlassScaffold owns
/// the refracting backdrop and the floating navigation bar.
class AppNavigationShell extends StatelessWidget {
  const AppNavigationShell({
    required this.child,
    required this.location,
    super.key,
  });
  final Widget child;
  final String location;
  static const _destinations = [
    ('Home', '/home', 'e8991.svg'),
    ('History', '/history', '9f5d6.svg'),
    ('Destination', '/destinations', 'c26b0.svg'),
    ('Split Rules', '/rules', 'f1027.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scaledLabel = media.textScaler.scale(12);
    final largeLabels = scaledLabel > 15;
    final horizontalPadding = math.max(16.0, (media.size.width - 500) / 2);
    final itemWidth =
        (media.size.width - horizontalPadding * 2 - 16) / _destinations.length;
    var labelHeight = scaledLabel * 1.2;
    if (largeLabels) {
      for (final (label, _, _) in _destinations) {
        final painter = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          textScaler: media.textScaler,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: itemWidth);
        labelHeight = math.max(labelHeight, painter.height);
        painter.dispose();
      }
    }
    final selected = _destinations.indexWhere((d) => d.$2 == location);
    final nav = GlassTabBar.bottom(
      tabs: [
        for (final (label, _, asset) in _destinations)
          GlassTab(
            icon: largeLabels
                ? _NavigationContent(
                    asset: asset,
                    label: label,
                    width: itemWidth,
                    selected: false,
                  )
                : _NavigationIcon(asset: asset, color: AppColors.body),
            activeIcon: largeLabels
                ? _NavigationContent(
                    asset: asset,
                    label: label,
                    width: itemWidth,
                    selected: true,
                  )
                : _NavigationIcon(asset: asset, color: AppColors.action),
            label: largeLabels ? null : label,
            semanticLabel: label,
          ),
      ],
      selectedIndex: selected < 0 ? 0 : selected,
      onTabSelected: (index) => context.go(_destinations[index].$2),
      horizontalPadding: horizontalPadding,
      verticalPadding: 18,
      barHeight: math.max(80, 24 + 8 + labelHeight + 32),
      barBorderRadius: 40,
      tabPadding: const EdgeInsets.all(8),
      iconLabelSpacing: 8,
      iconSize: 24,
      labelFontSize: 12,
      selectedIconColor: AppColors.action,
      unselectedIconColor: AppColors.body,
      selectedLabelColor: AppColors.action,
      unselectedLabelColor: AppColors.body,
      selectedLabelStyle: const TextStyle(
        fontFamily: 'DM Sans',
        fontWeight: FontWeight.w600,
        fontSize: 12,
        height: 1.2,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'DM Sans',
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.2,
      ),
      indicatorColor: const Color(0xE0FFFFFF),
      indicatorBorderRadius: 40,
      indicatorExpansion: EdgeInsets.zero,
      magnification: 1,
      glowOpacity: 0,
      settings: AppGlass.navigation,
      indicatorSettings: AppGlass.controls,
      quality: GlassQuality.premium,
      backgroundQuality: GlassQuality.premium,
    );
    final keyboardVisible = media.viewInsets.bottom > 0;
    final bottomClearance = keyboardVisible
        ? 0.0
        : nav.preferredSize.height + media.padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: location == '/home'
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: GlassScaffold(
          backgroundColor: AppColors.background,
          edgeFade: false,
          resizeToAvoidBottomInset: false,
          bottomBar: keyboardVisible ? null : nav,
          body: AppNavigationInsets(bottom: bottomClearance, child: child),
        ),
      ),
    );
  }
}

class _NavigationIcon extends StatelessWidget {
  const _NavigationIcon({required this.asset, required this.color});
  final String asset;
  final Color color;
  @override
  Widget build(BuildContext context) => ColorFiltered(
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    child: AppSvgIcon('assets/icons/dashboard/$asset'),
  );
}

/// The package's built-in label is one line inside a FittedBox. Supply bounded,
/// wrapping content through its public icon slot at larger text sizes so labels
/// remain at the user's requested scale. Glass still owns rendering and input.
class _NavigationContent extends StatelessWidget {
  const _NavigationContent({
    required this.asset,
    required this.label,
    required this.width,
    required this.selected,
  });
  final String asset, label;
  final double width;
  final bool selected;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavigationIcon(
          asset: asset,
          color: selected ? AppColors.action : AppColors.body,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            height: 1.2,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.action : AppColors.body,
          ),
        ),
      ],
    ),
  );
}
