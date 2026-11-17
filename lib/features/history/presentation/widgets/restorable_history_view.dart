import 'package:flutter/widgets.dart';
import 'package:paysplit/features/history/data/models/transaction.dart';
import 'package:paysplit/features/history/presentation/controllers/history_filter_controller.dart';

/// OS-restorable view choices only. Search text may contain personal
/// information and is deliberately absent from the payload.
class RestorableHistoryView extends RestorableValue<HistoryFilterState> {
  RestorableHistoryView(this._initial);
  final HistoryFilterState _initial;

  @override
  HistoryFilterState createDefaultValue() => _initial;

  @override
  void didUpdateValue(HistoryFilterState? oldValue) => notifyListeners();

  @override
  Object toPrimitives() => {
    'tab': value.tab.name,
    'direction': value.direction.name,
    'status': value.status?.name,
    'start': value.range?.start.toIso8601String(),
    'end': value.range?.end.toIso8601String(),
  };

  @override
  HistoryFilterState fromPrimitives(Object? data) {
    if (data is! Map) return const HistoryFilterState();
    T? choice<T extends Enum>(Iterable<T> choices, Object? name) =>
        choices.where((v) => v.name == name).firstOrNull;
    DateTime? date(Object? value) =>
        value is String ? DateTime.tryParse(value) : null;
    final start = date(data['start']);
    final end = date(data['end']);
    return HistoryFilterState(
      tab: choice(HistoryTab.values, data['tab']) ?? HistoryTab.all,
      direction:
          choice(MoneyDirection.values, data['direction']) ??
          MoneyDirection.all,
      status: choice(TransactionStatus.values, data['status']),
      range: start != null && end != null && !end.isBefore(start)
          ? (start: start, end: end)
          : null,
    );
  }
}
