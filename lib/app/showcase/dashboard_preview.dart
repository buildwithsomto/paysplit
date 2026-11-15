import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';

/// One coherent salary cycle for dashboard review. The separate History
/// gallery entry exercises pagination and additional transaction outcomes.
void loadDashboardPreview(WidgetRef ref, {required bool populated}) {
  ref
      .read(dashboardControllerProvider.notifier)
      .selectPreview(populated: populated);
  final history = ref.read(historyControllerProvider.notifier);
  if (!populated) {
    history.clearPreview();
    return;
  }
  final dashboard = ref.read(dashboardControllerProvider);
  const salaryAccount = 'Salary account (sample)';
  history.loadPreview([
    TransactionViewData(
      id: 'dashboard-salary',
      reference: 'SAMPLE-OCT-SALARY',
      title: 'Salary received',
      kind: TransactionKind.salary,
      status: TransactionStatus.success,
      amountMinor: dashboard.salaryReceived,
      time: DateTime(2026, 10, 25, 9),
      source: 'Sample employer',
      destination: salaryAccount,
      category: 'Salary',
    ),
    TransactionViewData(
      id: 'dashboard-wallet',
      reference: 'SAMPLE-OCT-WALLET',
      title: 'Monthly Savings',
      kind: TransactionKind.walletAllocation,
      status: TransactionStatus.success,
      amountMinor: dashboard.walletAllocation,
      time: DateTime(2026, 10, 25, 9, 1),
      source: salaryAccount,
      destination: 'Monthly Savings (sample)',
      category: 'Savings',
    ),
    TransactionViewData(
      id: 'dashboard-beneficiary',
      reference: 'SAMPLE-OCT-TRANSFER',
      title: 'Family Support',
      kind: TransactionKind.beneficiaryTransfer,
      status: TransactionStatus.success,
      amountMinor: dashboard.beneficiaryAllocation,
      time: DateTime(2026, 10, 25, 9, 2),
      source: salaryAccount,
      destination: 'Sample recipient · account ••••1234',
      category: 'Family',
    ),
  ]);
}
