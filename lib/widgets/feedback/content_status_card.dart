import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/theme/app_colors.dart';

/// Shared loading/failure feedback without taking ownership of requests or data.
class ContentStatusCard extends StatelessWidget {
  const ContentStatusCard({
    required this.phase,
    required this.hasContent,
    this.sample = false,
    this.retryFailed = false,
    this.updatedAt,
    this.onRetry,
    this.onRestorePreview,
    super.key,
  });
  final ContentPhase phase;
  final bool hasContent, sample, retryFailed;
  final DateTime? updatedAt;
  final VoidCallback? onRetry, onRestorePreview;

  @override
  Widget build(BuildContext context) {
    if (phase == ContentPhase.ready) return const SizedBox.shrink();
    final busy =
        phase == ContentPhase.loading || phase == ContentPhase.refreshing;
    final title = switch (phase) {
      ContentPhase.loading => 'Loading history',
      ContentPhase.refreshing => 'Checking for updates',
      ContentPhase.offline => 'You’re offline',
      ContentPhase.error => 'History could not be updated',
      ContentPhase.ready => '',
    };
    final message = busy
        ? hasContent
              ? 'Your saved transactions stay visible while we check for updates.'
              : 'Your records will appear when loading finishes.'
        : hasContent
        ? 'Showing saved transactions. Balances and payment statuses may be out of date.'
        : 'No saved transactions to show. Try again when you’re connected.';
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              if (sample)
                const Text(
                  'SIMULATED CONNECTION ISSUE',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              Row(
                spacing: 12,
                children: [
                  if (busy)
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Loading',
                      ),
                    ),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Text(message),
              if (hasContent && updatedAt != null)
                Text(
                  'Last updated: ${DateFormat.yMMMd().add_jm().format(updatedAt!)} · Local time',
                  style: const TextStyle(fontSize: 12),
                ),
              if (retryFailed)
                const Text(
                  'Still offline. Your saved transactions and filters are unchanged.',
                ),
              if (onRetry != null || onRestorePreview != null)
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (onRetry != null)
                      TextButton(
                        onPressed: busy ? null : onRetry,
                        child: const Text('Retry'),
                      ),
                    if (onRestorePreview != null)
                      TextButton(
                        onPressed: onRestorePreview,
                        child: const Text('Restore sample connection'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
