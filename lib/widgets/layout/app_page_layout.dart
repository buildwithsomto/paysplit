import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paysplit/theme/app_theme.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/buttons/app_back_button.dart';

/// Standard standalone page shell with a scrollable body and safe bottom action.
class AppPageLayout extends StatelessWidget {
  const AppPageLayout({
    required this.title,
    required this.onBack,
    required this.child,
    this.bottom,
    this.bodyGap = 19,
    this.headerTop = 22,
    this.trailing,
    this.backgroundColor,
    super.key,
  });
  final String title;
  final VoidCallback onBack;
  final Widget child;
  final Widget? bottom;
  final double bodyGap;
  final double headerTop;
  final Widget? trailing;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: AppTheme.systemOverlay,
    child: Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              restorationId: 'page_scroll',
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(16, headerTop, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      AppBackButton(onPressed: onBack),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(title, style: AppTypography.heading),
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  SizedBox(height: bodyGap),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 18, 16, 36),
              child: bottom!,
            ),
    ),
  );
}
