import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/features/home/presentation/widgets/dashboard_card.dart';
import 'package:paysplit/features/salary/data/models/salary_account.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';

class BalanceCarousel extends StatefulWidget {
  const BalanceCarousel({
    required this.state,
    required this.onToggleVisibility,
    required this.onAccount,
    super.key,
  });
  final DashboardState state;
  final VoidCallback onToggleVisibility;
  final VoidCallback onAccount;
  @override
  State<BalanceCarousel> createState() => _BalanceCarouselState();
}

class _BalanceCarouselState extends State<BalanceCarousel> {
  final _pages = PageController(viewportFraction: .9);
  int _index = 0;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  String _amount(int value) => widget.state.summary == null
      ? '—'
      : dashboardAmount(value, visible: widget.state.balancesVisible);

  static String _count(int count, String noun) =>
      '$count $noun${count == 1 ? '' : 's'}';

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final summary = widget.state.summary;
    final account = summary?.salaryAccount;
    final allocation = summary?.splitAllocation;
    final wallets = summary?.wallets;
    final nextRun = summary?.nextSplitRun ?? summary?.income?.nextPayday;
    // Nothing has loaded and nothing is loading: the figures are unknown,
    // so no card claims "no wallets" or "no rules".
    const unavailable = 'Not available right now';
    final cards = [
      (
        'Salary Account Balance',
        _amount(account?.balance ?? 0),
        switch (account?.phase) {
          null => summary == null ? unavailable : 'Account not ready',
          SalaryAccountPhase.active => [
            ?account?.maskedAccountNumber,
            ?account?.accountName,
          ].join(' '),
          SalaryAccountPhase.pending => 'Setting up account',
          SalaryAccountPhase.failed => 'Account setup failed',
          SalaryAccountPhase.closed => 'Account closed',
          SalaryAccountPhase.notIssued => 'Account not ready',
        },
      ),
      (
        'Split Allocation',
        _amount(allocation?.amount ?? 0),
        summary == null
            ? unavailable
            : allocation == null || allocation.activeRules == 0
            ? 'No active split rules yet'
            : '${compactNumber(allocation.percentOfSalary)}% of salary · ${_count(allocation.activeRules, 'active rule')}',
      ),
      (
        'Total In Wallets',
        _amount(wallets?.total ?? 0),
        summary == null
            ? unavailable
            : wallets == null || wallets.activeCount == 0
            ? 'No wallets yet'
            : wallets.withTargetCount == 0
            ? _count(wallets.activeCount, 'wallet')
            : '${_count(wallets.activeCount, 'wallet')} · ${wallets.withTargetCount} with a target',
      ),
      (
        'Next Split Run',
        summary == null
            ? '—'
            : nextRun == null
            ? 'Not set'
            : DateFormat('MMM d, y').format(nextRun),
        summary == null
            ? unavailable
            : nextRun == null
            ? 'Add your salary source to schedule it'
            : 'Runs when your salary arrives',
      ),
    ];
    return Column(
      children: [
        SizedBox(
          height:
              (MediaQuery.sizeOf(context).width < 360 ? 160 : 140) +
              (scale - 1).clamp(0, 2) * 140,
          child: PageView.builder(
            controller: _pages,
            onPageChanged: (value) => setState(() => _index = value),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final (title, amount, caption) = cards[index];
              // First load: placeholders where the figures will be.
              final loading =
                  summary == null && widget.state.phase == ContentPhase.loading;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    gradient: index == 0
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFEAF6FF), Colors.white],
                          ),
                    border: Border.all(color: AppColors.primaryBorder),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: index == 0 ? widget.onAccount : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF171918),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (loading) ...const [
                            SizedBox(height: 6),
                            SkeletonLoader(
                              label: 'Loading balances',
                              child: SkeletonBox(
                                width: 170,
                                height: 30,
                                radius: 8,
                              ),
                            ),
                            Spacer(),
                            SkeletonLoader(
                              child: SkeletonBox(width: 150, height: 10),
                            ),
                            SizedBox(height: 8),
                          ] else ...[
                            Row(
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      amount,
                                      style: const TextStyle(
                                        fontFamily: 'Arimo',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 32,
                                        height: 1.15,
                                        color: Color(0xFF171918),
                                      ),
                                    ),
                                  ),
                                ),
                                if (index < 3)
                                  IconButton(
                                    tooltip: widget.state.balancesVisible
                                        ? 'Hide balances'
                                        : 'Show balances',
                                    onPressed: widget.onToggleVisibility,
                                    icon: const AppSvgIcon(
                                      'assets/icons/dashboard/c3aee.svg',
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            if (index == 0)
                              // A long account name is cut short so the link
                              // beside it stays on the same line.
                              Row(
                                spacing: 12,
                                children: [
                                  Flexible(
                                    child: Text(
                                      caption,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF555653),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Text(
                                      'View Account Details',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.action,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.action,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF555653),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 2,
          children: [
            for (var i = 0; i < cards.length; i++)
              Container(
                width: i == _index ? 30 : 12,
                height: 4,
                decoration: BoxDecoration(
                  color: i == _index ? Colors.black : const Color(0x1A000000),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
