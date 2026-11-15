import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Preserves the original SVG inside the design's icon slot.
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(
    this.asset, {
    this.size = 24,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    super.key,
  });
  final String asset;
  final double size;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width ?? size,
    height: height ?? size,
    child: SvgPicture.asset(asset, fit: fit, excludeFromSemantics: true),
  );
}
