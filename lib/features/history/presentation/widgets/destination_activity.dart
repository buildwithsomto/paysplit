import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/destinations/data/models/destination_transaction.dart';
import 'package:paysplit/features/destinations/data/repositories/destinations_repository.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';
import 'package:paysplit/features/history/presentation/widgets/transaction_tile.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';

typedef DestinationKey = ({String id, bool beneficiary});

/// The latest transactions of one wallet or beneficiary. Refetched whenever
/// the destinations list reloads (after a move, split or edit).
final destinationRecentProvider = FutureProvider.autoDispose
    .family<List<DestinationTransaction>, DestinationKey>((ref, key) async {
      ref.watch(destinationsControllerProvider.select((s) => s.updatedAt));
      final repository = ref.watch(destinationsRepositoryProvider);
      final page = key.beneficiary
          ? await repository.beneficiaryTransactions(key.id, page: 1, limit: 5)
          : await repository.walletTransactions(key.id, page: 1, limit: 5);
      return page.items;
    });

class DestinationActivity extends ConsumerWidget {
  const DestinationActivity({
    required this.destinationId,
    required this.beneficiary,
    super.key,
  });
  final String destinationId;
  final bool beneficiary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (id: destinationId, beneficiary: beneficiary);
    final recent = ref.watch(destinationRecentProvider(key));
    final destinations = ref.watch(destinationsControllerProvider);
    final name = beneficiary
        ? destinations.beneficiary(destinationId)?.name
        : destinations.wallet(destinationId)?.name;
    final records = [
      for (final transaction
          in recent.value ?? const <DestinationTransaction>[])
        destinationRecord(
          transaction,
          beneficiary: beneficiary,
          destinationName: name ?? '',
          // On a beneficiary's own page the name is already the heading, so
          // each transfer is labelled by the rule that sent it.
          title: beneficiary ? transaction.narration : null,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                beneficiary ? 'Transfer History' : 'Recent Activity',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SeeAllLink(
              onPressed: () => context.push(
                '/activity/$destinationId?wallet=${!beneficiary}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(records.isEmpty ? 24 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: records.isNotEmpty
              ? TransactionMonthList(
                  records: records,
                  walletActivity: !beneficiary,
                )
              : recent.isLoading
              ? const SkeletonLoader(
                  label: 'Loading activity',
                  child: SkeletonRows(count: 3),
                )
              : recent.hasError
              ? Column(
                  spacing: 4,
                  children: [
                    const Text(
                      'Activity couldn’t be loaded.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(destinationRecentProvider(key)),
                      child: const Text('Retry'),
                    ),
                  ],
                )
              : Text(
                  beneficiary
                      ? 'Transfers to this beneficiary will appear here.'
                      : 'Allocations into this wallet will appear here.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.body,
                  ),
                ),
        ),
      ],
    );
  }
}

/// The "See all" link beside an activity heading.
class SeeAllLink extends StatelessWidget {
  const SeeAllLink({required this.onPressed, super.key});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: AppColors.action,
      minimumSize: const Size(48, 40),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    ),
    child: const Text('See all'),
  );
}
