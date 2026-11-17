import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/core/session/ledger_version.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/features/rules/data/models/split_rule.dart';
import 'package:paysplit/features/rules/data/repositories/rules_repository.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/features/salary/presentation/controllers/salary_account_controller.dart';

export 'package:paysplit/features/rules/data/models/split_rule.dart'
    show SplitExecution, SplitLine, SplitOutcome, SplitRunStatus;

@immutable
class SplitExecutionState {
  const SplitExecutionState({
    this.executions = const [],
    this.phase = ContentPhase.loading,
    this.message,
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreError,
    this.running = false,
    this.error,
    this.errorCode,
  });

  /// Split history, newest first.
  final List<SplitExecution> executions;
  final ContentPhase phase;

  /// The API's explanation of the last failed history load.
  final String? message;
  final int page;
  final bool hasMore, loadingMore;

  /// Why the last "Load more" brought nothing.
  final String? loadMoreError;

  /// A Run Now request is in flight.
  final bool running;

  /// Why the last Run Now did not complete, with the server's code.
  final String? error, errorCode;

  bool get hasData => page > 0;

  SplitExecutionState copyWith({
    List<SplitExecution>? executions,
    ContentPhase? phase,
    String? message,
    bool clearMessage = false,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    bool? running,
    String? error,
    String? errorCode,
    bool clearError = false,
  }) => SplitExecutionState(
    executions: List.unmodifiable(executions ?? this.executions),
    phase: phase ?? this.phase,
    message: clearMessage ? null : message ?? this.message,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: clearLoadMoreError
        ? null
        : loadMoreError ?? this.loadMoreError,
    running: running ?? this.running,
    error: clearError ? null : error ?? this.error,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
  );
}

/// A reason the split cannot run right now, with a link label and the route
/// of the screen that resolves it, when there is one.
typedef SplitBlock = ({String message, (String, String)? action});

/// What Run Now is expected to do, shown before the user confirms.
@immutable
class SplitReview {
  const SplitReview({
    required this.availableMinor,
    required this.lines,
    required this.blocks,
    this.balanceKnown = true,
  });

  /// False when the salary account balance has not loaded, so
  /// [availableMinor] is a placeholder and there is nothing to estimate.
  final bool balanceKnown;

  /// The salary account balance the run would share out.
  final int availableMinor;

  /// One line per active rule, in the order the server runs them.
  final List<SplitLine> lines;

  /// Reasons the split cannot run right now.
  final List<SplitBlock> blocks;

  bool get canRun => blocks.isEmpty && lines.isNotEmpty;

  /// Kobo the estimate allocates.
  int get allocatedMinor => lines
      .where((line) => line.outcome != SplitOutcome.skipped)
      .fold(0, (sum, line) => sum + line.requestedMinor);
}

/// An estimate of a run over [availableMinor]: rules run by priority,
/// percentages apply to the balance being split, and a rule that does not
/// fit is skipped. The server's result is authoritative.
List<SplitLine> estimateSplit(
  List<SplitRule> rules,
  DestinationsState destinations,
  int availableMinor,
) {
  final active = rules.where((r) => r.status == RuleStatus.active).toList()
    ..sort(SplitRule.byPriority);
  var remaining = availableMinor;
  final lines = <SplitLine>[];
  for (final rule in active) {
    final requested = rule.requestedMinor(availableMinor);
    final skipped = requested > remaining || requested <= 0;
    if (!skipped) remaining -= requested;
    lines.add(
      SplitLine(
        name: rule.name,
        destination: ruleDestinationName(rule, destinations),
        priority: rule.priority,
        requestedMinor: requested,
        outcome: skipped ? SplitOutcome.skipped : SplitOutcome.pending,
        reason: skipped ? SplitLine.insufficientFunds : null,
      ),
    );
  }
  return List.unmodifiable(lines);
}

/// Run Now and split history, backed by `/split-runs`.
class SplitExecutionController extends Notifier<SplitExecutionState> {
  int _generation = 0;

  RulesRepository get _repository => ref.read(rulesRepositoryProvider);

  @override
  SplitExecutionState build() {
    final userId = ref.watch(sessionUserIdProvider);
    final generation = ++_generation;
    ref.listen(ledgerVersionProvider, (_, _) => load());
    ref.onDispose(() => _generation++);
    if (userId == null) {
      return const SplitExecutionState(phase: ContentPhase.ready);
    }
    Future.microtask(() {
      if (ref.mounted && generation == _generation) load();
    });
    return const SplitExecutionState();
  }

