import 'package:intl/intl.dart';

/// Presentation helpers for NGN. All stored values are integer kobo.
abstract final class Money {
  static final _whole = NumberFormat('#,##0', 'en_NG');

  static String format(int minorUnits, {bool showDecimals = false}) {
    final magnitude = minorUnits.abs();
    final major = magnitude ~/ 100;
    final fraction = magnitude % 100;
    final decimals = showDecimals || fraction != 0
        ? '.${fraction.toString().padLeft(2, '0')}'
        : '';
    return '${minorUnits < 0 ? '−' : ''}₦${_whole.format(major)}$decimals';
  }

  /// Parses user input without a floating-point currency conversion.
  static int? parse(String input) {
    final normalized = input.trim().replaceFirst(RegExp(r'^₦\s*'), '');
    if (!RegExp(
      r'^(?:\d{1,12}|\d{1,3}(?:,\d{3}){1,3})(?:\.\d{1,2})?$',
    ).hasMatch(normalized)) {
      return null;
    }
    final value = normalized.replaceAll(',', '');
    if (!RegExp(r'^\d{1,12}(\.\d{1,2})?$').hasMatch(value)) return null;
    final parts = value.split('.');
    final major = int.parse(parts.first);
    final minor = parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0;
    return major * 100 + minor;
  }
}
