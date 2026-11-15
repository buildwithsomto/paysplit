import 'package:paysplit/features/salary/presentation/controllers/salary_account_controller.dart';
import 'package:paysplit/features/salary/presentation/widgets/salary_account_status_card.dart';
import 'package:paysplit/app/navigation/app_navigation_insets.dart';
import 'package:paysplit/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_progress_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/features/home/presentation/widgets/balance_carousel.dart';
import 'package:paysplit/features/home/presentation/widgets/cash_flow_card.dart';
import 'package:paysplit/features/home/presentation/widgets/recent_activity_card.dart';
import 'package:paysplit/features/home/presentation/widgets/salary_partition_card.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_controller.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final account = ref.watch(salaryAccountProvider);
    final configured = ref.watch(setupProgressProvider).configurationComplete;
    final payDay = ref.watch(setupControllerProvider.select((s) => s.payDay));
    final name = ref.watch(authControllerProvider.select((s) => s.firstName));
    final kycStatus = ref.watch(kycControllerProvider.select((s) => s.status));
    final verified = kycStatus == KycStatus.approved;
    final top = MediaQuery.paddingOf(context).top;
    return SingleChildScrollView(
      restorationId: 'home_scroll',
      key: const PageStorageKey('home-scroll'),
      child: Stack(
        children: [
          Container(
            height: top + 313,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Color(0xFF121212)],
              ),
            ),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(.3, 1.3),
                  radius: 1.2,
                  colors: [Color(0x5533A7F5), Color(0x0033A7F5)],
                ),
              ),
              child: SizedBox.expand(),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Semantics(
                            label: 'Profile',
                            button: true,
                            child: InkWell(
                              onTap: () => context.push('/profile'),
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: const ProfileAvatar(
                                    size: 40,
                                    placeholderAsset:
                                        'assets/icons/dashboard/431cb.png',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 2,
                              children: [
                                Text(
                                  'Hello, ${name.isEmpty ? 'there' : name}!',
                                  style: const TextStyle(
                                    fontFamily: 'Arimo',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'EEEE, MMM d, y',
                                  ).format(DateTime.now()),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.2,
                                    color: Color(0xA3FFFFFF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Notifications',
                            onPressed: () => context.push('/notifications'),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0x12FFFFFF),
                            ),
                            icon: const AppSvgIcon(
                              'assets/icons/dashboard/69f2f.svg',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 44),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 33),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => context.push('/notifications'),
                          child: Ink(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                colors: [Color(0xFF102F40), Colors.black],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 12,
                              children: [
                                const Row(
                                  spacing: 4,
                                  children: [
                                    AppSvgIcon(
                                      'assets/icons/dashboard/28978.svg',
                                      size: 16,
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Notifications',
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'View',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14,
                                        height: 1,
                                      ),
                                    ),
                                    AppSvgIcon(
                                      'assets/icons/dashboard/d3906.svg',
                                      size: 16,
                                    ),
                                  ],
                                ),
                                Text(
                                  'View your salary, split and account updates.',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 17 / 14,
                                  ),
                                ),
                                Row(
                                  spacing: 2,
                                  children: [
                                    for (var i = 0; i < 3; i++)
                                      Container(
                                        width: i == 0 ? 15 : 6,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: i == 0
                                              ? AppColors.primary
                                              : const Color(0xFF17415D),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 45),
                    BalanceCarousel(
                      state: state,
                      accountCaption: account.hasDetails
                          ? 'Sample · Paul Clarke'
                          : account.status.label,
                      nextSalaryLabel: payDay == null
                          ? null
                          : DateFormat('MMM d, y').format(
                              SetupController.nextExpectedDate(
                                DateTime.now(),
                                payDay,
                              ),
                            ),
                      onToggleVisibility: ref
                          .read(dashboardControllerProvider.notifier)
                          .toggleBalances,
                      onAccount: () => context.push('/salary-account'),
                    ),
                    const SizedBox(height: 11),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        spacing: 20,
                        children: [
                          if (!verified || (!state.populated && !configured))
                            Material(
                              color: const Color(0xFFF5FBFF),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => context.push('/setup/progress'),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.primaryBorder,
                                    ),
                                  ),
                                  child: Row(
                                    spacing: 12,
                                    children: [
                                      Image.asset(
                                        'assets/icons/dashboard/5e035.png',
                                        width: 24,
                                        height: 32,
                                        excludeFromSemantics: true,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          spacing: 6,
                                          children: [
                                            Text(
                                              verified
                                                  ? 'Complete Setup Checklist'
                                                  : kycStatus ==
                                                        KycStatus.unverified
                                                  ? 'Complete Onboarding'
                                                  : kycStatus.label,
                                              style: const TextStyle(
                                                color: Color(0xFF006BAA),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              verified
                                                  ? 'Add your salary source and first split rule.'
                                                  : switch (kycStatus) {
                                                      KycStatus.inReview =>
                                                        'Your verification is pending review. Financial actions remain restricted.',
                                                      KycStatus
                                                          .actionRequired ||
                                                      KycStatus.rejected ||
                                                      KycStatus
                                                          .reverificationRequired =>
                                                        'Review your verification status and next steps. Financial actions remain restricted.',
                                                      _ =>
                                                        'Verify your account to unlock splitting and get a dedicated account number.',
                                                    },
                                              style: const TextStyle(
                                                fontSize: 12,
                                                height: 1.4,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const AppSvgIcon(
                                        'assets/icons/dashboard/9c184.svg',
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (account.needsAttention)
                            const SalaryAccountStatusCard(compact: true),
                          SalaryPartitionCard(
                            state: state,
                            onRules: () => context.go('/rules'),
                          ),
                          CashFlowCard(state: state),
                          RecentActivityCard(
                            showAmounts: state.balancesVisible,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: AppNavigationInsets.bottomOf(context) + 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
