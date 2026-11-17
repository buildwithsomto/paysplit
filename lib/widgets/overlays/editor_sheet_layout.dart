import 'package:flutter/material.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

/// Shared Figma bottom-sheet shell. Fields scroll above the keyboard and actions.
class EditorSheetLayout extends StatelessWidget {
  const EditorSheetLayout({
    required this.title,
    required this.child,
    this.bottom,
    this.subtitle,
    this.height = 631,
    this.bottomPadding = 36,
    required this.onClose,
    super.key,
  });
  final String title;
  final Widget child;
  final Widget? bottom;
  final String? subtitle;
  final double height;
  final double bottomPadding;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final header = EditorSheetHeader(
            title: title,
            subtitle: subtitle,
            onClose: onClose,
          );
          final fields = Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              subtitle == null ? 28 : 23,
              16,
              16,
            ),
            child: child,
          );
          final actions = switch (bottom) {
            final bottom? => SafeArea(
              top: false,
              minimum: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                constraints.maxHeight < height ? 24 : bottomPadding,
              ),
              child: bottom,
            ),
            null => null,
          };
          // On compact keyboard layouts, all content scrolls so neither the title
          // nor a large-text action row consumes the field viewport completely.
          if (constraints.maxHeight < 400) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [header, fields, ?actions],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: fields,
                ),
              ),
              ?actions,
            ],
          );
        },
      ),
    ),
  );
}

/// The patterned sheet header from the design: centred title, optional
/// subtitle and the round close button.
class EditorSheetHeader extends StatelessWidget {
  const EditorSheetHeader({
    required this.title,
    required this.onClose,
    this.subtitle,
    super.key,
  });
  final String title;
  final VoidCallback onClose;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 96),
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned.fill(
          child: ClipRect(
            child: ColorFiltered(
              // Figma's luminosity image fill over a white background.
              colorFilter: const ColorFilter.matrix([
                .3,
                .59,
                .11,
                0,
                0,
                .3,
                .59,
                .11,
                0,
                0,
                .3,
                .59,
                .11,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: RotatedBox(
                quarterTurns: 3,
                child: Image.asset(
                  'assets/icons/destinations/5703b.png',
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-.0436, -1),
                end: Alignment(.0436, 1),
                colors: [
                  Color(0x00FFFFFF),
                  Color(0xB2FFFFFF),
                  Color(0xE3FFFFFF),
                  Colors.white,
                ],
                stops: [.07526, .38174, .49841, .62466],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            subtitle == null ? 44 : 39,
            24,
            subtitle == null ? 24 : 14,
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.sheetTitle,
              ),
              if (subtitle case final subtitle?)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.sheetBody,
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 16,
          child: IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const AppSvgIcon('assets/icons/destinations/8ac92.svg'),
          ),
        ),
      ],
    ),
  );
}
