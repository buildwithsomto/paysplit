import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

class WalletSummaryCard extends StatelessWidget {
  const WalletSummaryCard({
    required this.wallet,
    required this.onOpen,
    super.key,
  });
  final WalletViewData wallet;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onOpen,
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              switch (wallet.accent) {
                WalletAccent.green => const Color(0xFFEAFFED),
                WalletAccent.blue => const Color(0xFFEAF6FF),
                WalletAccent.orange => const Color(0xFFFFEDE8),
                WalletAccent.purple => const Color(0xFFF0E5FF),
              },
              Colors.white,
            ],
            stops: const [.13942, 1],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: wallet.accent.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppSvgIcon(
                    wallet.category == 'Travel'
                        ? 'assets/icons/destinations/f1fad.svg'
                        : 'assets/icons/destinations/f93f3.svg',
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        wallet.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF696969),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (MediaQuery.textScalerOf(context).scale(16) <= 20)
                  Flexible(
                    fit: FlexFit.tight,
                    child: Text(
                      Money.format(wallet.balanceMinor),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.2,
                        color: Color(0xFF171918),
                      ),
                    ),
                  ),
              ],
            ),
            if (MediaQuery.textScalerOf(context).scale(16) > 20) ...[
              const SizedBox(height: 8),
              Text(
                Money.format(wallet.balanceMinor),
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.2,
                  color: Color(0xFF171918),
                ),
              ),
            ],
            const SizedBox(height: 20),
            WalletTargetProgress(wallet: wallet),
            const SizedBox(height: 12),
            const AppSvgIcon(
              'assets/icons/destinations/72642.svg',
              width: double.infinity,
              height: 1,
            ),
            const SizedBox(height: 8),
            Row(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    DateFormat('MMM d, y').format(wallet.createdAt),
                    style: const TextStyle(
                      fontFamily: 'Switzer',
                      fontSize: 14,
                      height: 1.2,
                      color: Color(0xFF7D7D7D),
                    ),
                  ),
                ),
                const Flexible(
                  child: Text(
                    'View wallet',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
                const AppSvgIcon(
                  'assets/icons/destinations/f00e6.svg',
                  width: 16,
                  height: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class WalletTargetProgress extends StatelessWidget {
  const WalletTargetProgress({required this.wallet, super.key});
  final WalletViewData wallet;
  @override
  Widget build(BuildContext context) {
    final target = wallet.targetMinor;
    if (target == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No target amount',
          style: TextStyle(fontSize: 12, color: Color(0xFF696969)),
        ),
      );
    }
    final ratio = (wallet.balanceMinor / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: Text(
                'Target: ${Money.format(target)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF696969),
                ),
              ),
            ),
            Text(
              '${(ratio * 100).round()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Semantics(
          label: 'Wallet target progress',
          value: '${(ratio * 100).round()} percent',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              height: 17.364,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xABECECEC)),
                  ),
                  FractionallySizedBox(
                    widthFactor: ratio,
                    heightFactor: 1,
                    child: const AppSvgIcon(
                      'assets/icons/destinations/fb51f.svg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
