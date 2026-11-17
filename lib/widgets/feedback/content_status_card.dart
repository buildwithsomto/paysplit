import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';

/// Shared loading, offline and failure feedback for any API-backed screen.
///
/// A first load shows [skeleton], placeholders in the shape of the content.
/// After that it never replaces content: whatever was last loaded stays
/// visible below it, and this card says how current that content is.
class ContentStatusCard extends StatelessWidget {
  const ContentStatusCard({
    required this.phase,
    required this.hasContent,
    required this.subject,
    required this.items,
    this.message,
    this.retryFailed = false,
    this.updatedAt,
    this.onRetry,
    this.skeleton = const SkeletonRows(),
    super.key,
  });
  final ContentPhase phase;
  final bool hasContent, retryFailed;

  /// Names the screen's data in the title, for example `Wallets`.
  final String subject;

  /// Names the records in the body copy, for example `wallets`.
  final String items;

  /// Replaces the default failure copy, usually with the API's message.
  final String? message;
  final DateTime? updatedAt;
  final VoidCallback? onRetry;

  /// Placeholders for the first load, shaped like this screen's content.
  final Widget skeleton;

  @override
  Widget build(BuildContext context) {
    if (phase == ContentPhase.ready) return const SizedBox.shrink();
    if (phase == ContentPhase.loading && !hasContent) {
      return SkeletonLoader(
        label: 'Loading ${subject.toLowerCase()}',
        child: skeleton,
      );
    }
    final busy = phase.isBusy;
    final title = switch (phase) {
      ContentPhase.loading => 'Loading ${subject.toLowerCase()}',
      ContentPhase.refreshing => 'Checking for updates',
      ContentPhase.offline => 'You’re offline',
      ContentPhase.error => '$subject could not be updated',
      ContentPhase.ready => '',
    };
    final body = busy
        ? hasContent
              ? 'Your $items stay visible while we check for updates.'
              : 'Your $items will appear when loading finishes.'
        : hasContent
        ? 'Showing the last loaded $items. Balances and statuses may be out of date.'
        : phase == ContentPhase.offline
        ? 'Reconnect to load your $items.'
        : message ?? 'We couldn’t load your $items. Please try again.';
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
              Text(body),
              if (updatedAt case final updatedAt? when hasContent)
                Text(
                  'Last updated: ${DateFormat.yMMMd().add_jm().format(updatedAt)} · Local time',
                  style: const TextStyle(fontSize: 12),
                ),
              if (retryFailed)
                Text('Still offline. Your $items and filters are unchanged.'),
              if (onRetry != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: busy ? null : onRetry,
                    child: const Text('Retry'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
