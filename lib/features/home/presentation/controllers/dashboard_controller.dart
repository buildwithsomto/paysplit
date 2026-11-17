import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/core/session/ledger_version.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/features/home/data/models/cash_flow.dart';
import 'package:paysplit/features/home/data/models/dashboard_summary.dart';
import 'package:paysplit/features/home/data/repositories/dashboard_repository.dart';

export 'package:paysplit/features/home/data/models/cash_flow.dart';
export 'package:paysplit/features/home/data/models/dashboard_summary.dart';

/// The periods offered by the cash-flow chart's range control.
enum CashFlowRange {
  last30Days('Last 30 days'),
  last3Months('Last 3 months'),
  last6Months('Last 6 months');

  const CashFlowRange(this.label);
  final String label;

  /// The first day to request.
  DateTime startingFrom(DateTime today) => switch (this) {
    last30Days => DateTime(today.year, today.month, today.day - 29),
    last3Months => DateTime(today.year, today.month - 2),
    last6Months => DateTime(today.year, today.month - 5),
  };
}

@immutable
class DashboardState {
  const DashboardState({
    this.phase = ContentPhase.loading,
    this.summary,
    this.cashFlow,
    this.cashFlowRange = CashFlowRange.last6Months,
    this.cashFlowBusy = false,
    this.cashFlowFailed = false,
    this.balancesVisible = true,
    this.message,
    this.updatedAt,
  });

  final ContentPhase phase;

  /// Null until the first successful load.
  final DashboardSummary? summary;
  final CashFlow? cashFlow;
  final CashFlowRange cashFlowRange;

  /// A different chart range is being fetched.
  final bool cashFlowBusy;

  /// The chart could not be loaded even though the summary may have been.
  final bool cashFlowFailed;
  final bool balancesVisible;

  /// The API's explanation of the last failed load.
  final String? message;
  final DateTime? updatedAt;

  bool get hasData => summary != null;
  int get unreadNotifications => summary?.unreadNotifications ?? 0;

  DashboardState copyWith({
    ContentPhase? phase,
    DashboardSummary? summary,
    CashFlow? cashFlow,
    CashFlowRange? cashFlowRange,
    bool? cashFlowBusy,
    bool? cashFlowFailed,
    bool? balancesVisible,
    String? message,
    bool clearMessage = false,
    DateTime? updatedAt,
  }) => DashboardState(
    phase: phase ?? this.phase,
    summary: summary ?? this.summary,
    cashFlow: cashFlow ?? this.cashFlow,
    cashFlowRange: cashFlowRange ?? this.cashFlowRange,
    cashFlowBusy: cashFlowBusy ?? this.cashFlowBusy,
    cashFlowFailed: cashFlowFailed ?? this.cashFlowFailed,
    balancesVisible: balancesVisible ?? this.balancesVisible,
    message: clearMessage ? null : message ?? this.message,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// The home dashboard, backed by `/dashboard/summary` and
/// `/dashboard/cash-flow`.
class DashboardController extends Notifier<DashboardState> {
  int _generation = 0;

  DashboardRepository get _repository => ref.read(dashboardRepositoryProvider);

  @override
  DashboardState build() {
    final userId = ref.watch(sessionUserIdProvider);
    final generation = ++_generation;
    ref.listen(ledgerVersionProvider, (_, _) => load());
    ref.onDispose(() => _generation++);
    if (userId == null) return const DashboardState(phase: ContentPhase.ready);
    Future.microtask(() {
      if (ref.mounted && generation == _generation) load();
    });
    return const DashboardState();
  }

  /// First load, pull-to-refresh and Retry.
  Future<void> load() async {
    if (ref.read(sessionUserIdProvider) == null) return;
    final generation = _generation;
    final range = state.cashFlowRange;
    state = state.copyWith(
      phase: state.hasData ? ContentPhase.refreshing : ContentPhase.loading,
    );
    // The chart is secondary: it is fetched alongside the summary, and its
    // failure never hides the balances.
    final chartRequest = _fetchCashFlow(range);
    DashboardSummary? summary;
    Object? failure;
    try {
      summary = await _repository.summary();
    } on Object catch (error) {
      failure = error;
    }
    final cashFlow = await chartRequest;
    if (!ref.mounted || generation != _generation) return;
    final sameRange = state.cashFlowRange == range;
    final chart = sameRange ? cashFlow : null;
    if (summary == null) {
      // Keep the last loaded balances on screen; only the phase changes.
      state = state.copyWith(
        phase: ContentPhase.failure(failure!),
        message: describeError(failure),
        cashFlow: chart,
        cashFlowFailed: sameRange ? cashFlow == null : null,
      );
      return;
    }
    state = state.copyWith(
      phase: ContentPhase.ready,
      summary: summary,
      cashFlow: chart,
      cashFlowFailed: sameRange ? cashFlow == null : null,
      clearMessage: true,
      updatedAt: DateTime.now(),
    );
    // Opening the app with no connection leaves the profile unloaded. The
    // first refresh that gets through fetches it, so the greeting and the
    // setup card recover along with the balances.
    final account = ref.read(accountControllerProvider);
    if (account.user == null && !account.phase.isBusy) {
      await ref.read(accountControllerProvider.notifier).load();
      if (!ref.mounted || generation != _generation) return;
    }
    ref
        .read(accountControllerProvider.notifier)
        .apply(onboarding: summary.onboarding);
  }

  /// Switches the chart to [range]. Returns false, leaving the current chart
  /// and range in place, when that period could not be loaded.
  Future<bool> selectCashFlowRange(CashFlowRange range) async {
    if (state.cashFlowBusy) return true;
    if (range == state.cashFlowRange && state.cashFlow != null) return true;
    final generation = _generation;
    state = state.copyWith(cashFlowBusy: true);
    final cashFlow = await _fetchCashFlow(range);
    if (!ref.mounted || generation != _generation) return true;
    state = state.copyWith(
      cashFlow: cashFlow,
      cashFlowRange: cashFlow == null ? null : range,
      cashFlowBusy: false,
      cashFlowFailed: cashFlow == null && state.cashFlow == null,
    );
    return cashFlow != null;
  }

  void toggleBalances() =>
      state = state.copyWith(balancesVisible: !state.balancesVisible);

  /// Keeps the bell badge in step with the notification feed, which reports
  /// a fresher count every time it loads or marks something as read.
  void setUnreadNotifications(int count) {
    final summary = state.summary;
    if (summary == null || summary.unreadNotifications == count) return;
    state = state.copyWith(summary: summary.withUnreadNotifications(count));
  }

  /// Null when the chart could not be loaded. Never throws.
  Future<CashFlow?> _fetchCashFlow(CashFlowRange range) async {
    try {
      return await _repository.cashFlow(
        from: range.startingFrom(DateTime.now()),
      );
    } on Object {
      return null;
    }
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );
