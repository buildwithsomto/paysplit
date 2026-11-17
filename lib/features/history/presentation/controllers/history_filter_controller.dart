import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/history/data/models/transaction.dart';
import 'package:paysplit/features/history/data/repositories/history_repository.dart';

export 'package:paysplit/features/history/data/repositories/history_repository.dart'
    show HistoryTab, MoneyDirection;

typedef HistoryDateRange = ({DateTime start, DateTime end});

/// The filters the transactions API supports: a tab, a direction, one
/// status, a date range and a search term.
@immutable
class HistoryFilterState {
  const HistoryFilterState({
    this.query = '',
    this.tab = HistoryTab.all,
    this.direction = MoneyDirection.all,
    this.status,
    this.range,
  });
  final String query;
  final HistoryTab tab;
  final MoneyDirection direction;
  final TransactionStatus? status;
  final HistoryDateRange? range;

  /// A filter chosen in the filter sheet is active.
  bool get hasAdvanced =>
      status != null || range != null || direction != MoneyDirection.all;

  /// Anything narrows the list, so an empty result is "no matches".
  bool get isActive =>
      hasAdvanced || query.trim().isNotEmpty || tab != HistoryTab.all;

  HistoryFilterState copyWith({
    String? query,
    HistoryTab? tab,
    MoneyDirection? direction,
    TransactionStatus? status,
    bool clearStatus = false,
    HistoryDateRange? range,
    bool clearRange = false,
  }) => HistoryFilterState(
    query: query ?? this.query,
    tab: tab ?? this.tab,
    direction: direction ?? this.direction,
    status: clearStatus ? null : status ?? this.status,
    range: clearRange ? null : range ?? this.range,
  );
}

class HistoryFilterController extends Notifier<HistoryFilterState> {
  @override
  HistoryFilterState build() => const HistoryFilterState();
  void search(String query) => state = state.copyWith(query: query);
  void selectTab(HistoryTab tab) => state = state.copyWith(tab: tab);
  void selectDirection(MoneyDirection direction) =>
      state = state.copyWith(direction: direction);
  void apply(HistoryFilterState filter) => state = filter;
  void clear() => state = const HistoryFilterState();
}

final historyFilterProvider =
    NotifierProvider<HistoryFilterController, HistoryFilterState>(
      HistoryFilterController.new,
    );
