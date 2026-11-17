import 'package:paysplit/core/network/json.dart';
import 'package:paysplit/features/auth/data/models/auth_models.dart';
import 'package:paysplit/features/salary/data/models/salary_account.dart';
import 'package:paysplit/features/setup/data/models/income.dart';

/// What the active split rules take out of each salary.
class SplitAllocationSummary {
  const SplitAllocationSummary({
    required this.amount,
    required this.activeRules,
    required this.percentOfSalary,
  });

  factory SplitAllocationSummary.fromJson(Json json) => SplitAllocationSummary(
    amount: json.integer('amount'),
    activeRules: json.integer('activeRules'),
    percentOfSalary: json.number('percentOfSalary'),
  );

  /// Kobo.
  final int amount;
  final int activeRules;
  final double percentOfSalary;
}

class WalletsSummary {
  const WalletsSummary({
    required this.total,
    required this.activeCount,
    required this.withTargetCount,
  });

  factory WalletsSummary.fromJson(Json json) => WalletsSummary(
    total: json.integer('total'),
    activeCount: json.integer('activeCount'),
    withTargetCount: json.integer('withTargetCount'),
  );

  /// Combined wallet balances in kobo.
  final int total;
  final int activeCount, withTargetCount;
}

/// How one salary is divided between wallets, beneficiaries and spending.
class SalaryPartition {
  const SalaryPartition({
    required this.baselineSalary,
    required this.toWallets,
    required this.toBeneficiaries,
    required this.remaining,
    required this.remainingPercent,
  });

  factory SalaryPartition.fromJson(Json json) => SalaryPartition(
    baselineSalary: json.integerOrNull('baselineSalary'),
    toWallets: json.integer('toWallets'),
    toBeneficiaries: json.integer('toBeneficiaries'),
    remaining: json.integer('remaining'),
    remainingPercent: json.number('remainingPercent'),
  );

  /// The salary the split is planned against; null until income is set.
  final int? baselineSalary;
  final int toWallets, toBeneficiaries, remaining;
  final double remainingPercent;
}

/// `GET /dashboard/summary`.
class DashboardSummary {
  const DashboardSummary({
    required this.salaryAccount,
    required this.income,
    required this.splitAllocation,
    required this.wallets,
    required this.nextSplitRun,
    required this.partition,
    required this.unreadNotifications,
    required this.onboarding,
  });

  factory DashboardSummary.fromJson(Object? value) {
    final json = Json.from(value);
    return DashboardSummary(
      salaryAccount: SalaryAccount.fromJson(json.object('salaryAccount')),
      income: Income.fromJsonOrNull(json.objectOrNull('income')),
      splitAllocation: SplitAllocationSummary.fromJson(
        json.object('splitAllocation'),
      ),
      wallets: WalletsSummary.fromJson(json.object('wallets')),
      nextSplitRun: json.object('nextSplitRun').dayOrNull('date'),
      partition: SalaryPartition.fromJson(json.object('partition')),
      unreadNotifications: json.integer('unreadNotifications'),
      onboarding: Onboarding.fromJson(json.object('onboarding')),
    );
  }

  final SalaryAccount salaryAccount;

  /// Null until the salary income source is set.
  final Income? income;
  final SplitAllocationSummary splitAllocation;
  final WalletsSummary wallets;

  /// The day the rules next run; null while nothing is scheduled.
  final DateTime? nextSplitRun;
  final SalaryPartition partition;
  final int unreadNotifications;
  final Onboarding onboarding;

  DashboardSummary withUnreadNotifications(int count) => DashboardSummary(
    salaryAccount: salaryAccount,
    income: income,
    splitAllocation: splitAllocation,
    wallets: wallets,
    nextSplitRun: nextSplitRun,
    partition: partition,
    unreadNotifications: count < 0 ? 0 : count,
    onboarding: onboarding,
  );

  @override
  String toString() => 'DashboardSummary([redacted])';
}
