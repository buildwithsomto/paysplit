import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/widgets/feedback/content_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';
import 'package:paysplit/features/history/presentation/widgets/transaction_tile.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({
    required this.id,
    this.receipt = false,
    super.key,
  });
  final String id;
  final bool receipt;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyControllerProvider);
    final record = state.records.where((r) => r.id == id).firstOrNull;
    final available = record != null && (!receipt || record.canViewReceipt);
    return AppPageLayout(
      title: receipt ? 'Receipt Preview' : 'Details',
      headerTop: 31,
      bodyGap: 17,
      onBack: () => context.canPop() ? context.pop() : context.go('/history'),
      child: !available
          ? const Text(
              'This transaction or receipt is unavailable. Return to history to select a record.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                if (state.phase != ContentPhase.ready)
                  ContentStatusCard(
                    phase: state.phase,
                    hasContent: true,
                    sample: state.sample,
                    updatedAt: state.updatedAt,
                  ),
                if (receipt)
                  const Text(
                    'SAMPLE — NOT PROOF OF PAYMENT',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            border: Border.all(color: const Color(0xFFE4E4E4)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            record.category,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            Money.format(record.amountMinor),
                            style: const TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              color: Color(0xFF171918),
                            ),
                          ),
                          TransactionStatusBadge(status: record.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 1,
                        child: SvgPicture.asset(
                          'assets/icons/history/6dde3.svg',
                          fit: BoxFit.fill,
                          excludeFromSemantics: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TransactionDetailRow(
                        label: 'Reference No',
                        value: record.reference,
                        onCopy: () async {
                          await Clipboard.setData(
                            ClipboardData(text: record.reference),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sample transaction reference copied.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TransactionDetailRow(
                        label: 'Recipient/Destination',
                        value: record.destination,
                      ),
                      const SizedBox(height: 16),
                      TransactionDetailRow(
                        label: 'Date & time',
                        value:
                            '${DateFormat('MMM d, y • h:mm a').format(record.time)}\nLocal time',
                      ),
                      const SizedBox(height: 16),
                      TransactionDetailRow(
                        label: 'Transaction Type',
                        value: record.kind.label,
                      ),
                      const SizedBox(height: 16),
                      TransactionDetailRow(
                        label: 'Source',
                        value: record.source,
                      ),
                      if (record.ruleName != null) ...[
                        const SizedBox(height: 16),
                        TransactionDetailRow(
                          label: 'Split Rule',
                          value: record.ruleName!,
                        ),
                      ],
                      if (record.providerReference != null) ...[
                        const SizedBox(height: 16),
                        TransactionDetailRow(
                          label: 'Provider Reference',
                          value: record.providerReference!,
                        ),
                      ],
                      const SizedBox(height: 16),
                      TransactionDetailRow(
                        label: 'Fee',
                        value: Money.format(record.feeMinor),
                      ),
                    ],
                  ),
                ),
                if (record.note != null)
                  Text(
                    record.note!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                if (state.sample)
                  const Text(
                    'Sample transaction',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xFF667085),
                    ),
                  ),
                if (!receipt && record.canViewReceipt)
                  AppButton(
                    label: 'View Receipt',
                    onPressed: () => context.push('/transactions/$id/receipt'),
                  ),
                if (!receipt && !record.canViewReceipt)
                  const Text(
                    'A receipt is available only for a supported successful transaction.',
                  ),
                if (receipt) ...[
                  const Row(
                    spacing: 16,
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Download PDF',
                          onPressed: null,
                        ),
                      ),
                      Expanded(
                        child: AppButton(
                          label: 'Share Receipt',
                          outlined: true,
                          onPressed: null,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Official receipt download and sharing will be available when transaction records are connected.',
                  ),
                ],
              ],
            ),
    );
  }
}

class TransactionDetailRow extends StatelessWidget {
  const TransactionDetailRow({
    required this.label,
    required this.value,
    this.onCopy,
    super.key,
  });
  final String label, value;
  final VoidCallback? onCopy;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: onCopy == null
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center,
    spacing: 12,
    children: [
      Expanded(
        flex: 2,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF737373),
          ),
        ),
      ),
      Expanded(
        flex: 3,
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontFamilyFallback: ['Inter'],
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF121212),
          ),
        ),
      ),
      if (onCopy != null)
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: 'Copy transaction reference',
            onPressed: onCopy,
            icon: const AppSvgIcon('assets/icons/history/4833d.svg', size: 16),
          ),
        ),
    ],
  );
}
