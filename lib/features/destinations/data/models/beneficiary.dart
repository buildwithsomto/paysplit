import 'package:flutter/foundation.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/network/json.dart';

/// A bank from `GET /banks`, for the bank picker.
@immutable
class Bank {
  const Bank({required this.code, required this.name});

  factory Bank.fromJson(Object? value) {
    final json = Json.from(value);
    return Bank(code: json.string('code'), name: json.string('name'));
  }

  final String code, name;

  @override
  bool operator ==(Object other) => other is Bank && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

enum BeneficiaryStatus {
  active,
  paused;

  static BeneficiaryStatus fromApi(String value) => switch (value) {
    'active' => active,
    'paused' => paused,
    _ => throw ApiException.invalidResponse,
  };
}

/// A saved recipient bank account as the list, create and edit endpoints
/// return it: `{id, accountName, bankName, maskedAccountNumber,
/// category: {id, name}, status, nextSplitDate}`.
@immutable
class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.name,
    required this.bank,
    required this.maskedAccountNumber,
    required this.categoryId,
    required this.category,
    required this.status,
    this.nextSplitDate,
  });

  factory Beneficiary.fromJson(Object? value) {
    final json = Json.from(value);
    final category = json.object('category');
    return Beneficiary(
      id: json.string('id'),
      name: json.string('accountName'),
      bank: json.string('bankName'),
      maskedAccountNumber: json.string('maskedAccountNumber'),
      categoryId: category.string('id'),
      category: category.string('name'),
      status: BeneficiaryStatus.fromApi(json.string('status')),
      nextSplitDate: json.dayOrNull('nextSplitDate'),
    );
  }

  final String id;

  /// The account name the bank returned.
  final String name;

  /// The bank's display name.
  final String bank;

  /// The account number with all but its last four digits hidden.
  final String maskedAccountNumber;

  /// Sent back as `categoryId`; [category] is its display name.
  final String categoryId, category;
  final BeneficiaryStatus status;

  /// The next payday this beneficiary's rule runs on.
  final DateTime? nextSplitDate;

  bool get paused => status == BeneficiaryStatus.paused;
}

/// `GET /beneficiaries/{id}`: the list fields plus `accountNumber`,
/// `narration` and `totalAllocated`.
@immutable
class BeneficiaryDetail {
  const BeneficiaryDetail({
    required this.beneficiary,
    required this.accountNumber,
    required this.totalAllocatedMinor,
    this.narration,
  });

  factory BeneficiaryDetail.fromJson(Object? value) {
    final json = Json.from(value);
    return BeneficiaryDetail(
      beneficiary: Beneficiary.fromJson(value),
      accountNumber: json.string('accountNumber'),
      totalAllocatedMinor: json.integer('totalAllocated'),
      narration: json.stringOrNull('narration'),
    );
  }

  final Beneficiary beneficiary;

  /// The whole account number, to reveal or copy.
  final String accountNumber;

  /// Kobo sent to this beneficiary so far.
  final int totalAllocatedMinor;

  /// The note sent with each transfer; null when none is set.
  final String? narration;
}
