import 'package:flutter/material.dart';
import 'package:paysplit/theme/app_colors.dart';

abstract final class AppTypography {
  static const heading = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );
  static const title = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    height: 28 / 24,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );
  static const body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.body,
  );
  static const label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.label,
  );
  static const input = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );
  static const button = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );
}
