import 'package:paysplit/features/salary/presentation/controllers/salary_account_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Presentation fixtures, explicitly selected from the development gallery.
/// They never represent provisioned accounts or confirmed money movements.
@immutable
class DashboardState {
  const DashboardState({this.populated = false, this.balancesVisible = true});
  final bool populated;
  final bool balancesVisible;
  int get salaryReceived => populated ? 85000000 : 0;
  int get walletAllocation => populated ? 47750000 : 0;
  int get beneficiaryAllocation => populated ? 13500000 : 0;
  int get allocated => walletAllocation + beneficiaryAllocation;
  int get remainder => salaryReceived - allocated;
  int get remainderPercent =>
      salaryReceived == 0 ? 0 : (remainder * 100 / salaryReceived).round();
}

class DashboardController extends Notifier<DashboardState> {
  @override
  DashboardState build() => const DashboardState();

  void selectPreview({required bool populated}) {
    ref
        .read(salaryAccountProvider.notifier)
        .selectPreview(
          populated
              ? SalaryAccountStatus.ready
              : SalaryAccountStatus.notProvisioned,
        );
    state = DashboardState(
      populated: populated,
      balancesVisible: state.balancesVisible,
    );
  }

  void toggleBalances() => state = DashboardState(
    populated: state.populated,
    balancesVisible: !state.balancesVisible,
  );
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );
