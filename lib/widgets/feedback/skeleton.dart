import 'package:flutter/material.dart';

const _base = Color(0xFFE6EAF0);
const _highlight = Color(0xFFF4F6F9);

/// Marks a region as loading and drives the shimmer of every [SkeletonBox]
/// inside it, so a screen's placeholders move together.
///
/// Used wherever content is being fetched for the first time. Buttons keep
/// their own spinner: that is an action in progress, not content loading.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    required this.child,
    this.label = 'Loading',
    super.key,
  });

  final Widget child;

  /// What a screen reader announces in place of the placeholders.
  final String label;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // People who turn animations off get still placeholders.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: widget.label,
    child: ExcludeSemantics(
      child: _Shimmer(animation: _controller, child: widget.child),
    ),
  );
}

class _Shimmer extends InheritedWidget {
  const _Shimmer({required this.animation, required super.child});
  final Animation<double> animation;

  @override
  bool updateShouldNotify(_Shimmer oldWidget) =>
      animation != oldWidget.animation;
}

/// One placeholder block. Still, in the base colour, outside a
/// [SkeletonLoader].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({this.width, this.height = 14, this.radius = 6, super.key});

  /// A full-width block of [height], for a card or a chart.
  const SkeletonBox.card({this.height = 120, this.radius = 16, super.key})
    : width = double.infinity;

  /// A round placeholder for an avatar or an icon.
  const SkeletonBox.circle(double size, {super.key})
    : width = size,
      height = size,
      radius = size / 2;

  final double? width;
  final double height, radius;

  @override
  Widget build(BuildContext context) {
    final animation = context
        .dependOnInheritedWidgetOfExactType<_Shimmer>()
        ?.animation;
    final shape = BorderRadius.circular(radius);
    if (animation == null) {
      return SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(color: _base, borderRadius: shape),
        ),
      );
    }
    return SizedBox(
      width: width,
      height: height,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: shape,
            gradient: LinearGradient(
              colors: const [_base, _highlight, _base],
              stops: const [0.25, 0.5, 0.75],
              transform: _Slide(animation.value),
            ),
          ),
        ),
      ),
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.progress);
  final double progress;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (progress * 2 - 1), 0, 0);
}

/// Placeholder transaction rows: icon, two lines, amount and status.
class SkeletonRows extends StatelessWidget {
  const SkeletonRows({this.count = 5, super.key});
  final int count;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < count; index++)
        Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 18),
          child: const Row(
            spacing: 10,
            children: [
              SkeletonBox(width: 32, height: 32, radius: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    SkeletonBox(width: 150),
                    SkeletonBox(width: 80, height: 10),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 8,
                children: [
                  SkeletonBox(width: 76),
                  SkeletonBox(width: 52, height: 16, radius: 10),
                ],
              ),
            ],
          ),
        ),
    ],
  );
}

/// Placeholder list cards: a title, a line under it and a trailing chip.
/// Stands in for rules, beneficiaries, split runs and notifications.
class SkeletonTiles extends StatelessWidget {
  const SkeletonTiles({this.count = 3, super.key});
  final int count;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < count; index++)
        Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: const SkeletonSurface(
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      SkeletonBox(width: 140),
                      SkeletonBox(width: 90, height: 10),
                    ],
                  ),
                ),
                SkeletonBox(width: 84, height: 22, radius: 12),
              ],
            ),
          ),
        ),
    ],
  );
}

/// A placeholder detail card: a chip, a large amount, then labelled rows.
/// Stands in for a transaction, a rule or a split run.
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({this.rows = 4, super.key});
  final int rows;

  @override
  Widget build(BuildContext context) => SkeletonSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(width: 96, height: 26, radius: 8),
        const SizedBox(height: 16),
        const SkeletonBox(width: 180, height: 30, radius: 8),
        const SizedBox(height: 20),
        for (var index = 0; index < rows; index++)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SkeletonBox(width: 110),
                SkeletonBox(width: index.isEven ? 130 : 90),
              ],
            ),
          ),
      ],
    ),
  );
}

/// A placeholder form: labelled fields, as on a setup step.
class SkeletonForm extends StatelessWidget {
  const SkeletonForm({this.fields = 3, super.key});
  final int fields;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var index = 0; index < fields; index++) ...[
        if (index > 0) const SizedBox(height: 22),
        const SkeletonBox(width: 120),
        const SizedBox(height: 10),
        const SkeletonBox.card(height: 50, radius: 12),
      ],
    ],
  );
}

/// The white card placeholders sit on, so a loading screen keeps the
/// outline of the cards that will replace it.
class SkeletonSurface extends StatelessWidget {
  const SkeletonSurface({
    required this.child,
    this.radius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    super.key,
  });
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: child,
  );
}
