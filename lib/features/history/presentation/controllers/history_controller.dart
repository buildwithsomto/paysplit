import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/network/json.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/core/session/ledger_version.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/destinations/data/repositories/destinations_repository.dart';
import 'package:paysplit/features/history/data/models/transaction.dart';
import 'package:paysplit/features/history/data/repositories/history_repository.dart';
import 'package:paysplit/features/history/presentation/controllers/history_filter_controller.dart';

export 'package:paysplit/features/history/data/models/transaction.dart';

/// Limits a history list to one wallet, one beneficiary, or (with
/// [allWallets]) the activity of every wallet.
typedef HistoryScope = ({String destinationId, bool walletActivity});

@immutable
class HistoryState {
  const HistoryState({
    this.records = const [],
    this.phase = ContentPhase.loading,
    this.updatedAt,
    this.retryFailed = false,
    this.message,
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
  });
  final List<Transaction> records;
  final ContentPhase phase;

  /// When [records] were last confirmed with the server.
  final DateTime? updatedAt;

  /// The most recent Retry also failed.
  final bool retryFailed;

  /// The API's explanation of the last failed load.
  final String? message;
  final int page;
  final bool hasMore, loadingMore;

  bool get hasData => updatedAt != null;

  HistoryState copyWith({
    List<Transaction>? records,
    ContentPhase? phase,
    DateTime? updatedAt,
    bool? retryFailed,
    String? message,
    int? page,
    bool? hasMore,
    bool? loadingMore,
  }) => HistoryState(
    records: List.unmodifiable(records ?? this.records),
    phase: phase ?? this.phase,
    updatedAt: updatedAt ?? this.updatedAt,
    retryFailed: retryFailed ?? this.retryFailed,
    message: message ?? this.message,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// Transaction history, filtered and paged by the server.
///
/// When a refresh fails, the records already on screen stay there and only
/// the phase changes, so history remains readable offline.
class HistoryController extends Notifier<HistoryState> {
  HistoryController({this.scope});

  /// The id that means "every wallet" in a wallet-activity scope.
  static const allWallets = 'all';
  static const _pageSize = 20;

  final HistoryScope? scope;
  int _generation = 0;
  int _request = 0;
  Timer? _debounce;

  @override
  HistoryState build() {
    final userId = ref.watch(sessionUserIdProvider);
    final generation = ++_generation;
    ref.listen(ledgerVersionProvider, (_, _) => load());
    ref.onDispose(() {
      _generation++;
      _debounce?.cancel();
    });
    // Tabs and filters refetch at once; typing waits for a pause.
    ref.listen(historyFilterProvider, (previous, next) {
      if (previous == null || !_changed(previous, next)) return;
      _debounce?.cancel();
      if (previous.query != next.query) {
        _debounce = Timer(const Duration(milliseconds: 350), load);
      } else {
        load();
      }
    });
    if (userId == null) return const HistoryState(phase: ContentPhase.ready);
    Future.microtask(() {
      if (ref.mounted && generation == _generation) load();
    });
    return const HistoryState();
  }

  static bool _changed(HistoryFilterState a, HistoryFilterState b) =>
      a.query.trim() != b.query.trim() ||
      a.tab != b.tab ||
      a.direction != b.direction ||
      a.status != b.status ||
      a.range != b.range;

  /// The server filters for what is on screen; also used by the export.
  TransactionQuery get query {
    final filter = ref.read(historyFilterProvider);
    return TransactionQuery(
      type: filter.tab,
      direction: filter.direction,
      status: filter.status,
      search: filter.query,
      from: filter.range?.start,
      to: filter.range?.end,
    );
  }

  Future<ApiPage<Transaction>> _fetch(int page) async {
    final scope = this.scope;
    if (scope == null) {
      return ref
          .read(historyRepositoryProvider)
          .transactions(query, page: page, limit: _pageSize);
    }
    final filter = ref.read(historyFilterProvider);
    final search = filter.query.trim();
    final destinations = ref.read(destinationsRepositoryProvider);
    final result = !scope.walletActivity
        ? await destinations.beneficiaryTransactions(
            scope.destinationId,
            page: page,
            limit: _pageSize,
            search: search,
          )
        : scope.destinationId == allWallets
        ? await destinations.walletActivity(
            page: page,
            limit: _pageSize,
            direction: filter.direction.apiValue,
            search: search,
          )
        : await destinations.walletTransactions(
            scope.destinationId,
            page: page,
            limit: _pageSize,
            filter: switch (filter.direction) {
              MoneyDirection.all => 'all',
              MoneyDirection.incoming => 'allocated',
              MoneyDirection.outgoing => 'moved',
            },
            search: search,
          );
    return ApiPage(
      items: [
        for (final item in result.items)
          destinationRecord(
            item,
            beneficiary: !scope.walletActivity,
            destinationName: '',
          ),
      ],
      page: result.page,
      limit: result.limit,
      total: result.total,
      pages: result.pages,
    );
  }

  /// First load, pull-to-refresh and a changed filter.
  Future<void> load() => _load(retry: false);

  /// The Retry action on the offline or error notice.
  Future<void> retry() => _load(retry: true);

  Future<void> _load({required bool retry}) async {
    if (ref.read(sessionUserIdProvider) == null) return;
    final generation = _generation;
    final request = ++_request;
    state = state.copyWith(
      phase: state.hasData ? ContentPhase.refreshing : ContentPhase.loading,
      retryFailed: false,
      loadingMore: false,
    );
    try {
      final result = await _fetch(1);
      if (!ref.mounted || generation != _generation || request != _request) {
        return;
      }
      state = HistoryState(
        records: List.unmodifiable(result.items),
        phase: ContentPhase.ready,
        updatedAt: DateTime.now(),
        page: 1,
        hasMore: result.hasNextPage,
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation || request != _request) {
        return;
      }
      // What was loaded stays visible; it is only marked as possibly stale.
      state = state.copyWith(
        phase: ContentPhase.failure(error),
        message: describeError(error),
        retryFailed: retry,
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.phase.isBusy) return;
    final generation = _generation;
    final request = _request;
    state = state.copyWith(loadingMore: true);
    try {
      final result = await _fetch(state.page + 1);
      if (!ref.mounted || generation != _generation || request != _request) {
        return;
      }
      final known = {for (final record in state.records) record.id};
      state = state.copyWith(
        records: [
          ...state.records,
          ...result.items.where((record) => !known.contains(record.id)),
        ],
        page: result.page,
        hasMore: result.hasNextPage,
        loadingMore: false,
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation || request != _request) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        phase: ContentPhase.failure(error),
        message: describeError(error),
      );
    }
  }
}

final historyControllerProvider =
    NotifierProvider<HistoryController, HistoryState>(HistoryController.new);

/// One transaction for the detail and receipt screens, from
/// `GET /transactions/{id}`.
final transactionDetailProvider = FutureProvider.autoDispose
    .family<Transaction, String>(
      (ref, id) => ref.watch(historyRepositoryProvider).transaction(id),
    );
