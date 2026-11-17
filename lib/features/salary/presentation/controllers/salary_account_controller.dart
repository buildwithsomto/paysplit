import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/core/session/ledger_version.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/features/salary/data/models/salary_account.dart';
import 'package:paysplit/features/salary/data/repositories/salary_account_repository.dart';

/// The Nigerian IDs accepted by `POST /salary-account/identity`.
enum SalaryIdentityMethod {
  bvn('bvn', 'BVN'),
  nin('nin', 'NIN');

  const SalaryIdentityMethod(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

@immutable
class SalaryAccountState {
  const SalaryAccountState({
    this.account,
    this.phase = ContentPhase.loading,
    this.message,
    this.updatedAt,
    this.method = SalaryIdentityMethod.bvn,
    this.errors = const {},
    this.busy = false,
  });

  /// Null until the first successful load.
  final SalaryAccount? account;
  final ContentPhase phase;

  /// The API's explanation of the last failed load.
  final String? message;
  final DateTime? updatedAt;

  /// The ID type chosen in the "add your BVN or NIN" form.
  final SalaryIdentityMethod method;

  /// Keyed by form field; `form` holds a failure that belongs to no field.
  final Map<String, String> errors;

  /// An identity submission is in flight.
  final bool busy;

  bool get hasData => account != null;

  SalaryAccountState copyWith({
    SalaryAccount? account,
    ContentPhase? phase,
    String? message,
    bool clearMessage = false,
    DateTime? updatedAt,
    SalaryIdentityMethod? method,
    Map<String, String>? errors,
    bool? busy,
  }) => SalaryAccountState(
    account: account ?? this.account,
    phase: phase ?? this.phase,
    message: clearMessage ? null : message ?? this.message,
    updatedAt: updatedAt ?? this.updatedAt,
    method: method ?? this.method,
    errors: Map.unmodifiable(errors ?? this.errors),
    busy: busy ?? this.busy,
  );
}

/// The dedicated account salary is paid into, backed by `/salary-account`.
/// Identity numbers are passed straight to the API and never enter state.
class SalaryAccountController extends Notifier<SalaryAccountState> {
  int _generation = 0;
  bool _loading = false;

  SalaryAccountRepository get _repository =>
      ref.read(salaryAccountRepositoryProvider);

  @override
  SalaryAccountState build() {
    final userId = ref.watch(sessionUserIdProvider);
    final generation = ++_generation;
    ref.listen(ledgerVersionProvider, (_, _) => load());
    _loading = false;
    ref.onDispose(() => _generation++);
    if (userId == null) {
      return const SalaryAccountState(phase: ContentPhase.ready);
    }
    Future.microtask(() {
      if (ref.mounted && generation == _generation) load();
    });
    return const SalaryAccountState();
  }

  /// First load, "Check again" and Retry.
  Future<void> load() async {
    if (ref.read(sessionUserIdProvider) == null || _loading) return;
    final generation = _generation;
    _loading = true;
    state = state.copyWith(
      phase: state.hasData ? ContentPhase.refreshing : ContentPhase.loading,
    );
    try {
      final account = await _repository.account();
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        account: account,
        phase: ContentPhase.ready,
        clearMessage: true,
        updatedAt: DateTime.now(),
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      // Keep the last loaded details on screen; only the phase changes.
      state = state.copyWith(
        phase: ContentPhase.failure(error),
        message: describeError(error),
      );
    } finally {
      if (generation == _generation) _loading = false;
    }
  }

  void selectMethod(SalaryIdentityMethod method) {
    if (state.busy || method == state.method) return;
    state = state.copyWith(method: method, errors: const {});
  }

  void clearErrors() {
    if (state.errors.isNotEmpty) state = state.copyWith(errors: const {});
  }

  /// Supplies the BVN or NIN the banking partner needs to issue the account.
  Future<bool> addIdentity(String idNumber) async {
    if (state.busy) return false;
    final digits = idNumber.trim();
    if (!RegExp(r'^\d{11}$').hasMatch(digits)) {
      state = state.copyWith(
        errors: {'idNumber': 'Enter your 11-digit ${state.method.label}.'},
      );
      return false;
    }
    final generation = _generation;
    state = state.copyWith(busy: true, errors: const {});
    try {
      final account = await _repository.addIdentity(
        method: state.method.apiValue,
        idNumber: digits,
      );
      if (!ref.mounted || generation != _generation) return false;
      state = state.copyWith(
        account: account,
        phase: ContentPhase.ready,
        busy: false,
        updatedAt: DateTime.now(),
      );
      // The dashboard shows the same account and the onboarding progress.
      ref.read(dashboardControllerProvider.notifier).load();
      return true;
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return false;
      final code = error is ApiException ? error.code : '';
      final message = describeError(error);
      state = state.copyWith(
        busy: false,
        errors: switch (code) {
          'IDENTITY_NOT_FOUND' ||
          'NAME_MISMATCH' ||
          'DOB_MISMATCH' ||
          'ID_ALREADY_USED' => {'idNumber': message},
          _ => {'form': message},
        },
      );
      // The account moved on without this ID; show where it stands now.
      if (code == 'SALARY_ACCOUNT_IDENTITY_NOT_NEEDED') load();
      return false;
    }
  }

  /// Sandbox tools only: asks a dev/QA backend to run its real salary
  /// credit flow with simulated money, then refreshes what that changes.
  /// Returns the outcome in words to show on the sandbox screen.
  Future<String> simulateCredit({
    required int amount,
    String? senderName,
    String? narration,
  }) async {
    final generation = _generation;
    try {
      await _repository.simulateCredit(
        amount: amount,
        senderName: senderName,
        narration: narration,
      );
      if (ref.mounted && generation == _generation) {
        ref.read(ledgerVersionProvider.notifier).moved();
      }
      return 'Salary credit simulated. Your balances are refreshing.';
    } on Object catch (error) {
      return describeError(error);
    }
  }
}

final salaryAccountProvider =
    NotifierProvider<SalaryAccountController, SalaryAccountState>(
      SalaryAccountController.new,
    );
