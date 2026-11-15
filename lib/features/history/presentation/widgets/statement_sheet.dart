import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';
import 'package:paysplit/features/history/presentation/controllers/history_filter_controller.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/inputs/app_select_field.dart';
import 'package:paysplit/widgets/overlays/choice_sheet.dart';
import 'package:paysplit/widgets/overlays/editor_sheet_layout.dart';

Future<void> showStatementSheet(
  BuildContext context,
  List<TransactionViewData> records, {
  required bool sample,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: const Color(0xFFFBFBFB),
  clipBehavior: Clip.antiAlias,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
  ),
  builder: (_) => StatementSheet(records: records, sample: sample),
);

class StatementSheet extends StatefulWidget {
  const StatementSheet({
    required this.records,
    required this.sample,
    super.key,
  });
  final List<TransactionViewData> records;
  final bool sample;
  @override
  State<StatementSheet> createState() => _StatementSheetState();
}

class _StatementSheetState extends State<StatementSheet> {
  String _format = 'PDF';
  HistoryDateRange? _range;
  bool _preview = false;
  @override
  Widget build(BuildContext context) {
    final records = filterHistory(
      widget.records,
      HistoryFilterState(range: _range),
    );
    final totals = StatementTotals.from(records);
    return EditorSheetLayout(
      title: _preview ? 'Statement Preview' : 'Export Statement',
      height: 740,
      onClose: () => Navigator.pop(context),
      bottom: AppButton(
        label: _preview ? 'Back to Export' : 'Preview Statement',
        onPressed: records.isEmpty
            ? null
            : () => setState(() => _preview = !_preview),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          if (!_preview) ...[
            const Text(
              'Export includes every matching record, including rows beyond the current page. Select a period and format.',
            ),
            AppSelectField(
              label: 'Format',
              value: _format,
              onPressed: () async {
                final format = await showChoiceSheet(
                  context,
                  title: 'Statement format',
                  choices: ['PDF', 'CSV'],
                  label: (v) => v,
                  selected: _format,
                );
                if (format != null && mounted) {
                  setState(() => _format = format);
                }
              },
            ),
            AppSelectField(
              label: 'Statement Period',
              value: _range == null
                  ? 'All matching dates'
                  : '${DateFormat.yMMMd().format(_range!.start)} – ${DateFormat.yMMMd().format(_range!.end)}',
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  initialDateRange: _range == null
                      ? null
                      : DateTimeRange(start: _range!.start, end: _range!.end),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                );
                if (range != null && mounted) {
                  setState(() => _range = (start: range.start, end: range.end));
                }
              },
            ),
            if (_range != null)
              TextButton(
                onPressed: () => setState(() => _range = null),
                child: const Text('Use all matching dates'),
              ),
          ],
          Text(
            '${records.length} transactions · $_format',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (records.isEmpty)
            const Text('There are no transactions for this selection.'),
          if (_preview) ...[
            const Text(
              'SAMPLE — NOT PROOF OF PAYMENT',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            _TotalRow('Salary received', totals.salaryMinor),
            _TotalRow('Beneficiary payments', totals.paidMinor),
            _TotalRow('Allocated to wallets', totals.allocatedMinor),
            _TotalRow('Returned from wallets', totals.returnedMinor),
            _TotalRow('Fees', totals.feeMinor),
            Text(
              '${totals.completed} successful · ${totals.unsettled} other statuses. Totals include successful records only; internal allocations are not new income.',
            ),
            if (_format == 'CSV')
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  statementCsv(records),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              )
            else
              for (final record in records)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4,
                    children: [
                      Row(
                        spacing: 12,
                        children: [
                          Expanded(child: Text(record.title)),
                          Expanded(
                            child: Text(
                              Money.format(record.amountMinor),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${record.reference}\n${DateFormat.yMMMd().format(record.time)} · ${record.status.label}',
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                ),
            AppButton(label: 'Download $_format', onPressed: null),
          ],
          Text(
            widget.sample
                ? 'This is a local sample preview. Downloading or sharing an official statement will require the provided API.'
                : 'Your account is not connected. Statement downloads will be available after API integration.',
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.amount);
  final String label;
  final int amount;
  @override
  Widget build(BuildContext context) => Row(
    spacing: 16,
    children: [
      Expanded(child: Text(label)),
      Expanded(child: Text(Money.format(amount), textAlign: TextAlign.right)),
    ],
  );
}
