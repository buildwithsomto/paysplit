import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SalaryAccountStatus {
  notProvisioned,
  pending,
  failed,
  providerUnavailable,
  ready;

  String get label => switch (this) {
    notProvisioned => 'Account not provisioned',
    pending => 'Salary account pending',
    failed => 'Account setup unsuccessful',
    providerUnavailable => 'Provider temporarily unavailable',
    ready => 'Sample salary account',
  };
}

@immutable
class SalaryAccountState {
  const SalaryAccountState({
    this.status = SalaryAccountStatus.notProvisioned,
    this.preview = false,
    this.checking = false,
    this.checked = false,
    this.expectedSalaryDate,
  });
  final SalaryAccountStatus status;
  final bool preview, checking, checked;
  final DateTime? expectedSalaryDate;
  bool get hasDetails => preview && status == SalaryAccountStatus.ready;
  bool get needsAttention =>
      status != SalaryAccountStatus.notProvisioned &&
      (status != SalaryAccountStatus.ready || expectedSalaryDate != null);
}

/// UI scenarios only. Checking a sample never provisions an account, confirms
/// salary or makes funds eligible for an allocation.
class SalaryAccountController extends Notifier<SalaryAccountState> {
  Timer? _check;

  @override
  SalaryAccountState build() {
    ref.onDispose(() => _check?.cancel());
    return const SalaryAccountState();
  }

  void selectPreview(
    SalaryAccountStatus status, {
    DateTime? expectedSalaryDate,
  }) {
    _check?.cancel();
    state = SalaryAccountState(
      status: status,
      preview: status != SalaryAccountStatus.notProvisioned,
      expectedSalaryDate: status == SalaryAccountStatus.ready
          ? expectedSalaryDate
          : null,
    );
  }

  void checkPreview() {
    if (!state.preview || state.checking) return;
    final previous = state;
    state = SalaryAccountState(
      status: previous.status,
      preview: true,
      checking: true,
      expectedSalaryDate: previous.expectedSalaryDate,
    );
    _check = Timer(const Duration(milliseconds: 650), () {
      state = SalaryAccountState(
        status: previous.status,
        preview: true,
        checked: true,
        expectedSalaryDate: previous.expectedSalaryDate,
      );
    });
  }
}

final salaryAccountProvider =
    NotifierProvider<SalaryAccountController, SalaryAccountState>(
      SalaryAccountController.new,
    );
