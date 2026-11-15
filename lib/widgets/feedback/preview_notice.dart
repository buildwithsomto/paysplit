import 'package:flutter/material.dart';

/// Keeps simulated service outcomes explicit without changing the design.
void showPreviewNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        showCloseIcon: true,
      ),
    );
}
