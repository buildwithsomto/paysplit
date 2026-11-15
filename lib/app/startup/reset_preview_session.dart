import 'package:paysplit/features/salary/presentation/controllers/salary_account_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/split_execution_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';
import 'package:paysplit/features/history/presentation/controllers/history_filter_controller.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/features/settings/presentation/controllers/settings_controller.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_controller.dart';

/// Clears the local UI session. Server revocation belongs to API integration.
void resetPreviewSession(WidgetRef ref) {
  ref.read(authControllerProvider.notifier).reset();
  ref.invalidate(kycControllerProvider);
  ref.invalidate(setupControllerProvider);
  ref.invalidate(rulesControllerProvider);
  ref.invalidate(splitExecutionProvider);
  ref.invalidate(destinationsControllerProvider);
  ref.invalidate(historyControllerProvider);
  ref.invalidate(historyFilterProvider);
  ref.invalidate(dashboardControllerProvider);
  ref.invalidate(salaryAccountProvider);
  ref.invalidate(notificationsControllerProvider);
  ref.invalidate(settingsControllerProvider);
}
