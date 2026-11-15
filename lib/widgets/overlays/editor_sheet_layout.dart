import 'package:flutter/material.dart';
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
          final header = _SheetHeader(
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
          final actions = SafeArea(
            top: false,
            minimum: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              constraints.maxHeight < height ? 24 : bottomPadding,
            ),
            child: bottom ?? const SizedBox.shrink(),
          );
          // On compact keyboard layouts, all content scrolls so neither the title
          // nor a large-text action row consumes the field viewport completely.
          if (constraints.maxHeight < 400) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [header, fields, if (bottom != null) actions],
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
              if (bottom != null) actions,
            ],
          );
        },
      ),
    ),
  );
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.onClose,
    this.subtitle,
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
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF101828),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox.shrink(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      height: 20 / 14,
                      color: Color(0xFF475467),
                    ),
                  ),
                ),
              ],
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
