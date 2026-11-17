import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paysplit/theme/app_colors.dart';

OverlayEntry? _current;
Timer? _timer;

/// Transient feedback for request outcomes, for example a failed save.
///
/// Drawn on the root overlay so it stays visible above bottom sheets, where a
/// snackbar would sit hidden behind the sheet.
void showAppNotice(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _dismiss();
  final entry = OverlayEntry(
    builder: (_) => _NoticeBanner(message: message, onClose: _dismiss),
  );
  _current = entry;
  overlay.insert(entry);
  _timer = Timer(const Duration(seconds: 5), _dismiss);
}

void _dismiss() {
  _timer?.cancel();
  _timer = null;
  final entry = _current;
  _current = null;
  if (entry != null && entry.mounted) entry.remove();
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 16,
    right: 16,
    top: MediaQuery.paddingOf(context).top + 8,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, -12 * (1 - t)),
          child: child,
        ),
      ),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Dismissible(
          key: ValueKey(message),
          direction: DismissDirection.up,
          onDismissed: (_) => onClose(),
          child: Material(
            color: AppColors.heading,
            elevation: 6,
            shadowColor: const Color(0x33101828),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    tooltip: 'Dismiss',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
