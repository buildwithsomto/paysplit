import 'package:flutter/material.dart';
import 'package:paysplit/features/rules/presentation/screens/run_now_screen.dart';
import 'package:paysplit/core/config/app_config.dart';
import 'package:paysplit/features/kyc/presentation/screens/kyc_code_screen.dart';
import 'package:paysplit/features/settings/presentation/screens/settings_screen.dart';
import 'package:paysplit/features/settings/presentation/screens/profile_details_screen.dart';
import 'package:paysplit/features/settings/presentation/screens/notification_preferences_screen.dart';
import 'package:paysplit/features/settings/presentation/screens/change_password_screen.dart';
import 'package:paysplit/features/settings/presentation/screens/device_management_screen.dart';
import 'package:paysplit/features/settings/presentation/screens/security_preview_screen.dart';
import 'package:paysplit/features/history/presentation/screens/history_screen.dart';
import 'package:paysplit/features/history/presentation/screens/transaction_detail_screen.dart';
import 'package:paysplit/core/routing/app_sheet_page.dart';
import 'package:paysplit/features/rules/presentation/screens/rules_screen.dart';
import 'package:paysplit/features/rules/presentation/screens/rule_editor_screen.dart';
import 'package:paysplit/features/rules/presentation/screens/rule_detail_screen.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/features/destinations/presentation/screens/destinations_screen.dart';
import 'package:paysplit/features/destinations/presentation/screens/destination_detail_screen.dart';
import 'package:paysplit/features/setup/presentation/screens/setup_destination_route.dart';
import 'package:paysplit/features/setup/presentation/screens/setup_progress_sheet.dart';
import 'package:paysplit/features/setup/presentation/screens/salary_setup_screen.dart';
import 'package:paysplit/app/navigation/app_navigation_shell.dart';
import 'package:paysplit/features/home/presentation/screens/home_screen.dart';
import 'package:paysplit/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:paysplit/features/salary/presentation/screens/salary_account_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/app/showcase/app_showcase_screen.dart';
import 'package:paysplit/app/startup/app_splash_screen.dart';
import 'package:paysplit/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:paysplit/features/auth/presentation/screens/login_screen.dart';
import 'package:paysplit/features/auth/presentation/screens/password_screen.dart';
import 'package:paysplit/features/auth/presentation/screens/signup_screen.dart';
import 'package:paysplit/features/auth/presentation/screens/verification_screen.dart';
import 'package:paysplit/features/auth/presentation/screens/welcome_screen.dart';

