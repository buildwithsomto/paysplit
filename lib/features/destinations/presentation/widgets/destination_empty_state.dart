import 'package:flutter/material.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

class DestinationEmptyState extends StatelessWidget {
  const DestinationEmptyState({required this.beneficiary, super.key});
  final bool beneficiary;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
    child: Column(
      children: [
        if (beneficiary)
          const AppSvgIcon(
            'assets/icons/destinations/b98c5.svg',
            width: 103,
            height: 66,
          )
        else
          const ColorFiltered(
            colorFilter: ColorFilter.mode(Color(0xFF33A7F5), BlendMode.srcIn),
            child: AppSvgIcon('assets/icons/destinations/f93f3.svg', size: 48),
          ),
        const SizedBox(height: 20),
        Text(
          beneficiary ? 'No Saved Beneficiary Yet' : 'No Wallets Yet',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F324A),
          ),
        ),
      ],
    ),
  );
}
