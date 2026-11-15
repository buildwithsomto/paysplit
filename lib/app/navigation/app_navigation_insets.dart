import 'package:flutter/widgets.dart';

/// Clearance belongs inside each tab's scrollable so content can pass behind
/// the glass, while its final controls can still scroll fully above the bar.
class AppNavigationInsets extends InheritedWidget {
  const AppNavigationInsets({
    required this.bottom,
    required super.child,
    super.key,
  });
  final double bottom;
  static double bottomOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AppNavigationInsets>()
          ?.bottom ??
      MediaQuery.paddingOf(context).bottom;
  @override
  bool updateShouldNotify(AppNavigationInsets oldWidget) =>
      bottom != oldWidget.bottom;
}
