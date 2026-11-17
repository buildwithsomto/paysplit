import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/json.dart';
import 'package:paysplit/features/auth/data/models/auth_models.dart';
import 'package:paysplit/features/setup/data/data_sources/setup_data_source.dart';
import 'package:paysplit/features/setup/data/models/income.dart';

class SetupRepository {
  const SetupRepository(this._source);
  final SetupDataSource _source;

  /// Null until the user completes setup step 1.
  Future<Income?> income() async => Income.fromJsonOrNull(
    Json.from(await _source.income()).objectOrNull('income'),
  );

  /// Also used by Profile → Salary Income Source. Returns the saved income
  /// with the refreshed onboarding progress.
  Future<({Income income, Onboarding onboarding})> saveIncome({
    required String employerName,
    required int monthlyAmount,
    required int paydayDay,
  }) async {
    final json = Json.from(
      await _source.saveIncome({
        'employerName': employerName,
        'monthlyAmount': monthlyAmount,
        'paydayDay': paydayDay,
      }),
    );
    return (
      income: Income.fromJson(json.object('income')),
      onboarding: Onboarding.fromJson(json.object('onboarding')),
    );
  }
}

final setupRepositoryProvider = Provider<SetupRepository>(
  (ref) => SetupRepository(ref.watch(setupDataSourceProvider)),
);
