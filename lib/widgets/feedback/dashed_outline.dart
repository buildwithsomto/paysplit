import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dashed outline for the document drop zone specified in the mobile design.
class DashedOutline extends StatelessWidget {
  const DashedOutline({required this.color, required this.child, super.key});
  final Color color;
  final Widget child;
  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _DashedOutlinePainter(color),
    child: child,
  );
}

class _DashedOutlinePainter extends CustomPainter {
  const _DashedOutlinePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          const Radius.circular(8),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += 16) {
        canvas.drawPath(
          metric.extractPath(start, math.min(start + 8, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutlinePainter oldDelegate) =>
      oldDelegate.color != color;
}
