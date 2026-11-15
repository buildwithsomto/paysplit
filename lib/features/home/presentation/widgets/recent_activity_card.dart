import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';
import 'package:paysplit/features/history/presentation/widgets/transaction_tile.dart';
import 'package:paysplit/features/home/presentation/widgets/dashboard_card.dart';

/// Uses the same records and detail routes as History.
class RecentActivityCard extends ConsumerWidget {
  const RecentActivityCard({required this.showAmounts, super.key});

  final bool showAmounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyControllerProvider);
    final unavailable = history.phase != ContentPhase.ready;
    final records = history.records.take(3);
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Semantics(
            header: true,
            child: const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          if (records.isEmpty)
            Text(
              unavailable
                  ? 'Activity is unavailable. Open History to check its status.'
                  : 'Salary deposits and splits will appear here.',
            ),
          if (records.isNotEmpty && unavailable)
            const Text('Saved activity. Payment statuses may have changed.'),
          if (records.isNotEmpty && history.sample)
            const Text('Sample transactions', style: TextStyle(fontSize: 12)),
          for (final record in records)
            TransactionTile(record: record, showAmount: showAmounts),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go('/history'),
              child: const Text('View all activity'),
            ),
          ),
        ],
      ),
    );
  }
}
