import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/features/home/presentation/widgets/dashboard_card.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';
import 'package:paysplit/widgets/overlays/choice_sheet.dart';

/// One bar of the chart: a month, or a run of days for short ranges.
/// [label] is the month; [detail] is its year, or the day a run starts on.
typedef _Bar = ({String label, String detail, int wallets, int beneficiaries});

/// "Salary Allocation & Split Cash Flow": money sent to wallets (up) and to
/// beneficiaries (down) per period, from `/dashboard/cash-flow`.
class CashFlowCard extends StatefulWidget {
  const CashFlowCard({
    required this.state,
    required this.onSelectRange,
    required this.onRetry,
    super.key,
  });
  final DashboardState state;

  /// Completes with false when the chosen period could not be loaded.
  final Future<bool> Function(CashFlowRange) onSelectRange;
  final VoidCallback onRetry;
  @override
  State<CashFlowCard> createState() => _CashFlowCardState();
}

class _CashFlowCardState extends State<CashFlowCard> {
  static const _maxBars = 6;
  static const _gridTop = 20.0;
  static const _gridStep = 42.0;
  static const _baseline = _gridTop + 3 * _gridStep;

  /// Null selects the most recent bar.
  int? _selected;

  @override
  void didUpdateWidget(CashFlowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.cashFlow != widget.state.cashFlow) _selected = null;
  }

  /// One bar per month; daily ranges are summed into at most [_maxBars]
  /// runs of days.
  List<_Bar> _bars(CashFlow flow) {
    final buckets = flow.buckets;
    if (buckets.isEmpty) return const [];
    if (!flow.daily) {
      return [
        for (final bucket in buckets)
          (
            label: DateFormat.MMM().format(bucket.start),
            detail: DateFormat('yy').format(bucket.start),
            wallets: bucket.toWallets,
            beneficiaries: bucket.toBeneficiaries,
          ),
      ];
    }
    final size = (buckets.length / _maxBars).ceil();
    return [
      for (var i = 0; i < buckets.length; i += size)
        () {
          final group = buckets.skip(i).take(size);
          final start = group.first.start;
          return (
            label: DateFormat.MMM().format(start),
            detail: DateFormat.d().format(start),
            wallets: group.fold(0, (sum, b) => sum + b.toWallets),
            beneficiaries: group.fold(0, (sum, b) => sum + b.toBeneficiaries),
          );
        }(),
    ];
  }

  Future<void> _pickRange() async {
    final range = await showChoiceSheet(
      context,
      title: 'Cash Flow Period',
      choices: CashFlowRange.values,
      selected: widget.state.cashFlowRange,
      label: (value) => value.label,
    );
    if (range == null) return;
    final loaded = await widget.onSelectRange(range);
    if (!loaded && mounted) {
      showAppNotice(context, 'That period couldn’t be loaded. Try again.');
    }
  }

  /// A round value per grid line so three lines cover the tallest bar.
  static int _step(List<_Bar> bars) {
    var peak = 0;
    for (final bar in bars) {
      if (bar.wallets > peak) peak = bar.wallets;
      if (bar.beneficiaries > peak) peak = bar.beneficiaries;
    }
    if (peak <= 0) return 100000;
    final raw = peak / 3;
    var magnitude = 1;
    while (magnitude * 10 <= raw) {
      magnitude *= 10;
    }
    for (final factor in const [1, 2, 5, 10]) {
      if (factor * magnitude >= raw) return factor * magnitude;
    }
    return 10 * magnitude;
  }

  static String _axis(int minor) {
    final naira = minor.abs() / 100;
    final text = naira >= 1000000
        ? '${compactNumber(naira / 1000000)}m'
        : naira >= 1000
        ? '${compactNumber(naira / 1000)}k'
        : compactNumber(naira);
    return minor < 0 ? '−₦$text' : '₦$text';
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final flow = state.cashFlow;
    final bars = flow == null ? const <_Bar>[] : _bars(flow);
    final selected = bars.isEmpty
        ? 0
        : (_selected ?? bars.length - 1).clamp(0, bars.length - 1);
    final step = _step(bars);
    double barHeight(int minor) =>
        (minor / step * _gridStep).clamp(0, 3 * _gridStep);
    // The API compares this month with the last, so the figure belongs to
    // the latest monthly bar only.
    final change = flow != null && !flow.daily && selected == bars.length - 1
        ? flow.changePercent
        : null;
    return DashboardCard(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Salary Allocation & Split Cash Flow',
            style: TextStyle(fontSize: 14, color: Color(0xFF171918)),
          ),
          if (flow == null && (state.cashFlowFailed || state.phase.isFailure))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56),
              child: Center(
                child: Column(
                  spacing: 4,
                  children: [
                    const Text('Cash flow couldn’t be loaded.'),
                    TextButton(
                      onPressed: widget.onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (flow == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SkeletonLoader(
                label: 'Loading cash flow',
                child: SkeletonBox.card(height: 180, radius: 12),
              ),
            )
          else if (!state.balancesVisible)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 90),
              child: Center(child: Text('Balances and cash flow are hidden.')),
            )
          else ...[
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                Text(
                  Money.format(
                    bars.isEmpty
                        ? 0
                        : bars[selected].wallets + bars[selected].beneficiaries,
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF171918),
                  ),
                ),
                if (change != null) ...[
                  Text(
                    '${change >= 0 ? '+' : '−'}${compactNumber(change.abs())}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: change >= 0 ? AppColors.positive : AppColors.error,
                    ),
                  ),
                  const Text('from last month', style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _Legend('Wallets', AppColors.primary),
                _Legend('Recipient/Beneficiaries', Color(0xFF171918)),
              ],
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: 'Cash flow period',
              child: Material(
                color: const Color(0xFFFAF9F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFE4E4E4)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: state.cashFlowBusy ? null : _pickRange,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        Text(
                          state.cashFlowRange.label,
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (state.cashFlowBusy)
                          const SizedBox.square(
                            dimension: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (flow.isEmpty) ...[
              const SizedBox(height: 56),
              Center(
                child: SvgPicture.asset(
                  'assets/icons/dashboard/b98c5.svg',
                  width: 120,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('Your allocations will appear here.')),
              const SizedBox(height: 32),
            ] else ...[
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  SizedBox(
                    width: 36,
                    height: 298,
                    child: Stack(
                      children: [
                        for (var i = 0; i < 7; i++)
                          Positioned(
                            top: _gridTop - 7 + i * _gridStep,
                            left: 0,
                            right: 0,
                            // A long label such as "−₦500k" shrinks to
                            // the column instead of wrapping.
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _axis((3 - i) * step),
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF555653),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 298,
                          child: LayoutBuilder(
                            builder: (context, constraints) => Stack(
                              children: [
                                for (var i = 0; i < 7; i++)
                                  Positioned(
                                    top: _gridTop + i * _gridStep,
                                    left: 0,
                                    right: 0,
                                    height: 1,
                                    child: i == 3
                                        ? Image.asset(
                                            'assets/icons/dashboard/3c337.png',
                                            fit: BoxFit.fill,
                                            excludeFromSemantics: true,
                                          )
                                        : SvgPicture.asset(
                                            'assets/icons/dashboard/e79b3.svg',
                                            fit: BoxFit.fill,
                                            excludeFromSemantics: true,
                                          ),
                                  ),
                                for (final (i, bar) in bars.indexed)
                                  Positioned(
                                    left:
                                        i * constraints.maxWidth / bars.length,
                                    top: 0,
                                    bottom: 0,
                                    width: constraints.maxWidth / bars.length,
                                    child: Semantics(
                                      button: true,
                                      selected: i == selected,
                                      label:
                                          '${bar.label} ${bar.detail}. Wallets ${Money.format(bar.wallets)}. Beneficiaries ${Money.format(bar.beneficiaries)}.',
                                      child: InkWell(
                                        onTap: () =>
                                            setState(() => _selected = i),
                                        child: Stack(
                                          alignment: Alignment.topCenter,
                                          children: [
                                            if (i > 0)
                                              Positioned(
                                                left: 0,
                                                top: 0,
                                                bottom: 0,
                                                width: 1,
                                                child: RotatedBox(
                                                  quarterTurns: 1,
                                                  child: Image.asset(
                                                    'assets/icons/dashboard/4a96f.png',
                                                    fit: BoxFit.fill,
                                                    excludeFromSemantics: true,
                                                  ),
                                                ),
                                              ),
                                            if (bar.wallets > 0)
                                              Positioned(
                                                top:
                                                    _baseline -
                                                    barHeight(bar.wallets),
                                                width: 26,
                                                height: barHeight(bar.wallets),
                                                child: _BarFill(
                                                  up: true,
                                                  selected: i == selected,
                                                ),
                                              ),
                                            if (bar.beneficiaries > 0)
                                              Positioned(
                                                top: _baseline,
                                                width: 26,
                                                height: barHeight(
                                                  bar.beneficiaries,
                                                ),
                                                child: _BarFill(
                                                  up: false,
                                                  selected: i == selected,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            for (final bar in bars)
                              Expanded(
                                child: Text(
                                  '${bar.label}\n${bar.detail}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.2,
                                    color: Color(0xFF555653),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// A wallet bar grows up in blue; a beneficiary bar grows down in ink.
class _BarFill extends StatelessWidget {
  const _BarFill({required this.up, required this.selected});
  final bool up, selected;
  @override
  Widget build(BuildContext context) {
    final color = up ? AppColors.primary : const Color(0xFF171918);
    final edge = BorderSide(color: color, width: 2);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? color : null,
        gradient: selected
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: up
                    ? const [Color(0xFFEAF6FF), Color(0x00FFFFFF)]
                    : const [Color(0x00FFFFFF), Color(0xFFF4F4F3)],
              ),
        border: up ? Border(top: edge) : Border(bottom: edge),
        borderRadius: up
            ? const BorderRadius.vertical(top: Radius.circular(18))
            : const BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 4,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      Flexible(
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF171918)),
        ),
      ),
    ],
  );
}
