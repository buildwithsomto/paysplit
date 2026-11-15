import 'package:paysplit/features/salary/presentation/controllers/salary_account_controller.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/split_execution_controller.dart';
import 'package:paysplit/app/showcase/settings_preview.dart';
import 'package:paysplit/app/showcase/history_preview.dart';
import 'package:paysplit/app/showcase/dashboard_preview.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';
import 'package:paysplit/app/showcase/rules_preview.dart';
import 'package:paysplit/features/destinations/presentation/screens/wallet_editor_screen.dart';
import 'package:paysplit/features/destinations/presentation/screens/beneficiary_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:go_router/go_router.dart';

/// Development review entry points; never substitutes for product navigation.
class AppShowcaseScreen extends ConsumerWidget {
  const AppShowcaseScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('PaySplit UI review')),
    body: ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Local UI preview. Accounts, verification and transfers are not connected.',
          ),
        ),
        ListTile(
          title: const Text('Dashboard · empty'),
          onTap: () {
            loadDashboardPreview(ref, populated: false);
            context.push('/home');
          },
        ),
        ListTile(
          title: const Text('Dashboard · sample balances'),
          onTap: () {
            loadDashboardPreview(ref, populated: true);
            context.push('/home');
          },
        ),
        for (final status in [
          SalaryAccountStatus.pending,
          SalaryAccountStatus.failed,
          SalaryAccountStatus.providerUnavailable,
          SalaryAccountStatus.ready,
        ])
          ListTile(
            title: Text(
              status == SalaryAccountStatus.ready
                  ? 'Salary · expected but not received'
                  : 'Account · ${status.label}',
            ),
            onTap: () {
              ref
                  .read(dashboardControllerProvider.notifier)
                  .selectPreview(populated: false);
              ref
                  .read(kycControllerProvider.notifier)
                  .previewOutcome(KycStatus.approved);
              final today = DateTime.now();
              ref
                  .read(salaryAccountProvider.notifier)
                  .selectPreview(
                    status,
                    expectedSalaryDate: status == SalaryAccountStatus.ready
                        ? DateTime(today.year, today.month, today.day - 1)
                        : null,
                  );
              context.push('/salary-account');
            },
          ),
        ListTile(
          title: const Text('Split rules · sample configuration'),
          subtitle: const Text('Verified UI preview; no real allocations'),
          onTap: () {
            loadRulesPreview(ref);
            context.push('/rules');
          },
        ),
        ListTile(
          title: const Text('Run Now · mixed sample outcomes'),
          onTap: () {
            loadRulesPreview(ref);
            ref.read(splitExecutionProvider.notifier).loadSample();
            context.push('/run-now');
          },
        ),
        ListTile(
          title: const Text('History · sample transactions'),
          onTap: () {
            loadHistoryPreview(ref);
            context.push('/history');
          },
        ),
        ListTile(
          title: const Text('History · empty'),
          onTap: () {
            ref.read(historyControllerProvider.notifier).clearPreview();
            context.push('/history');
          },
        ),
        for (final scenario in <(String, ContentPhase, bool)>[
          ('History · offline with saved sample', ContentPhase.offline, true),
          ('History · initial loading', ContentPhase.loading, false),
          ('History · failed initial load', ContentPhase.error, false),
          ('History · failed refresh', ContentPhase.error, true),
        ])
          ListTile(
            title: Text(scenario.$1),
            onTap: () {
              loadHistoryPreview(ref);
              ref
                  .read(historyControllerProvider.notifier)
                  .previewPhase(scenario.$2, cached: scenario.$3);
              context.push('/history');
            },
          ),
        ListTile(
          title: const Text('Wallet activity · sample'),
          onTap: () {
            loadHistoryPreview(ref);
            context.push('/activity/sample-savings?wallet=true');
          },
        ),
        ListTile(
          title: const Text('Profile · sample account and devices'),
          onTap: () {
            loadSettingsPreview(ref);
            context.push('/profile');
          },
        ),
        ListTile(
          title: const Text('Create wallet · sheet'),
          onTap: () => showWalletEditor(context),
        ),
        ListTile(
          title: const Text('Add beneficiary · sheet'),
          onTap: () => showBeneficiaryEditor(context),
        ),
        for (final status in KycStatus.values)
          ListTile(
            title: Text('Verification · ${status.label}'),
            onTap: () {
              ref.read(kycControllerProvider.notifier).previewOutcome(status);
              context.push('/kyc/result');
            },
          ),
        for (final (label, path) in const [
          ('Account setup progress', '/setup/progress'),
          ('Split rules', '/rules'),
          ('Final setup step', '/setup/rule'),
          ('Wallets and beneficiaries', '/destinations'),
          ('First wallet setup', '/setup/wallet'),
          ('First beneficiary setup', '/setup/beneficiary'),
          ('Salary setup', '/setup'),
          ('Notifications', '/notifications'),
          ('Salary account', '/salary-account'),
          ('Splash', '/splash-preview'),
          ('Login', '/login'),
          ('Create account', '/signup'),
          ('Set password', '/signup/password'),
          ('Forgot password', '/forgot-password'),
          ('Verification', '/verify'),
          ('Reset password', '/reset-password'),
          ('Welcome', '/welcome'),
          ('Profile basics', '/kyc'),
          ('Identity document', '/kyc/identity'),
          ('Provider verification code', '/kyc/code'),
          ('Liveness', '/kyc/liveness'),
          ('Verification outcome', '/kyc/result'),
        ])
          ListTile(
            title: Text(label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(path),
          ),
      ],
    ),
  );
}
