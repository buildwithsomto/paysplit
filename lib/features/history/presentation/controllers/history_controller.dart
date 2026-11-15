import 'dart:async';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TransactionKind {
  salary('Salary received'),
  walletAllocation('Wallet allocation'),
  walletReturn('Wallet to salary account'),
  beneficiaryTransfer('Beneficiary transfer');

  const TransactionKind(this.label);
  final String label;
  bool get isWallet => this == walletAllocation || this == walletReturn;
}

enum TransactionStatus {
  success('Success'),
  pending('Pending'),
  uncertain('Pending confirmation'),
  failed('Failed'),
  reversed('Reversed');

  const TransactionStatus(this.label);
  final String label;
}

/// A historical UI snapshot. Editing/deleting a destination never rewrites it.
@immutable
class TransactionViewData {
  const TransactionViewData({
    required this.id,
    required this.reference,
    required this.title,
    required this.kind,
    required this.status,
    required this.amountMinor,
    required this.time,
    required this.source,
    required this.destination,
    required this.category,
    this.destinationId,
    this.ruleName,
    this.providerReference,
    this.note,
    this.feeMinor = 0,
    this.receiptSupported = true,
  });
  final String id;
  final String reference;
  final String title;
  final TransactionKind kind;
  final TransactionStatus status;
  final int amountMinor;
  final DateTime time;
  final String source;
  final String destination;
  final String category;
  final String? destinationId;
  final String? ruleName;
  final String? providerReference;
  final String? note;
  final int feeMinor;
  final bool receiptSupported;
  bool get canViewReceipt =>
      status == TransactionStatus.success && receiptSupported;
  bool get incomingToSalary =>
      kind == TransactionKind.salary || kind == TransactionKind.walletReturn;
  bool incoming({bool walletActivity = false}) => walletActivity
      ? kind == TransactionKind.walletAllocation
      : incomingToSalary;
}

@immutable
class HistoryState {
  const HistoryState({
    this.records = const [],
    this.sample = false,
    this.phase = ContentPhase.ready,
    this.updatedAt,
    this.retryFailed = false,
  });
  final List<TransactionViewData> records;
  final bool sample;
  final ContentPhase phase;
  final DateTime? updatedAt;
  final bool retryFailed;
}

class HistoryController extends Notifier<HistoryState> {
  Timer? _previewTimer;
  List<TransactionViewData> _previewRecords = const [];
  @override
  HistoryState build() {
    ref.onDispose(() => _previewTimer?.cancel());
    return const HistoryState();
  }

  /// Explicit development fixtures only; this never creates ledger entries.
  void loadPreview(Iterable<TransactionViewData> records) {
    final unique = {for (final record in records) record.id: record};
    final sorted = unique.values.toList()
      ..sort((a, b) {
        final byTime = b.time.compareTo(a.time);
        return byTime == 0 ? a.id.compareTo(b.id) : byTime;
      });
    _previewTimer?.cancel();
    _previewRecords = List.unmodifiable(sorted);
    state = HistoryState(
      records: _previewRecords,
      sample: true,
      updatedAt: DateTime.now(),
    );
  }

  void previewPhase(ContentPhase phase, {bool cached = true}) {
    _previewTimer?.cancel();
    state = HistoryState(
      records: cached ? _previewRecords : const [],
      sample: true,
      phase: phase,
      updatedAt: cached ? state.updatedAt : null,
    );
  }

  /// Deliberately fails while the selected outage lasts. This does not make a
  /// request, replay a transfer or claim that connectivity has been restored.
  void retryPreview() {
    if (!state.sample ||
        ![ContentPhase.offline, ContentPhase.error].contains(state.phase)) {
      return;
    }
    final previous = state;
    state = HistoryState(
      records: previous.records,
      sample: true,
      phase: ContentPhase.refreshing,
      updatedAt: previous.updatedAt,
    );
    _previewTimer = Timer(const Duration(milliseconds: 650), () {
      state = HistoryState(
        records: previous.records,
        sample: true,
        phase: previous.phase,
        updatedAt: previous.updatedAt,
        retryFailed: true,
      );
    });
  }

  void restorePreview() {
    _previewTimer?.cancel();
    state = HistoryState(
      records: _previewRecords,
      sample: true,
      updatedAt: DateTime.now(),
    );
  }

  void clearPreview() {
    _previewTimer?.cancel();
    _previewRecords = const [];
    state = const HistoryState();
  }
}

final historyControllerProvider =
    NotifierProvider<HistoryController, HistoryState>(HistoryController.new);
