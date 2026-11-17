import 'package:paysplit/core/network/json.dart';

/// The salary income source: who pays, how much and on which day.
class Income {
  const Income({
    required this.employerName,
    required this.monthlyAmount,
    required this.paydayDay,
    this.nextPayday,
  });

  factory Income.fromJson(Object? value) {
    final json = Json.from(value);
    return Income(
      employerName: json.string('employerName'),
      monthlyAmount: json.integer('monthlyAmount'),
      paydayDay: json.integer('paydayDay'),
      nextPayday: json.dayOrNull('nextPayday'),
    );
  }

  static Income? fromJsonOrNull(Object? value) =>
      value == null ? null : Income.fromJson(value);

  final String employerName;

  /// Expected monthly salary in kobo.
  final int monthlyAmount;

  /// Day of the month, 1-31. 31 falls on the last day of shorter months.
  final int paydayDay;
  final DateTime? nextPayday;
}
