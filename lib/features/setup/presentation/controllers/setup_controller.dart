import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/features/setup/data/models/income.dart';
import 'package:paysplit/features/setup/data/repositories/setup_repository.dart';

@immutable
class SetupState {
  const SetupState({
    this.employer = '',
    this.salaryInput = '',
    this.salaryMinor = 0,
    this.payDay,
    this.nextPayday,
    this.errors = const {},
    this.phase = ContentPhase.loading,
    this.busy = false,
    this.saved = false,
  });
  final String employer;
  final String salaryInput;
  final int salaryMinor;
  final int? payDay;

  /// The server's next expected payday for the saved income.
  final DateTime? nextPayday;

  /// Keyed by form field; `form` holds a failure that belongs to no field.
  final Map<String, String> errors;

  /// Loading the saved income source.
  final ContentPhase phase;
  final bool busy;

  /// The income source exists on the server.
  final bool saved;

  SetupState copyWith({
    String? employer,
    String? salaryInput,
    int? salaryMinor,
    int? payDay,
    DateTime? nextPayday,
    Map<String, String>? errors,
    ContentPhase? phase,
    bool? busy,
    bool? saved,
  }) => SetupState(
    employer: employer ?? this.employer,
    salaryInput: salaryInput ?? this.salaryInput,
    salaryMinor: salaryMinor ?? this.salaryMinor,
    payDay: payDay ?? this.payDay,
    nextPayday: nextPayday ?? this.nextPayday,
    errors: Map.unmodifiable(errors ?? this.errors),
    phase: phase ?? this.phase,
    busy: busy ?? this.busy,
    saved: saved ?? this.saved,
  );
}

/// The salary income source (employer, monthly salary, payday), backed by
/// `/setup/income`. The form edits a draft; [save] sends it.
class SetupController extends Notifier<SetupState> {
  int _generation = 0;

  SetupRepository get _repository => ref.read(setupRepositoryProvider);

  @override
  SetupState build() {
    final userId = ref.watch(sessionUserIdProvider);
    final generation = ++_generation;
    ref.onDispose(() => _generation++);
    if (userId == null) return const SetupState(phase: ContentPhase.ready);
    Future.microtask(() {
      if (ref.mounted && generation == _generation) load();
    });
    return const SetupState();
  }

  SetupState _adopt(Income income, {bool keepDraft = false}) => state.copyWith(
    employer: keepDraft ? null : income.employerName,
    salaryInput: keepDraft ? null : Money.plain(income.monthlyAmount),
    salaryMinor: income.monthlyAmount,
    payDay: keepDraft ? null : income.paydayDay,
    nextPayday: income.nextPayday,
    phase: ContentPhase.ready,
    saved: true,
  );

  Future<void> load() async {
    final generation = _generation;
    state = state.copyWith(
      phase: state.saved ? ContentPhase.refreshing : ContentPhase.loading,
    );
    try {
      final income = await _repository.income();
      if (!ref.mounted || generation != _generation) return;
      // Never overwrite what the user has started typing.
      final typing =
          state.employer.isNotEmpty ||
          state.salaryInput.isNotEmpty ||
          (state.payDay != null && !state.saved);
      state = income == null
          ? state.copyWith(phase: ContentPhase.ready)
          : _adopt(income, keepDraft: typing && !state.saved);
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(phase: ContentPhase.failure(error));
    }
  }

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

  /// Validates the draft and saves it. Returns false when it was not saved.
  Future<bool> save() async {
    if (state.busy) return false;
    final salary = Money.parse(state.salaryInput);
    final employer = state.employer.trim();
    final payDay = state.payDay;
    final errors = <String, String>{};
    if (employer.isEmpty) {
      errors['employer'] = 'Enter your employer or income source.';
    } else if (employer.length > 120) {
      errors['employer'] = 'Use at most 120 characters.';
    }
    if (salary == null || salary <= 0) {
      errors['salary'] = 'Enter a monthly salary greater than zero.';
    }
    if (payDay == null) errors['day'] = 'Select your expected pay day.';
    if (salary == null || payDay == null || errors.isNotEmpty) {
      state = state.copyWith(errors: errors);
      return false;
    }
    final generation = _generation;
    state = state.copyWith(busy: true, errors: const {});
    try {
      final result = await _repository.saveIncome(
        employerName: employer,
        monthlyAmount: salary,
        paydayDay: payDay,
      );
      if (!ref.mounted || generation != _generation) return false;
      state = _adopt(result.income).copyWith(busy: false);
      ref
          .read(accountControllerProvider.notifier)
          .apply(onboarding: result.onboarding);
      ref.read(dashboardControllerProvider.notifier).load();
      return true;
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return false;
      state = state.copyWith(
        busy: false,
        errors: switch (error) {
          ApiException() when error.fieldError('employerName') != null => {
            'employer': 'Check your employer and try again.',
          },
          ApiException() when error.fieldError('monthlyAmount') != null => {
            'salary': 'Enter a valid monthly salary.',
          },
          ApiException() when error.fieldError('paydayDay') != null => {
            'day': 'Select your expected pay day.',
          },
          _ => {'form': describeError(error)},
        },
      );
      return false;
    }
  }
}

final setupControllerProvider = NotifierProvider<SetupController, SetupState>(
  SetupController.new,
);
