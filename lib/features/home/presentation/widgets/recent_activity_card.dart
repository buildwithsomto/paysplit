import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/history/data/models/transaction.dart';
import 'package:paysplit/features/history/data/repositories/history_repository.dart';
import 'package:paysplit/features/history/presentation/widgets/transaction_tile.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/features/home/presentation/widgets/dashboard_card.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';

/// "Recent Activity & Splits": the latest transactions, opening the same
/// detail screens as History.
class RecentActivityCard extends ConsumerWidget {
  const RecentActivityCard({required this.showAmounts, super.key});

  final bool showAmounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Refetched whenever the dashboard reloads.
    ref.listen(dashboardControllerProvider.select((s) => s.updatedAt), (
      previous,
      next,
    ) {
      if (previous != null) ref.invalidate(recentTransactionsProvider);
    });
    final recent = ref.watch(recentTransactionsProvider);
    // A failed refresh keeps the rows that were already loaded.
    final records = recent.value ?? const <Transaction>[];
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: const Text(
                    'Recent Activity & Splits',
                    style: TextStyle(fontSize: 18, color: Color(0xFF171918)),
                  ),
                ),
              ),
              InkWell(
                onTap: () => context.go('/history'),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 12,
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.action,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.action,
                        ),
                      ),
                      AppSvgIcon('assets/icons/dashboard/9c184.svg', size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: recent.isLoading && !recent.hasValue
                  ? const SkeletonLoader(
                      label: 'Loading recent activity',
                      child: SkeletonRows(count: 3),
                    )
                  : Text(
                      recent.hasError
                          ? 'Recent activity couldn’t be loaded. Pull down to refresh.'
                          : 'Salary deposits and splits will appear here.',
                      textAlign: TextAlign.center,
                    ),
            ),
          for (final record in records)
            TransactionTile(record: record, showAmount: showAmounts),
        ],
      ),
    );
  }
}
