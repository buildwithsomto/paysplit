import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/formatting/money.dart';

@immutable
class SetupState {
  const SetupState({
    this.employer = '',
    this.salaryInput = '',
    this.salaryMinor = 0,
    this.payDay,
    this.errors = const {},
  });
  final String employer;
  final String salaryInput;
  final int salaryMinor;
  final int? payDay;
  final Map<String, String> errors;
  bool get salarySourceComplete =>
      employer.trim().isNotEmpty &&
      salaryMinor > 0 &&
      Money.parse(salaryInput) == salaryMinor &&
      payDay != null;
  SetupState copyWith({
    String? employer,
    String? salaryInput,
    int? salaryMinor,
    int? payDay,
    Map<String, String>? errors,
  }) => SetupState(
    employer: employer ?? this.employer,
    salaryInput: salaryInput ?? this.salaryInput,
    salaryMinor: salaryMinor ?? this.salaryMinor,
    payDay: payDay ?? this.payDay,
    errors: Map.unmodifiable(errors ?? this.errors),
  );
}

class SetupController extends Notifier<SetupState> {
  @override
  SetupState build() => const SetupState();
  void saveSalaryProfile({
    required String employer,
    required String salaryInput,
    required int salaryMinor,
    required int payDay,
  }) => state = SetupState(
    employer: employer.trim(),
    salaryInput: salaryInput,
    salaryMinor: salaryMinor,
    payDay: payDay,
  );
  void setPayDay(int day) {
    if (day < 1 || day > 31) return;
    state = state.copyWith(
      payDay: day,
      errors: {...state.errors}..remove('day'),
    );
  }

  void updateEmployer(String value) => state = state.copyWith(
    employer: value,
    errors: {...state.errors}..remove('employer'),
  );
  void updateSalary(String value) => state = state.copyWith(
    salaryInput: value,
    errors: {...state.errors}..remove('salary'),
  );
  bool validate() {
    final salary = Money.parse(state.salaryInput);
    final errors = <String, String>{};
    if (state.employer.trim().isEmpty) {
      errors['employer'] = 'Enter your employer or income source.';
    }
    if (salary == null || salary <= 0) {
      errors['salary'] = 'Enter a monthly salary greater than zero.';
    }
    if (state.payDay == null) errors['day'] = 'Select your expected pay day.';
    state = state.copyWith(salaryMinor: salary ?? 0, errors: errors);
    return errors.isEmpty;
  }

  /// A calendar expectation only. This never schedules or executes a transfer.
  static DateTime nextExpectedDate(DateTime now, int payDay) {
    assert(payDay >= 1 && payDay <= 31);
    DateTime inMonth(int year, int month) {
      final lastDay = DateTime(year, month + 1, 0).day;
      return DateTime(year, month, payDay > lastDay ? lastDay : payDay);
    }

    final thisMonth = inMonth(now.year, now.month);
    final today = DateTime(now.year, now.month, now.day);
    return thisMonth.isBefore(today)
        ? inMonth(now.year, now.month + 1)
        : thisMonth;
  }
}

final setupControllerProvider = NotifierProvider<SetupController, SetupState>(
  SetupController.new,
);
