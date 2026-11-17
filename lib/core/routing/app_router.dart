import 'package:flutter/material.dart';
import 'package:paysplit/features/rules/presentation/screens/run_now_screen.dart';
import 'package:paysplit/core/config/app_config.dart';
import 'package:paysplit/core/session/session_controller.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/settings/presentation/screens/settings_screen.dart';
import 'package:paysplit/features/settings/presentation/screens/profile_details_screen.dart';
import 'package:paysplit/features/settings/presentation/screens/notification_preferences_screen.dart';
import 'package:paysplit/features/settings/presentation/screens/change_password_screen.dart';
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
import 'package:paysplit/features/salary/presentation/screens/sandbox_tools_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// Routes a signed-out visitor may open.
const _publicPaths = {
  '/',
  '/login',
  '/signup',
  '/signup/password',
  '/forgot-password',
  '/verify',
  '/reset-password',
};

/// Entry screens a signed-in user is moved past.
const _signedOutOnlyPaths = {'/login', '/signup', '/forgot-password'};

/// The rule editor for a link's query: `id` opens an existing rule, while
/// `beneficiary` or `wallet` starts a new one for that destination. During
/// setup the only destination a link names is the beneficiary just added.
RuleEditorRoute _ruleEditor(GoRouterState state, {bool setup = false}) {
  final query = state.uri.queryParameters;
  final beneficiary = query['beneficiary'];
  return RuleEditorRoute(
    setup: setup,
    id: setup ? null : query['id'],
    destinationId: beneficiary ?? (setup ? null : query['wallet']),
    type: beneficiary != null
        ? RuleDestinationType.beneficiary
        : RuleDestinationType.wallet,
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final sandboxTools = ref.watch(appConfigProvider).sandboxToolsEnabled;
  // Re-runs the guard whenever the session starts, ends or expires.
  final sessionChanges = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (previous, next) {
    if (previous?.status != next.status) sessionChanges.value++;
  });
  ref.onDispose(sessionChanges.dispose);
  final router = GoRouter(
    restorationScopeId: 'paysplit_routes',
    refreshListenable: sessionChanges,
    redirect: (context, state) {
      final path = state.uri.path;
      final public = _publicPaths.contains(path);
      return switch (ref.read(sessionControllerProvider).status) {
        // The splash restores the stored session before anything else opens.
        SessionStatus.unknown => public ? null : '/',
        SessionStatus.signedOut => public ? null : '/login',
        SessionStatus.authenticated =>
          _signedOutOnlyPaths.contains(path) ? '/home' : null,
      };
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AppSplashScreen()),
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
      if (sandboxTools)
        GoRoute(
          path: '/sandbox',
          builder: (context, state) => const SandboxToolsScreen(),
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
        path: '/kyc',
        builder: (context, state) => const ProfileBasicsScreen(),
      ),
      GoRoute(
        path: '/kyc/identity',
        builder: (context, state) => const IdentityScreen(),
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
        builder: (context, state) => _ruleEditor(state, setup: true),
      ),
      GoRoute(
        path: '/run-now',
        builder: (context, state) => const RunNowScreen(),
      ),
      GoRoute(
        path: '/split-history',
        builder: (context, state) => const SplitHistoryScreen(),
      ),
      GoRoute(
        path: '/split-history/:id',
        builder: (context, state) =>
            SplitExecutionScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/rules/new',
        pageBuilder: (context, state) =>
            AppSheetPage(key: state.pageKey, child: _ruleEditor(state)),
      ),
      GoRoute(
        path: '/rules/saved',
        redirect: (context, state) {
          final id = state.uri.queryParameters['id'];
          return ref.read(rulesControllerProvider).any((rule) => rule.id == id)
              ? null
              : '/rules';
        },
        pageBuilder: (context, state) =>
            AppSheetPage(key: state.pageKey, child: const RuleSavedSheet()),
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
