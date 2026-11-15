import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';

/// Stable historical snapshots, kept separate from newly created destinations.
void loadHistoryPreview(WidgetRef ref) {
  ref
      .read(historyControllerProvider.notifier)
      .loadPreview(historyPreviewRecords());
}

List<TransactionViewData> historyPreviewRecords() => [
  for (final month in [1, 12, 11, 10, 9, 8]) ...[
    TransactionViewData(
      id: 'salary-$month',
      reference: 'SAMPLE-SAL-$month-001',
      title: 'Salary from Talent Nation',
      kind: TransactionKind.salary,
      status: TransactionStatus.success,
      amountMinor: 85000000,
      time: DateTime(month == 1 ? 2026 : 2025, month, 21, 9),
      source: 'Talent Nation (sample)',
      destination: 'Salary account (sample)',
      category: 'Salary',
      providerReference: 'SAMPLE-PROVIDER-$month-001',
    ),
    TransactionViewData(
      id: 'wallet-$month',
      reference: 'SAMPLE-ALLOC-$month-002',
      title: 'Monthly Savings',
      kind: TransactionKind.walletAllocation,
      status: TransactionStatus.success,
      amountMinor: 20000000,
      time: DateTime(month == 1 ? 2026 : 2025, month, 21, 9, 2),
      source: 'Salary account (sample)',
      destination: 'Monthly Savings',
      destinationId: 'sample-savings',
      category: 'Savings',
      ruleName: 'Monthly Savings Rule',
    ),
    TransactionViewData(
      id: 'transfer-$month',
      reference: 'SAMPLE-PAY-$month-003',
      title: 'Family Support',
      kind: TransactionKind.beneficiaryTransfer,
      status: month == 1
          ? TransactionStatus.pending
          : TransactionStatus.success,
      amountMinor: 10000000,
      time: DateTime(month == 1 ? 2026 : 2025, month, 21, 9, 3),
      source: 'Salary account (sample)',
      destination: 'Demo Recipient · account ••••1234',
      destinationId: 'sample-family',
      category: 'Family',
      ruleName: 'Family Support Rule',
      providerReference: 'SAMPLE-PROVIDER-$month-003',
      note: month == 1
          ? 'The provider has not confirmed this sample transfer. Do not send it again.'
          : null,
    ),
    TransactionViewData(
      id: 'return-$month',
      reference: 'SAMPLE-RETURN-$month-004',
      title: 'Return from Monthly Savings',
      kind: TransactionKind.walletReturn,
      status: month == 1
          ? TransactionStatus.reversed
          : TransactionStatus.success,
      amountMinor: 2500000,
      time: DateTime(month == 1 ? 2026 : 2025, month, 22, 10),
      source: 'Monthly Savings',
      destination: 'Salary account (sample)',
      destinationId: 'sample-savings',
      category: 'Savings',
      note: month == 1
          ? 'This sample movement was reversed. Its record is retained for traceability.'
          : null,
    ),
  ],
  TransactionViewData(
    id: 'failed-jan',
    reference: 'SAMPLE-FAILED-005',
    title: 'Rent payment',
    kind: TransactionKind.beneficiaryTransfer,
    status: TransactionStatus.failed,
    amountMinor: 5000000,
    time: DateTime(2026, 1, 23, 10),
    source: 'Salary account (sample)',
    destination: 'Demo Landlord · account ••••5678',
    destinationId: 'sample-rent',
    category: 'Rent',
    note:
        'The sample bank rejected the transfer. No successful payment is recorded.',
  ),
  TransactionViewData(
    id: 'uncertain-jan',
    reference: 'SAMPLE-CHECK-006',
    title: 'Utility payment',
    kind: TransactionKind.beneficiaryTransfer,
    status: TransactionStatus.uncertain,
    amountMinor: 3500000,
    time: DateTime(2026, 1, 24, 10),
    source: 'Salary account (sample)',
    destination: 'Demo Utility · account ••••9012',
    destinationId: 'sample-utility',
    category: 'Bills',
    note:
        'Confirmation is delayed. Check the status before attempting another payment.',
  ),
];
