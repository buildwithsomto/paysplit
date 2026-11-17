import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/features/history/data/repositories/history_repository.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/overlays/editor_sheet_layout.dart';
import 'package:share_plus/share_plus.dart';

/// "Export": fetches the statement CSV for the filters on screen and hands
/// it to the system share sheet (Save to Files, email, and so on).
Future<void> showStatementSheet(
  BuildContext context, {
  required TransactionQuery query,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => StatementSheet(query: query),
);

class StatementSheet extends ConsumerStatefulWidget {
  const StatementSheet({required this.query, super.key});
  final TransactionQuery query;
  @override
  ConsumerState<StatementSheet> createState() => _StatementSheetState();
}

class _StatementSheetState extends ConsumerState<StatementSheet> {
  /// The API caps one export at this many rows.
  static const _maxRows = 5000;

  String? _csv;
  String? _error;
  bool _loading = true;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final csv = await ref
          .read(historyRepositoryProvider)
          .exportCsv(widget.query);
      if (!mounted) return;
      setState(() {
        _csv = csv;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = describeError(
          error,
          fallback: 'The statement couldn’t be prepared.',
        );
      });
    }
  }

  /// Data rows in the CSV, not counting the header.
  int get _rows {
    final lines = const LineSplitter()
        .convert(_csv ?? '')
        .where((line) => line.trim().isNotEmpty)
        .length;
    return lines > 0 ? lines - 1 : 0;
  }

  Future<void> _share() async {
    final csv = _csv;
    if (csv == null || _sharing) return;
    setState(() => _sharing = true);
    File? file;
    try {
      final directory = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
      file = File('${directory.path}/paysplit-statement-$stamp.csv');
      await file.writeAsString(csv, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: 'PaySplit statement',
        ),
      );
      if (mounted) Navigator.pop(context);
    } on Object {
      if (mounted) {
        setState(() => _error = 'The statement couldn’t be shared. Try again.');
      }
    } finally {
      // Financial records are not left behind in temporary storage.
      try {
        await file?.delete();
      } on Object {
        // Already gone.
      }
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.query;
    final rows = _rows;
    final period = query.from == null || query.to == null
        ? 'All dates'
        : '${DateFormat.yMMMd().format(query.from!)} – ${DateFormat.yMMMd().format(query.to!)}';
    final scope = [
      switch (query.type) {
        HistoryTab.all => 'All transactions',
        HistoryTab.wallets => 'Wallet transactions',
        HistoryTab.transfers => 'Beneficiary transfers',
      },
      if (query.direction == MoneyDirection.incoming) 'Money in',
      if (query.direction == MoneyDirection.outgoing) 'Money out',
      if (query.status != null) query.status!.label,
      if ((query.search ?? '').trim().isNotEmpty) '“${query.search!.trim()}”',
    ].join(' · ');
    return EditorSheetLayout(
      title: 'Export Statement',
      subtitle: 'A CSV of the transactions you’re viewing.',
      height: 460,
      onClose: () => Navigator.pop(context),
      bottom: _error != null && _csv == null
          ? AppButton(label: 'Try Again', onPressed: _load)
          : AppButton(
              label: 'Share CSV',
              busy: _loading || _sharing,
              onPressed: rows == 0 ? null : _share,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Column(
              spacing: 14,
              children: [
                _Row(label: 'Period', value: period),
                _Row(label: 'Includes', value: scope),
                _Row(
                  label: 'Transactions',
                  value: _loading
                      ? 'Preparing…'
                      : _csv == null
                      ? '—'
                      : NumberFormat.decimalPattern().format(rows),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              _error ??
                  (!_loading && _csv != null && rows == 0
                      ? 'There are no transactions to export for these filters.'
                      : rows >= _maxRows
                      ? 'This export holds the first ${NumberFormat.decimalPattern().format(_maxRows)} transactions. Narrow the dates to export the rest.'
                      : 'Amounts are in naira. Dates use West Africa Time.'),
              style: AppTypography.body.copyWith(
                fontSize: 12,
                color: _error == null ? AppColors.body : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 16,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF696969)),
        ),
      ),
      Expanded(
        flex: 2,
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF171918),
          ),
        ),
      ),
    ],
  );
}
