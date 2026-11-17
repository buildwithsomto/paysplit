import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/core/constants/app_assets.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/features/history/data/repositories/history_repository.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';
import 'package:paysplit/features/history/presentation/widgets/transaction_tile.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';
import 'package:share_plus/share_plus.dart';

/// A transaction's details, or (with [receipt]) its shareable receipt.
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({
    required this.id,
    this.receipt = false,
    super.key,
  });
  final String id;
  final bool receipt;

  static String _timestamp(DateTime time) =>
      DateFormat("MMM d, y 'at' hh:mm a").format(time);

  static String _destinationType(Transaction record) => switch (record.kind) {
    TransactionKind.walletAllocation => 'Wallet',
    TransactionKind.beneficiaryTransfer => 'Beneficiary',
    TransactionKind.salary || TransactionKind.walletReturn => 'Salary account',
  };

  Future<void> _share(BuildContext context, Transaction record) async {
    final lines = [
      'PaySplit receipt',
      '${record.title} · ${record.status.label}',
      'Amount: ${Money.format(record.amountMinor)}',
      if (record.feeMinor > 0) 'Fee: ${Money.format(record.feeMinor)}',
      if (record.destination.isNotEmpty) 'To: ${record.destination}',
      'From: ${record.source}',
      'Date: ${_timestamp(record.time)}',
      'Reference: ${record.reference}',
    ];
    try {
      await SharePlus.instance.share(
        ShareParams(text: lines.join('\n'), subject: 'PaySplit receipt'),
      );
    } on Object {
      if (context.mounted) {
        showAppNotice(context, 'The receipt couldn’t be shared. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(transactionDetailProvider(id));
    // A row already on screen shows at once while the full record loads.
    final listed =
        ref
            .watch(historyControllerProvider)
            .records
            .where((r) => r.id == id)
            .firstOrNull ??
        ref
            .watch(recentTransactionsProvider)
            .value
            ?.where((r) => r.id == id)
            .firstOrNull;
    final record = detail.value ?? listed;
    return AppPageLayout(
      title: receipt ? 'Receipt' : 'Details',
      headerTop: 31,
      bodyGap: 17,
      onBack: () => context.canPop() ? context.pop() : context.go('/history'),
      bottom: record == null
          ? null
          : receipt
          ? AppButton(
              label: 'Share Receipt',
              onPressed: () => _share(context, record),
            )
          : record.canViewReceipt
          ? AppButton(
              label: 'View Receipt',
              onPressed: () => context.push('/transactions/$id/receipt'),
            )
          : null,
      child: record == null
          ? detail.isLoading
                ? const SkeletonLoader(
                    label: 'Loading transaction',
                    child: SkeletonDetail(),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      Text(
                        describeError(
                          detail.error ?? ApiException.invalidResponse,
                          fallback: 'This transaction couldn’t be loaded.',
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () =>
                              ref.invalidate(transactionDetailProvider(id)),
                          child: const Text('Try again'),
                        ),
                      ),
                    ],
                  )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (receipt) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const AppSvgIcon(AppAssets.logo, size: 28),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            'Transaction Receipt',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF737373),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              border: Border.all(
                                color: const Color(0xFFE4E4E4),
                              ),
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
                      ],
                      Wrap(
                        alignment: receipt
                            ? WrapAlignment.center
                            : WrapAlignment.start,
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
                        label: 'Settlement Reference',
                        value: record.reference,
                        onCopy: () async {
                          await Clipboard.setData(
                            ClipboardData(text: record.reference),
                          );
                          if (context.mounted) {
                            showAppNotice(context, 'Reference copied.');
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (record.destination.isNotEmpty) ...[
                        TransactionDetailRow(
                          label: 'Recipient/Destination',
                          value: record.destination,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (record.bankName case final bank?) ...[
                        TransactionDetailRow(
                          label: 'Bank',
                          value: [
                            bank,
                            ?record.maskedAccountNumber,
                          ].join(' · '),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TransactionDetailRow(
                        label: 'Time Stamp',
                        value: _timestamp(record.time),
                      ),
                      const SizedBox(height: 16),
                      TransactionDetailRow(
                        label: 'Destination Type',
                        value: _destinationType(record),
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
                      if (record.feeMinor > 0) ...[
                        const SizedBox(height: 16),
                        TransactionDetailRow(
                          label: 'Fee',
                          value: Money.format(record.feeMinor),
                        ),
                      ],
                      if ((record.note ?? '').isNotEmpty) ...[
                        const SizedBox(height: 16),
                        TransactionDetailRow(
                          label: 'Narration',
                          value: record.note!,
                        ),
                      ],
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                if (!receipt && record.status == TransactionStatus.failed)
                  const Text(
                    'This transaction didn’t go through. No money left your account for it.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                if (!receipt && record.status == TransactionStatus.pending)
                  const Text(
                    'This transaction is still processing. You’ll be notified when it completes.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
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
