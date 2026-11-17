import 'package:paysplit/features/salary/presentation/controllers/salary_account_controller.dart';
import 'package:paysplit/features/salary/presentation/widgets/salary_account_status_card.dart';
import 'package:paysplit/app/navigation/app_navigation_insets.dart';
import 'package:paysplit/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_progress_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/features/home/presentation/widgets/balance_carousel.dart';
import 'package:paysplit/features/home/presentation/widgets/cash_flow_card.dart';
import 'package:paysplit/features/home/presentation/widgets/recent_activity_card.dart';
import 'package:paysplit/features/home/presentation/widgets/salary_partition_card.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/features/kyc/data/models/kyc_models.dart';
import 'package:paysplit/widgets/feedback/content_status_card.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';
import 'package:paysplit/widgets/layout/header_overscroll_fill.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _headerGradient = LinearGradient(
    colors: [Colors.black, Color(0xFF121212)],
  );

  /// The header date as designed: "Saturday, Dec 25th, 2025".
  static String _today(DateTime date) {
    final day = date.day;
    final suffix = day >= 11 && day <= 13
        ? 'th'
        : switch (day % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    return '${DateFormat('EEEE, MMM d').format(date)}$suffix, ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final dashboard = ref.read(dashboardControllerProvider.notifier);
    final progress = ref.watch(setupProgressProvider);
    final accountLoaded = ref.watch(
      accountControllerProvider.select((s) => s.user != null),
    );
    final name = ref.watch(
      accountControllerProvider.select((s) => s.firstName),
    );
    final kycStatus = progress.identityStatus;
    final verified = progress.identityComplete;
    final unread = state.unreadNotifications;
    final firstLoad = state.phase == ContentPhase.loading && !state.hasData;
    // The first load failed: the notice says why, and the cards that would
    // only show zeros stay hidden.
    final unknown = !state.hasData && state.phase.isFailure;
    final accountPending = ref.watch(
      salaryAccountProvider.select(
        (s) => s.account != null && !s.account!.isActive,
      ),
    );
    final top = MediaQuery.paddingOf(context).top;
    return RefreshIndicator(
      onRefresh: dashboard.load,
      edgeOffset: top,
      child: SingleChildScrollView(
        restorationId: 'home_scroll',
        key: const PageStorageKey('home-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            HeaderOverscrollFill(
              gradient: _headerGradient,
              child: Container(
                height: top + 313,
                decoration: const BoxDecoration(gradient: _headerGradient),
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
                                    name.isEmpty ? 'Hello!' : 'Hello, $name!',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Arimo',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _today(DateTime.now()),
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
                              tooltip: unread == 0
                                  ? 'Notifications'
                                  : 'Notifications, $unread unread',
                              onPressed: () => context.push('/notifications'),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0x12FFFFFF),
                              ),
                              icon: Badge(
                                isLabelVisible: unread > 0,
                                label: Text(unread > 99 ? '99+' : '$unread'),
                                backgroundColor: const Color(0xFFF04438),
                                child: const AppSvgIcon(
                                  'assets/icons/dashboard/69f2f.svg',
                                ),
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
                                          'Notification',
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
                                    unread == 0
                                        ? 'View your salary, split and account updates.'
                                        : 'You have $unread unread ${unread == 1 ? 'notification' : 'notifications'}.',
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
                        onToggleVisibility: dashboard.toggleBalances,
                        onAccount: () => context.push('/salary-account'),
                      ),
                      const SizedBox(height: 11),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          spacing: 20,
                          children: [
                            if (state.phase != ContentPhase.ready &&
                                !(state.phase == ContentPhase.refreshing &&
                                    state.hasData))
                              ContentStatusCard(
                                phase: state.phase,
                                hasContent: state.hasData,
                                subject: 'Dashboard',
                                items: 'balances',
                                message: state.message,
                                updatedAt: state.updatedAt,
                                onRetry: dashboard.load,
                                skeleton: const Column(
                                  spacing: 20,
                                  children: [
                                    // Salary partition: heading, ring, totals.
                                    SkeletonSurface(
                                      radius: 16,
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SkeletonBox(
                                                width: 130,
                                                height: 16,
                                              ),
                                              SkeletonBox(width: 80),
                                            ],
                                          ),
                                          SizedBox(height: 28),
                                          SkeletonBox.circle(180),
                                          SizedBox(height: 28),
                                          Row(
                                            spacing: 16,
                                            children: [
                                              Expanded(
                                                child: SkeletonBox(height: 36),
                                              ),
                                              Expanded(
                                                child: SkeletonBox(height: 36),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Cash flow: heading and chart.
                                    SkeletonSurface(
                                      radius: 16,
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        spacing: 20,
                                        children: [
                                          SkeletonBox(width: 110, height: 16),
                                          SkeletonBox.card(
                                            height: 160,
                                            radius: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Hidden until the account has loaded, so a finished
                            // setup never flashes the onboarding prompt.
                            if (accountLoaded && !progress.complete)
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
                                                    : switch (kycStatus) {
                                                        KycStatus.unverified =>
                                                          'Complete Onboarding',
                                                        KycStatus.inProgress =>
                                                          'Continue Verification',
                                                        KycStatus.inReview =>
                                                          'Verification in Review',
                                                        KycStatus
                                                            .actionRequired =>
                                                          'One More Step Needed',
                                                        KycStatus.rejected =>
                                                          'Verification Unsuccessful',
                                                        _ => kycStatus.label,
                                                      },
                                                style: const TextStyle(
                                                  color: AppColors.action,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                verified
                                                    ? 'Add your salary source and first split rule.'
                                                    : switch (kycStatus) {
                                                        KycStatus.inReview =>
                                                          'We’re reviewing your details. Splitting unlocks once you’re approved.',
                                                        KycStatus.inProgress =>
                                                          'Pick up where you left off to unlock splitting and your account number.',
                                                        KycStatus
                                                            .actionRequired ||
                                                        KycStatus.rejected ||
                                                        KycStatus
                                                            .reverificationRequired =>
                                                          'Part of your verification needs another try before you can split your salary.',
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
                            // Shown only once the card has something to say,
                            // so an empty one never doubles the gap here.
                            if (verified && accountPending)
                              const SalaryAccountStatusCard(compact: true),
                            // The placeholders above stand in for these
                            // until the first load finishes.
                            if (!firstLoad && !unknown) ...[
                              SalaryPartitionCard(
                                state: state,
                                onRules: () => context.go('/rules'),
                              ),
                              CashFlowCard(
                                state: state,
                                onSelectRange: dashboard.selectCashFlowRange,
                                onRetry: dashboard.load,
                              ),
                              RecentActivityCard(
                                showAmounts: state.balancesVisible,
                              ),
                            ],
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
      ),
    );
  }
}
