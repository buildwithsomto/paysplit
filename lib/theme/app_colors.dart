import 'package:flutter/material.dart';

/// Colours from the PaySplit mobile design.
abstract final class AppColors {
  static const background = Color(0xFFF7F7F7);
  static const white = Color(0xFFFFFFFF);

  /// The surface of every bottom sheet.
  static const sheet = Color(0xFFFBFBFB);
  static const primary = Color(0xFF33A7F5);

  /// Buttons, selected tabs and links. The design uses its primary blue for
  /// all of them.
  static const action = primary;
  static const positive = Color(0xFF087A20);
  static const primaryLight = Color(0xFFEBF6FE);
  static const primaryBorder = Color(0xFFD6EDFD);
  static const ink = Color(0xFF0F324A);
  static const heading = Color(0xFF101828);
  static const body = Color(0xFF475467);
  static const label = Color(0xFF344054);
  static const placeholder = Color(0xFF667085);

  /// The form field outline in the designs.
  static const border = Color(0xFFEDEDED);
  static const error = Color(0xFFB42318);
}
