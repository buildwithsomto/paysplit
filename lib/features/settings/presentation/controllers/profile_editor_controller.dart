import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_controller.dart';

/// Stages validation before updating the existing presentation-state owners.
class ProfileEditorController extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};
  void clearError(String key) =>
      state = Map.unmodifiable({...state}..remove(key));
  bool save({
    required String name,
    required String phone,
    required String employer,
    required String salary,
    required int? payDay,
  }) {
    final kyc = ref.read(kycControllerProvider);
    final locked = kyc.status.identityFieldsLocked;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final amount = Money.parse(salary);
    final errors = <String, String>{
      if (!locked && name.trim().isEmpty) 'name': 'Enter your full name.',
      if (!locked &&
          (digits.length < 7 || digits.length + kyc.dialCode.length - 1 > 15))
        'phone': 'Enter a valid phone number.',
      if (employer.trim().isEmpty)
        'employer': 'Enter your employer or income source.',
      if (amount == null || amount <= 0)
        'salary': 'Enter a monthly salary greater than zero.',
      if (payDay == null || payDay < 1 || payDay > 31)
        'day': 'Select your expected pay day.',
    };
    state = Map.unmodifiable(errors);
    if (errors.isNotEmpty) {
      return false;
    }
    if (!locked) {
      ref.read(authControllerProvider.notifier).updateDisplayName(name);
      ref.read(kycControllerProvider.notifier).updateProfilePhone(digits);
    }
    ref
        .read(setupControllerProvider.notifier)
        .saveSalaryProfile(
          employer: employer,
          salaryInput: salary,
          salaryMinor: amount!,
          payDay: payDay!,
        );
    return true;
  }
}

final profileEditorProvider =
    NotifierProvider.autoDispose<ProfileEditorController, Map<String, String>>(
      ProfileEditorController.new,
    );