  /// First load, pull-to-refresh and Retry of the history.
  Future<void> load() async {
    final generation = _generation;
    state = state.copyWith(
      phase: state.hasData ? ContentPhase.refreshing : ContentPhase.loading,
    );
    try {
      final result = await _repository.runs(page: 1);
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        executions: result.items,
        phase: ContentPhase.ready,
        clearMessage: true,
        page: 1,
        hasMore: result.hasNextPage,
        clearLoadMoreError: true,
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        phase: ContentPhase.failure(error),
        message: describeError(error),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || !state.hasData) return;
    final generation = _generation;
    state = state.copyWith(loadingMore: true, clearLoadMoreError: true);
    try {
      final result = await _repository.runs(page: state.page + 1);
      if (!ref.mounted || generation != _generation) return;
      final known = {for (final run in state.executions) run.id};
      state = state.copyWith(
        executions: [
          ...state.executions,
          ...result.items.where((run) => !known.contains(run.id)),
        ],
        page: result.page,
        hasMore: result.hasNextPage,
        loadingMore: false,
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        loadingMore: false,
        loadMoreError: describeError(error),
      );
    }
  }

  /// Forgets why the last Run Now did not complete, when the screen reopens.
  void clearError() {
    if (state.error != null) state = state.copyWith(clearError: true);
  }

  /// Runs the split. Returns the run's id, or null when it did not complete;
  /// [SplitExecutionState.error] then says why. A request whose answer never
  /// arrived is never sent again: history is reloaded so the user can see
  /// whether it went through.
  Future<String?> runNow() async {
    if (state.running) return null;
    final generation = _generation;
    state = state.copyWith(running: true, clearError: true);
    try {
      final run = await _repository.run();
      if (!ref.mounted || generation != _generation) return run.id;
      state = state.copyWith(
        running: false,
        executions: [run, ...state.executions.where((r) => r.id != run.id)],
      );
      ref.read(ledgerVersionProvider.notifier).moved();
      return run.id;
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return null;
      state = state.copyWith(
        running: false,
        error: describeError(error),
        errorCode: error is ApiException ? error.code : null,
      );
      // The split may have run: reload so the user can see whether it did.
      if (error is ApiException && error.isConnectivity) {
        ref.read(ledgerVersionProvider.notifier).moved();
      }
      return null;
    }
  }
}

final splitExecutionProvider =
    NotifierProvider<SplitExecutionController, SplitExecutionState>(
      SplitExecutionController.new,
    );

/// One run with its lines; the list only carries summaries.
final splitRunDetailProvider = FutureProvider.autoDispose
    .family<SplitExecution, String>(
      (ref, id) => ref.watch(rulesRepositoryProvider).runDetail(id),
    );

final splitReviewProvider = Provider<SplitReview>((ref) {
  final rules = ref.watch(rulesControllerProvider);
  final destinations = ref.watch(destinationsControllerProvider);
  final onboarding = ref.watch(onboardingProvider);
  // The dashboard carries the same account, so a balance is still known
  // when the account screen's own request has not gone through.
  final account =
      ref.watch(salaryAccountProvider).account ??
      ref.watch(
        dashboardControllerProvider.select((s) => s.summary?.salaryAccount),
      );
  final available = account?.balance ?? 0;
  final active = rules.where((r) => r.status == RuleStatus.active);
  const accountDetails = ('View Account Details', '/salary-account');
  return SplitReview(
    availableMinor: available,
    balanceKnown: account != null,
    // An unknown balance is not an empty one: no estimate is made from it.
    lines: account == null
        ? const []
        : estimateSplit(rules, destinations, available),
    blocks: List.unmodifiable(<SplitBlock>[
      if (account == null)
        (
          message:
              'Your salary account balance couldn’t be loaded. Check your connection and try again.',
          action: accountDetails,
        ),
      if (!onboarding.kycApproved)
        (
          message: 'Verify your identity before running a split.',
          action: ('Complete verification', '/kyc/result'),
        ),
      if (onboarding.kycApproved && account != null && !account.isActive)
        (
          message: 'Your salary account isn’t active yet.',
          action: accountDetails,
        ),
      if (active.isEmpty)
        (message: 'You have no active split rules.', action: null),
      if (active.isNotEmpty && account != null && available <= 0)
        (
          message: 'There’s no money in your salary account to split.',
          action: accountDetails,
        ),
    ]),
  );
});
