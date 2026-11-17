import 'package:flutter/material.dart';

/// The pinned action at the bottom of a page.
///
/// A scaffold leaves its bottom bar under the keyboard, and the number pad has
/// no "done" key, so this lifts the action above the keyboard to keep it
/// reachable while a field has focus.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({required this.child, super.key});

  final Widget child;
  static const _padding = EdgeInsets.fromLTRB(16, 18, 16, 36);

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        minimum: keyboard > 0
            ? _padding.copyWith(top: 12, bottom: 12)
            : _padding,
        child: child,
      ),
    );
  }
}
