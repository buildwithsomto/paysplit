import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';

enum HistoryTab { all, wallets, transfers }

enum MoneyDirection { all, incoming, outgoing }

typedef HistoryDateRange = ({DateTime start, DateTime end});

@immutable
class HistoryFilterState {
  const HistoryFilterState({
    this.query = '',
    this.tab = HistoryTab.all,
    this.direction = MoneyDirection.all,
    this.statuses = const {},
    this.kinds = const {},
    this.destinations = const {},
    this.range,
    this.visibleCount = 20,
  });
  final String query;
  final HistoryTab tab;
  final MoneyDirection direction;
  final Set<TransactionStatus> statuses;
  final Set<TransactionKind> kinds;
  final Set<String> destinations;
  final HistoryDateRange? range;
  final int visibleCount;
  bool get hasAdvanced =>
      statuses.isNotEmpty ||
      kinds.isNotEmpty ||
      destinations.isNotEmpty ||
      range != null;
  HistoryFilterState copyWith({
    String? query,
    HistoryTab? tab,
    MoneyDirection? direction,
    Set<TransactionStatus>? statuses,
    Set<TransactionKind>? kinds,
    Set<String>? destinations,
    HistoryDateRange? range,
    bool clearRange = false,
    int? visibleCount,
  }) => HistoryFilterState(
    query: query ?? this.query,
    tab: tab ?? this.tab,
    direction: direction ?? this.direction,
    statuses: Set.unmodifiable(statuses ?? this.statuses),
    kinds: Set.unmodifiable(kinds ?? this.kinds),
    destinations: Set.unmodifiable(destinations ?? this.destinations),
    range: clearRange ? null : range ?? this.range,
    visibleCount: visibleCount ?? 20,
  );
}

class HistoryFilterController extends Notifier<HistoryFilterState> {
  @override
  HistoryFilterState build() => const HistoryFilterState();
  void search(String query) => state = state.copyWith(query: query);
  void selectTab(HistoryTab tab) => state = state.copyWith(tab: tab);
  void selectDirection(MoneyDirection direction) =>
      state = state.copyWith(direction: direction);
  void apply(HistoryFilterState filter) => state = filter.copyWith();
  void restoreView(HistoryFilterState filter) => state = filter;
  void clear() => state = const HistoryFilterState();
  void loadMore() =>
      state = state.copyWith(visibleCount: state.visibleCount + 20);
}

final historyFilterProvider =
    NotifierProvider<HistoryFilterController, HistoryFilterState>(
      HistoryFilterController.new,
    );

List<TransactionViewData> filterHistory(
  Iterable<TransactionViewData> records,
  HistoryFilterState filter, {
  String? destinationId,
  bool walletActivity = false,
}) {
  final query = filter.query.trim().toLowerCase();
  return List.unmodifiable(
    records.where((record) {
      if (destinationId != null && record.destinationId != destinationId) {
        return false;
      }
      if (filter.tab == HistoryTab.wallets && !record.kind.isWallet) {
        return false;
      }
      if (filter.tab == HistoryTab.transfers &&
          record.kind != TransactionKind.beneficiaryTransfer) {
        return false;
      }
      if (filter.direction != MoneyDirection.all &&
          record.incoming(walletActivity: walletActivity) !=
              (filter.direction == MoneyDirection.incoming)) {
        return false;
      }
      if (filter.statuses.isNotEmpty &&
          !filter.statuses.contains(record.status)) {
        return false;
      }
      if (filter.kinds.isNotEmpty && !filter.kinds.contains(record.kind)) {
        return false;
      }
      if (filter.destinations.isNotEmpty &&
          !filter.destinations.contains(record.destinationId)) {
        return false;
      }
      final range = filter.range;
      if (range != null) {
        final start = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        final endExclusive = DateTime(
          range.end.year,
          range.end.month,
          range.end.day + 1,
        );
        if (record.time.isBefore(start) ||
            !record.time.isBefore(endExclusive)) {
          return false;
        }
      }
      return query.isEmpty ||
          [
            record.title,
            record.reference,
            record.source,
            record.destination,
            record.category,
            record.ruleName ?? '',
            record.providerReference ?? '',
          ].any((v) => v.toLowerCase().contains(query));
    }),
  );
}

/// Totals keep external income separate from internal allocations.
@immutable
class StatementTotals {
  const StatementTotals({
    required this.salaryMinor,
    required this.paidMinor,
    required this.allocatedMinor,
    required this.returnedMinor,
    required this.feeMinor,
    required this.completed,
    required this.unsettled,
  });
  factory StatementTotals.from(Iterable<TransactionViewData> records) {
    var salary = 0,
        paid = 0,
        allocated = 0,
        returned = 0,
        fees = 0,
        completed = 0,
        unsettled = 0;
    for (final r in records) {
      if (r.status != TransactionStatus.success) {
        unsettled++;
        continue;
      }
      completed++;
      fees += r.feeMinor;
      switch (r.kind) {
        case TransactionKind.salary:
          salary += r.amountMinor;
        case TransactionKind.walletAllocation:
          allocated += r.amountMinor;
        case TransactionKind.walletReturn:
          returned += r.amountMinor;
        case TransactionKind.beneficiaryTransfer:
          paid += r.amountMinor;
      }
    }
    return StatementTotals(
      salaryMinor: salary,
      paidMinor: paid,
      allocatedMinor: allocated,
      returnedMinor: returned,
      feeMinor: fees,
      completed: completed,
      unsettled: unsettled,
    );
  }
  final int salaryMinor,
      paidMinor,
      allocatedMinor,
      returnedMinor,
      feeMinor,
      completed,
      unsettled;
}

/// Preview CSV includes all filtered rows, with decimal minor units preserved.
String statementCsv(Iterable<TransactionViewData> records) {
  String cell(String value) {
    final protected = RegExp(r'^[=+\-@\t\r]').hasMatch(value)
        ? "'$value"
        : value;
    return '"${protected.replaceAll('"', '""')}"';
  }

  String amount(int minor) =>
      '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';
  return [
    [
      'Reference',
      'Date',
      'Type',
      'Status',
      'Amount NGN',
      'Fee NGN',
      'Source',
      'Destination',
    ],
    for (final r in records)
      [
        r.reference,
        r.time.toIso8601String(),
        r.kind.label,
        r.status.label,
        amount(r.amountMinor),
        amount(r.feeMinor),
        r.source,
        r.destination,
      ],
  ].map((row) => row.map(cell).join(',')).join('\r\n');
}
