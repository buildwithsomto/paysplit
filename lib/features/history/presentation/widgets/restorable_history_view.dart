import 'package:flutter/widgets.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';
import 'package:paysplit/features/history/presentation/controllers/history_filter_controller.dart';

/// OS-restorable view choices only. Search text and destination identifiers may
/// contain personal information and are deliberately absent from the payload.
class RestorableHistoryView extends RestorableValue<HistoryFilterState> {
  RestorableHistoryView(this._initial);
  final HistoryFilterState _initial;

  @override
  HistoryFilterState createDefaultValue() => _initial;

  @override
  void didUpdateValue(HistoryFilterState? oldValue) => notifyListeners();

  @override
  Object toPrimitives() => {
    'version': 1,
    'tab': value.tab.name,
    'direction': value.direction.name,
    'statuses': value.statuses.map((v) => v.name).toList(),
    'kinds': value.kinds.map((v) => v.name).toList(),
    'start': value.range?.start.toIso8601String(),
    'end': value.range?.end.toIso8601String(),
    'visible': value.visibleCount,
  };

  @override
  HistoryFilterState fromPrimitives(Object? data) {
    if (data is! Map || data['version'] != 1) {
      return const HistoryFilterState();
    }
    T? choice<T extends Enum>(Iterable<T> choices, Object? name) =>
        choices.where((v) => v.name == name).firstOrNull;
    Set<T> choices<T extends Enum>(Iterable<T> values, Object? names) =>
        names is List
        ? Set.unmodifiable(values.where((v) => names.contains(v.name)))
        : {};
    DateTime? date(Object? value) =>
        value is String ? DateTime.tryParse(value) : null;
    final start = date(data['start']);
    final end = date(data['end']);
    final count = data['visible'];
    return HistoryFilterState(
      tab: choice(HistoryTab.values, data['tab']) ?? HistoryTab.all,
      direction:
          choice(MoneyDirection.values, data['direction']) ??
          MoneyDirection.all,
      statuses: choices(TransactionStatus.values, data['statuses']),
      kinds: choices(TransactionKind.values, data['kinds']),
      range: start != null && end != null && !end.isBefore(start)
          ? (start: start, end: end)
          : null,
      visibleCount: count is int ? count.clamp(20, 10000) : 20,
    );
  }
}
