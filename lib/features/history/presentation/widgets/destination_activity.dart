import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';
import 'package:paysplit/features/history/presentation/widgets/transaction_tile.dart';

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
    final records = ref
        .watch(historyControllerProvider)
        .records
        .where((r) => r.destinationId == destinationId)
        .take(3)
        .toList();
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
            TextButton(
              onPressed: () => context.push(
                '/activity/$destinationId?wallet=${!beneficiary}',
              ),
              child: const Text('See All'),
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
          child: records.isEmpty
              ? const Text(
                  'No transactions yet. Confirmed salary allocations will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF696969),
                  ),
                )
              : Column(
                  children: [
                    for (final record in records)
                      TransactionTile(
                        record: record,
                        walletActivity: !beneficiary,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
