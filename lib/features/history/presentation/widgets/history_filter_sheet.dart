import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/features/history/data/models/transaction.dart';
import 'package:paysplit/features/history/presentation/controllers/history_filter_controller.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/inputs/app_select_field.dart';
import 'package:paysplit/widgets/overlays/editor_sheet_layout.dart';

/// Status, direction and date filters. Resolves to the chosen filters, or
/// null when the sheet is closed without applying.
Future<HistoryFilterState?> showHistoryFilters(
  BuildContext context,
  HistoryFilterState initial,
) => showModalBottomSheet<HistoryFilterState>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => HistoryFilterSheet(initial: initial),
);

class HistoryFilterSheet extends StatefulWidget {
  const HistoryFilterSheet({required this.initial, super.key});
  final HistoryFilterState initial;
  @override
  State<HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<HistoryFilterSheet> {
  late HistoryFilterState _filter = widget.initial;

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _filter.range == null
          ? null
          : DateTimeRange(start: _filter.range!.start, end: _filter.range!.end),
    );
    if (mounted && range != null) {
      setState(
        () => _filter = _filter.copyWith(
          range: (start: range.start, end: range.end),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _filter.range;
    return EditorSheetLayout(
      title: 'Filter Transactions',
      height: 560,
      onClose: () => Navigator.pop(context),
      bottom: Row(
        spacing: 16,
        children: [
          Expanded(
            child: AppButton(
              label: 'Reset',
              outlined: true,
              onPressed: () => setState(
                () => _filter = HistoryFilterState(
                  query: _filter.query,
                  tab: _filter.tab,
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
        children: [
          const Text('Status', style: AppTypography.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                selected: _filter.status == null,
                onSelected: () => setState(
                  () => _filter = _filter.copyWith(clearStatus: true),
                ),
              ),
              for (final status in TransactionStatus.values)
                _FilterChip(
                  label: status.label,
                  selected: _filter.status == status,
                  onSelected: () => setState(
                    () => _filter = _filter.copyWith(status: status),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Direction', style: AppTypography.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (direction, label) in const [
                (MoneyDirection.all, 'All'),
                (MoneyDirection.incoming, 'Money In'),
                (MoneyDirection.outgoing, 'Money Out'),
              ])
                _FilterChip(
                  label: label,
                  selected: _filter.direction == direction,
                  onSelected: () => setState(
                    () => _filter = _filter.copyWith(direction: direction),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          AppSelectField(
            label: 'Date Range',
            value: range == null
                ? null
                : '${DateFormat.yMMMd().format(range.start)} – ${DateFormat.yMMMd().format(range.end)}',
            hint: 'All dates',
            arrowAsset: 'assets/icons/destinations/cefc6.svg',
            onPressed: _pickDates,
          ),
          if (range != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(
                  () => _filter = _filter.copyWith(clearRange: true),
                ),
                child: const Text('Clear dates'),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? AppColors.action : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.action : const Color(0xFFE4E4E4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onSelected,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF333333),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
