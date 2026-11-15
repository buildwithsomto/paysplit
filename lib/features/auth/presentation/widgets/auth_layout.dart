import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paysplit/theme/app_theme.dart';
import 'package:paysplit/theme/app_typography.dart';

/// Shared Scaffold owns safe areas, keyboard resizing and scrolling.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    this.header,
    required this.title,
    required this.description,
    required this.child,
    this.topPadding = 20,
    this.titleGap = 24,
    this.formGap = 40,
    this.largeTitle = false,
    this.footer,
    super.key,
  });
  final Widget? header;
  final String title;
  final Widget description;
  final Widget child;
  final double topPadding;
  final double titleGap;
  final double formGap;
  final bool largeTitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: AppTheme.systemOverlay,
    child: Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(16, topPadding, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (header case final header?) ...[
                    header,
                    SizedBox(height: titleGap),
                  ],
                  Text(
                    title,
                    style: largeTitle
                        ? AppTypography.title
                        : AppTypography.heading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  DefaultTextStyle(
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                    child: description,
                  ),
                  SizedBox(height: formGap),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: footer == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: footer!,
            ),
    ),
  );
}
