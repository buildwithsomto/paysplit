import 'package:flutter/material.dart';

/// A declarative root modal route, so sheets cover the tab navigation shell.
class AppSheetPage extends Page<void> {
  const AppSheetPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });
  final Widget child;
  @override
  Route<void> createRoute(BuildContext context) => ModalBottomSheetRoute<void>(
    settings: this,
    builder: (_) => child,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFFFBFBFB),
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
  );
}
