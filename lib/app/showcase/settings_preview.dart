import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/settings/presentation/controllers/settings_controller.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_controller.dart';

void loadSettingsPreview(WidgetRef ref) {
  ref
      .read(authControllerProvider.notifier)
      .validateSignup('Paul', 'Clarke', 'paul@example.test');
  ref.read(kycControllerProvider.notifier)
    ..selectCountry(previewCountries.first)
    ..validateBasics('8000000000');
  ref
      .read(setupControllerProvider.notifier)
      .saveSalaryProfile(
        employer: 'Talent Nation',
        salaryInput: '850000',
        salaryMinor: 85000000,
        payDay: 21,
      );
  ref.read(settingsControllerProvider.notifier).loadSampleDevices();
}
