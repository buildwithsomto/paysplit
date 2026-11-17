import 'dart:math' as math;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Liquid glass material for the navigation bar and its selection indicator.
abstract final class AppGlass {
  static const controls = LiquidGlassSettings.figma(
    refraction: 83,
    depth: 44,
    dispersion: 18,
    frost: 9.978,
    lightIntensity: 100,
    lightAngle: 315 * math.pi / 180,
  );
  static final navigation = controls.copyWith(lightAngle: 287 * math.pi / 180);
}