import 'package:paysplit/features/kyc/presentation/screens/profile_basics_screen.dart';
import 'package:paysplit/features/kyc/presentation/screens/identity_screen.dart';
import 'package:paysplit/features/kyc/presentation/screens/liveness_screen.dart';
import 'package:paysplit/features/kyc/presentation/screens/kyc_result_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final showcase = ref.watch(appConfigProvider).showcaseEnabled;
  final router = GoRouter(
    restorationScopeId: 'paysplit_routes',
    initialLocation: showcase
        ? const String.fromEnvironment('INITIAL_ROUTE', defaultValue: '/')
        : '/',
    redirect: (context, state) =>
        !showcase &&
            (state.uri.path == '/showcase' ||
                state.uri.path == '/splash-preview')
        ? '/'
        : null,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AppSplashScreen()),
      GoRoute(
        path: '/splash-preview',
        builder: (context, state) => const AppSplashScreen(advance: false),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/signup/password',
        builder: (context, state) => const PasswordScreen(creating: true),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const PasswordScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/showcase',
        builder: (context, state) => const AppShowcaseScreen(),
      ),
      ShellRoute(
        restorationScopeId: 'main_tabs',
        pageBuilder: (context, state, child) => MaterialPage<void>(
          key: state.pageKey,
          restorationId: 'main_tabs_page',
          child: AppNavigationShell(location: state.uri.path, child: child),
        ),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/destinations',
            builder: (context, state) => const DestinationsScreen(),
          ),
          GoRoute(
            path: '/rules',
            builder: (context, state) => const RulesScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/transactions/:id/receipt',
        builder: (context, state) => TransactionDetailScreen(
          id: state.pathParameters['id']!,
          receipt: true,
        ),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) =>
            TransactionDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/activity/:id',
        builder: (context, state) => ActivityHistoryRoute(
          destinationId: state.pathParameters['id']!,
          walletActivity: state.uri.queryParameters['wallet'] == 'true',
        ),
      ),
      GoRoute(
        path: '/wallets/:id',
        builder: (context, state) =>
            DestinationDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/beneficiaries/:id',
        builder: (context, state) => DestinationDetailScreen(
          id: state.pathParameters['id']!,
          beneficiary: true,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/salary-account',
        builder: (context, state) => const SalaryAccountScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/details',
        builder: (context, state) => const ProfileDetailsScreen(),
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: '/profile/password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/profile/devices',
        builder: (context, state) => const DeviceManagementScreen(),
      ),
      GoRoute(
        path: '/profile/delete',
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: '/profile/security',
        builder: (context, state) => SecurityPreviewScreen(
          biometrics: state.uri.queryParameters['kind'] == 'biometrics',
        ),
      ),
      GoRoute(
        path: '/kyc',
        builder: (context, state) => const ProfileBasicsScreen(),
      ),
      GoRoute(
        path: '/kyc/identity',
        builder: (context, state) => const IdentityScreen(),
      ),
      GoRoute(
        path: '/kyc/code',
        builder: (context, state) => const KycCodeScreen(),
      ),
      GoRoute(
        path: '/kyc/liveness',
        builder: (context, state) => const LivenessScreen(),
      ),
      GoRoute(
        path: '/kyc/result',
        builder: (context, state) => const KycResultScreen(),
      ),
      GoRoute(
        path: '/setup/progress',
        pageBuilder: (context, state) => AppSheetPage(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const SetupProgressSheet(),
        ),
      ),
      GoRoute(
        path: '/setup/wallet',
        builder: (context, state) => const SetupDestinationRoute(),
      ),
      GoRoute(
        path: '/setup/beneficiary',
        builder: (context, state) =>
            const SetupDestinationRoute(beneficiary: true),
      ),
      GoRoute(
        path: '/setup/rule',
        builder: (context, state) => RuleEditorRoute(
          setup: true,
          destinationId:
              state.uri.queryParameters['beneficiary'] ??
              state.uri.queryParameters['wallet'],
          type: state.uri.queryParameters.containsKey('beneficiary')
              ? RuleDestinationType.beneficiary
              : RuleDestinationType.wallet,
        ),
      ),
      GoRoute(
        path: '/run-now',
        builder: (context, state) => const RunNowScreen(),
      ),
      GoRoute(
        path: '/split-history',
        builder: (context, state) =>
            SplitHistoryScreen(ruleId: state.uri.queryParameters['rule']),
      ),
      GoRoute(
        path: '/split-history/:id',
        builder: (context, state) =>
            SplitExecutionScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/rules/new',
        pageBuilder: (context, state) => AppSheetPage(
          key: state.pageKey,
          child: RuleEditorRoute(
            id: state.uri.queryParameters['id'],
            destinationId:
                state.uri.queryParameters['beneficiary'] ??
                state.uri.queryParameters['wallet'],
            type: state.uri.queryParameters.containsKey('beneficiary')
                ? RuleDestinationType.beneficiary
                : RuleDestinationType.wallet,
          ),
        ),
      ),
      GoRoute(
        path: '/rules/saved',
        redirect: (context, state) {
          final id = state.uri.queryParameters['id'];
          return ref.read(rulesControllerProvider).any((rule) => rule.id == id)
              ? null
              : '/rules';
        },
        pageBuilder: (context, state) => AppSheetPage(
          key: state.pageKey,
          child: RuleSavedSheet(id: state.uri.queryParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/rules/:id',
        builder: (context, state) =>
            RuleDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SalarySetupScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
