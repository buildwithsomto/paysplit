import 'package:flutter/foundation.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/network/json.dart';
import 'package:paysplit/features/destinations/data/models/destination_transaction.dart';

enum TransactionKind {
  salary('Salary received'),
  walletAllocation('Wallet allocation'),
  walletReturn('Wallet to salary account'),
  beneficiaryTransfer('Beneficiary transfer');

  const TransactionKind(this.label);
  final String label;

  static TransactionKind fromApi(String type) => switch (type) {
    'salary_credit' => salary,
    'wallet_allocation' => walletAllocation,
    'wallet_withdrawal' => walletReturn,
    'beneficiary_payout' => beneficiaryTransfer,
    _ => throw ApiException.invalidResponse,
  };
}

/// Each value's [name] is the API's spelling, in responses and as the
/// `status` filter.
enum TransactionStatus {
  success('Success'),
  pending('Pending'),
  failed('Failed'),
  reversed('Reversed');

  const TransactionStatus(this.label);
  final String label;

  static TransactionStatus fromApi(String value) => switch (value) {
    'success' => success,
    'pending' => pending,
    'failed' => failed,
    'reversed' => reversed,
    _ => throw ApiException.invalidResponse,
  };
}

/// One ledger entry: a salary credit, a wallet allocation or return, or a
/// transfer to a beneficiary.
///
/// `{id, reference, type, status, title, direction, amount, signedAmount,
/// fee, currency, category: {id, name, slug}?, destination: {type, id, name},
/// narration, createdAt, completedAt}`; the detail adds `recipient: {name,
/// type, bankName, maskedAccountNumber}`, `providerReference` and
/// `splitRuleId`. `signedAmount` is negative for money leaving the salary
/// account. `type` is `salary_credit`, `wallet_allocation`,
/// `wallet_withdrawal` or `beneficiary_payout`.
@immutable
class Transaction {
  const Transaction({
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
    this.ruleName,
    this.note,
    this.bankName,
    this.maskedAccountNumber,
    this.feeMinor = 0,
  });

  factory Transaction.fromJson(Object? value) {
    final json = Json.from(value);
    final recipient = json.objectOrNull('recipient');
    final kind = TransactionKind.fromApi(json.string('type'));
    final narration = json.stringOrNull('narration');
    // A split writes the rule's name as the narration.
    final fromRule = json.has('splitRuleId');
    return Transaction(
      id: json.string('id'),
      reference: json.string('reference'),
      title: json.string('title'),
      kind: kind,
      status: TransactionStatus.fromApi(json.string('status')),
      amountMinor: json.integer('amount'),
      time: json.date('createdAt'),
      source: switch (kind) {
        TransactionKind.salary => 'Employer',
        TransactionKind.walletReturn => 'Wallet',
        _ => 'Salary account',
      },
      destination: json.object('destination').string('name'),
      // A salary credit has no category.
      category:
          json.objectOrNull('category')?.stringOrNull('name') ?? kind.label,
      ruleName: fromRule ? narration : null,
      note: fromRule ? null : narration,
      bankName: recipient?.stringOrNull('bankName'),
      maskedAccountNumber: recipient?.stringOrNull('maskedAccountNumber'),
      feeMinor: json.integer('fee'),
    );
  }

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
  final String? ruleName;
  final String? note;

  /// The receiving bank account, for a transfer to a beneficiary.
  final String? bankName, maskedAccountNumber;
  final int feeMinor;

  bool get canViewReceipt => status == TransactionStatus.success;
  bool get incomingToSalary =>
      kind == TransactionKind.salary || kind == TransactionKind.walletReturn;
  bool incoming({bool walletActivity = false}) => walletActivity
      ? kind == TransactionKind.walletAllocation
      : incomingToSalary;
}

/// A wallet or beneficiary transaction as a history row, so every list in
/// the app renders money movements the same way.
Transaction destinationRecord(
  DestinationTransaction transaction, {
  required bool beneficiary,
  required String destinationName,
  String? title,
}) {
  return Transaction(
    id: transaction.id,
    reference: transaction.reference,
    title: title ?? transaction.label,
    kind: beneficiary
        ? TransactionKind.beneficiaryTransfer
        : transaction.incoming
        ? TransactionKind.walletAllocation
        : TransactionKind.walletReturn,
    status: switch (transaction.status) {
      DestinationTransactionStatus.success => TransactionStatus.success,
      DestinationTransactionStatus.failed => TransactionStatus.failed,
      DestinationTransactionStatus.reversed => TransactionStatus.reversed,
      DestinationTransactionStatus.pending ||
      DestinationTransactionStatus.unknown => TransactionStatus.pending,
    },
    amountMinor: transaction.magnitudeMinor,
    time: transaction.createdAt,
    source: 'Salary account',
    destination: destinationName,
    category: transaction.category,
    note: transaction.narration,
  );
}
