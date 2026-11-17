import 'package:flutter/material.dart';

/// Carries a scrolling header's colour into the space above it.
///
/// iOS lets a page be pulled down past its top edge, for pull-to-refresh or
/// just the bounce. A header that scrolls with the page would then leave a
/// band of the page colour above it. Wrapping the header in this fills that
/// band with the header's own [color] or [gradient], as system apps do.
class HeaderOverscrollFill extends StatelessWidget {
  const HeaderOverscrollFill({
    required this.child,
    this.color,
    this.gradient,
    super.key,
  }) : assert(color != null || gradient != null);

  final Widget child;
  final Color? color;
  final Gradient? gradient;

  /// Taller than any pull-down, so the fill never runs out.
  static const _extent = 800.0;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: 0,
        right: 0,
        top: -_extent,
        height: _extent,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, gradient: gradient),
          ),
        ),
      ),
      child,
    ],
  );
}
