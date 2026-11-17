import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/salary/data/data_sources/salary_account_data_source.dart';
import 'package:paysplit/features/salary/data/models/salary_account.dart';

class SalaryAccountRepository {
  const SalaryAccountRepository(this._source);
  final SalaryAccountDataSource _source;

  Future<SalaryAccount> account() async =>
      SalaryAccount.fromJson(await _source.account());

  /// Supplies a BVN or NIN so the account can be issued, then returns the
  /// account as it now stands. [method] is `bvn` or `nin`.
  Future<SalaryAccount> addIdentity({
    required String method,
    required String idNumber,
  }) async =>
      SalaryAccount.fromJson(await _source.addIdentity(method, idNumber));

  /// Dev/QA only: runs the real salary-credit flow with simulated money.
  Future<void> simulateCredit({
    required int amount,
    String? senderName,
    String? narration,
  }) async {
    await _source.simulateCredit({
      'amount': amount,
      'senderName': ?senderName,
      'narration': ?narration,
    });
  }
}

final salaryAccountRepositoryProvider = Provider<SalaryAccountRepository>(
  (ref) => SalaryAccountRepository(ref.watch(salaryAccountDataSourceProvider)),
);
