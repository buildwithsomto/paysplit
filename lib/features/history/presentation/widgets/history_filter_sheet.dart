import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';
import 'package:paysplit/features/history/presentation/controllers/history_filter_controller.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/inputs/app_select_field.dart';
import 'package:paysplit/widgets/overlays/choice_sheet.dart';
import 'package:paysplit/widgets/overlays/editor_sheet_layout.dart';

Future<HistoryFilterState?> showHistoryFilters(
  BuildContext context,
  HistoryFilterState initial,
  List<TransactionViewData> records, {
  bool destinationScoped = false,
}) => showModalBottomSheet<HistoryFilterState>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: const Color(0xFFFBFBFB),
  clipBehavior: Clip.antiAlias,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
  ),
  builder: (_) => HistoryFilterSheet(
    initial: initial,
    records: records,
    destinationScoped: destinationScoped,
  ),
);

class HistoryFilterSheet extends StatefulWidget {
  const HistoryFilterSheet({
    required this.initial,
    required this.records,
    this.destinationScoped = false,
    super.key,
  });
  final HistoryFilterState initial;
  final List<TransactionViewData> records;
  final bool destinationScoped;
  @override
  State<HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<HistoryFilterSheet> {
  late HistoryFilterState _filter = widget.initial;
  @override
  Widget build(BuildContext context) {
    final destinations = {
      for (final r in widget.records)
        if (r.destinationId != null)
          r.destinationId!: r.kind == TransactionKind.walletReturn
              ? r.source
              : r.destination,
    };
    return EditorSheetLayout(
      title: 'Filter Transactions',
      height: 670,
      onClose: () => Navigator.pop(context),
      bottom: Row(
        spacing: 16,
        children: [
          Expanded(
            child: AppButton(
              label: 'Reset',
              outlined: true,
              onPressed: () => setState(
                () => _filter = widget.initial.copyWith(
                  statuses: {},
                  kinds: {},
                  destinations: {},
                  clearRange: true,
                ),
              ),
            ),
          ),
          Expanded(
            child: AppButton(
              label: 'Apply Filters',
              onPressed: () => Navigator.pop(context, _filter),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18,
        children: [
          AppSelectField(
            label: 'Status',
            value: _filter.statuses.firstOrNull?.label ?? 'All statuses',
            onPressed: () async {
              final selected = await showChoiceSheet<String>(
                context,
                title: 'Transaction status',
                choices: ['', ...TransactionStatus.values.map((s) => s.name)],
                label: (v) => v.isEmpty
                    ? 'All statuses'
                    : TransactionStatus.values.byName(v).label,
                selected: _filter.statuses.firstOrNull?.name ?? '',
              );
              if (mounted && selected != null) {
                setState(
                  () => _filter = _filter.copyWith(
                    statuses: selected.isEmpty
                        ? {}
                        : {TransactionStatus.values.byName(selected)},
                  ),
                );
              }
            },
          ),
          if (_filter.statuses.isNotEmpty)
            TextButton(
              onPressed: () =>
                  setState(() => _filter = _filter.copyWith(statuses: {})),
              child: const Text('Clear status filter'),
            ),
          AppSelectField(
            label: 'Transaction Type',
            value: _filter.kinds.firstOrNull?.label ?? 'All types',
            onPressed: () async {
              final kind = await showChoiceSheet(
                context,
                title: 'Transaction type',
                choices: TransactionKind.values,
                label: (v) => v.label,
                selected: _filter.kinds.firstOrNull,
              );
              if (mounted && kind != null) {
                setState(() => _filter = _filter.copyWith(kinds: {kind}));
              }
            },
          ),
          if (_filter.kinds.isNotEmpty)
            TextButton(
              onPressed: () =>
                  setState(() => _filter = _filter.copyWith(kinds: {})),
              child: const Text('Clear type filter'),
            ),
          if (!widget.destinationScoped)
            AppSelectField(
              label: 'Wallet or Beneficiary',
              value: _filter.destinations.isEmpty
                  ? 'All destinations'
                  : destinations[_filter.destinations.first],
              onPressed: () async {
                final id = await showChoiceSheet(
                  context,
                  title: 'Wallet or beneficiary',
                  choices: ['', ...destinations.keys],
                  label: (v) =>
                      v.isEmpty ? 'All destinations' : destinations[v]!,
                  selected: _filter.destinations.firstOrNull,
                );
                if (mounted && id != null) {
                  setState(
                    () => _filter = _filter.copyWith(
                      destinations: id.isEmpty ? {} : {id},
                    ),
                  );
                }
              },
            ),
          if (_filter.destinations.isNotEmpty)
            TextButton(
              onPressed: () =>
                  setState(() => _filter = _filter.copyWith(destinations: {})),
              child: const Text('Clear destination filter'),
            ),
          AppSelectField(
            label: 'Date Range',
            value: _filter.range == null
                ? 'All dates'
                : '${DateFormat.yMMMd().format(_filter.range!.start)} – ${DateFormat.yMMMd().format(_filter.range!.end)}',
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                initialDateRange: _filter.range == null
                    ? null
                    : DateTimeRange(
                        start: _filter.range!.start,
                        end: _filter.range!.end,
                      ),
              );
              if (mounted && range != null) {
                setState(
                  () => _filter = _filter.copyWith(
                    range: (start: range.start, end: range.end),
                  ),
                );
              }
            },
          ),
          if (_filter.range != null)
            TextButton(
              onPressed: () =>
                  setState(() => _filter = _filter.copyWith(clearRange: true)),
              child: const Text('Clear date range'),
            ),
        ],
      ),
    );
  }
}
