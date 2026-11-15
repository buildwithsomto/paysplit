import 'package:flutter/material.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

class BalanceCarousel extends StatefulWidget {
  const BalanceCarousel({
    required this.state,
    required this.onToggleVisibility,
    required this.onAccount,
    this.nextSalaryLabel,
    this.accountCaption,
    super.key,
  });
  final DashboardState state;
  final VoidCallback onToggleVisibility;
  final VoidCallback onAccount;
  final String? nextSalaryLabel, accountCaption;
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

  String _amount(int value) =>
      widget.state.balancesVisible ? Money.format(value) : '••••••';

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final cards = [
      (
        'Salary Account Balance',
        _amount(widget.state.remainder),
        widget.accountCaption ??
            (widget.state.populated
                ? 'Sample · Paul Clarke'
                : 'Account not provisioned'),
      ),
      (
        'Total In Wallets',
        _amount(widget.state.walletAllocation),
        widget.state.populated
            ? 'Allocated to wallets · sample'
            : 'No wallet allocations yet',
      ),
      (
        'Split Allocation',
        _amount(widget.state.allocated),
        widget.state.populated
            ? '72% of sample salary'
            : 'No salary allocated yet',
      ),
      (
        'Next Expected Salary',
        widget.nextSalaryLabel ??
            (widget.state.populated ? 'Nov 25, 2026' : 'Not set'),
        'Execution waits for confirmed funds',
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
                            Wrap(
                              spacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  caption,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF555653),
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
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF555653),
                              ),
                            ),
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
