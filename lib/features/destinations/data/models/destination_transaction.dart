import 'package:flutter/foundation.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/network/json.dart';

enum DestinationTransactionStatus {
  success,
  pending,
  failed,
  reversed,

  /// Any other status the server reports; shown as still in progress.
  unknown;

  static DestinationTransactionStatus fromApi(String value) => switch (value) {
    'success' => success,
    'pending' => pending,
    'failed' => failed,
    'reversed' => reversed,
    _ => unknown,
  };
}

/// One row of wallet activity or of a beneficiary's transfer history:
/// `{id, reference, status, title, direction, amount, category: {name},
/// destination: {type, id, name}, narration, createdAt}`. It is the
/// transaction shape of `/transactions`, seen from the destination.
@immutable
class DestinationTransaction {
  const DestinationTransaction({
    required this.id,
    required this.reference,
    required this.label,
    required this.category,
    required this.incoming,
    required this.magnitudeMinor,
    required this.status,
    required this.createdAt,
    this.narration,
    this.walletId,
    this.walletName,
  });

  factory DestinationTransaction.fromJson(Object? value) {
    final json = Json.from(value);
    final destination = json.object('destination');
    final toWallet = destination.string('type') == 'wallet';
    return DestinationTransaction(
      id: json.string('id'),
      reference: json.string('reference'),
      label: json.string('title'),
      category: json.object('category').string('name'),
      incoming: switch (json.string('direction')) {
        'in' => true,
        'out' => false,
        _ => throw ApiException.invalidResponse,
      },
      magnitudeMinor: json.integer('amount').abs(),
      status: DestinationTransactionStatus.fromApi(json.string('status')),
      createdAt: json.date('createdAt'),
      narration: json.stringOrNull('narration'),
      walletId: toWallet ? destination.string('id') : null,
      walletName: toWallet ? destination.string('name') : null,
    );
  }

  final String id, reference;

  /// The server's one-line description, for example "Split from Salary".
  final String label;

  /// The category's display name.
  final String category;

  /// Whether money arrived in the destination (`true`) or left it.
  final bool incoming;

  /// The unsigned amount in kobo.
  final int magnitudeMinor;
  final DestinationTransactionStatus status;
  final DateTime createdAt;

  /// The rule or move that caused the transaction, when the server names it.
  final String? narration;

  /// The wallet the money went to; null for money leaving a wallet.
  final String? walletId, walletName;
}
