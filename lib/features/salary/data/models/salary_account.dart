import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/network/json.dart';

/// Lifecycle of the virtual account salary is paid into.
enum SalaryAccountPhase {
  /// Before KYC approval.
  notIssued,

  /// Being created with the banking partner.
  pending,
  active,
  failed,
  closed;

  static SalaryAccountPhase fromApi(String value) => switch (value) {
    'not_issued' => notIssued,
    'pending' => pending,
    'active' => active,
    'failed' => failed,
    'closed' => closed,
    _ => throw ApiException.invalidResponse,
  };
}

/// One bank account number salary can be sent to.
class FundingAccount {
  const FundingAccount({
    required this.accountNumber,
    required this.bankName,
    this.accountName,
  });

  factory FundingAccount.fromJson(Object? value) {
    final json = Json.from(value);
    return FundingAccount(
      accountNumber: json.string('accountNumber'),
      bankName: json.string('bankName'),
      accountName: json.stringOrNull('accountName'),
    );
  }

  final String accountNumber, bankName;
  final String? accountName;
}

class SalaryAccount {
  const SalaryAccount({
    required this.phase,
    required this.balance,
    required this.accounts,
    this.accountName,
    this.maskedAccountNumber,
    this.actionRequired,
  });

  factory SalaryAccount.fromJson(Object? value) {
    final json = Json.from(value);
    return SalaryAccount(
      phase: SalaryAccountPhase.fromApi(json.string('status')),
      // The balance and the account numbers are absent until the account is
      // active.
      balance: json.integerOrNull('balance') ?? 0,
      accounts: json.listOrEmpty('accounts', FundingAccount.fromJson),
      accountName: json.stringOrNull('accountName'),
      maskedAccountNumber: json.stringOrNull('maskedAccountNumber'),
      actionRequired: json.stringOrNull('actionRequired'),
    );
  }

  final SalaryAccountPhase phase;

  /// Available balance in kobo.
  final int balance;
  final String? accountName, maskedAccountNumber;

  /// Every funding account number; empty until the account is active.
  final List<FundingAccount> accounts;

  /// `add_bvn_or_nin` when a Nigerian ID is needed before the account can be
  /// issued (verified with a passport or licence, or the partner declined).
  final String? actionRequired;

  bool get isActive => phase == SalaryAccountPhase.active;
  bool get needsNigerianId => actionRequired == 'add_bvn_or_nin';

  @override
  String toString() => 'SalaryAccount([redacted])';
}
