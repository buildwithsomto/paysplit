import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/overlays/editor_sheet_layout.dart';

Future<String?> showRuleDestinationSheet(
  BuildContext context,
  RuleDestinationType type, {
  String? ruleId,
}) => showModalBottomSheet<String>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: const Color(0xFFFBFBFB),
  clipBehavior: Clip.antiAlias,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
  ),
  builder: (_) => _DestinationChoices(type: type, ruleId: ruleId),
);

class _DestinationChoices extends ConsumerWidget {
  const _DestinationChoices({required this.type, this.ruleId});
  final RuleDestinationType type;
  final String? ruleId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(destinationsControllerProvider);
    final rules = ref.watch(rulesControllerProvider);
    final wallet = type == RuleDestinationType.wallet;
    final choices = wallet
        ? data.wallets
              .map(
                (w) => (
                  id: w.id,
                  name: w.name,
                  caption: w.category,
                  color: w.accent.color,
                ),
              )
              .toList()
        : data.beneficiaries
              .map(
                (b) => (
                  id: b.id,
                  name: b.name,
                  caption: b.bank,
                  color: Colors.transparent,
                ),
              )
              .toList();
    return EditorSheetLayout(
      title: wallet ? 'Choose Wallet' : 'Choose Beneficiary',
      subtitle:
          'Select the ${wallet ? 'wallet' : 'beneficiary'} you want to add to the split rule',
      height: wallet ? 388 : 500,
      onClose: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          if (choices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No saved ${wallet ? 'wallets' : 'beneficiaries'} yet. Create a destination first.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final choice in choices)
            Builder(
              builder: (context) {
                final occupied = rules.any(
                  (r) => r.destinationId == choice.id && r.id != ruleId,
                );
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: occupied
                        ? null
                        : () => Navigator.pop(context, choice.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 16,
                      ),
                      child: Row(
                        spacing: 8,
                        children: [
                          if (wallet)
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: choice.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  choice.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF171918),
                                  ),
                                ),
                                if (!wallet || occupied) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    occupied
                                        ? 'Already linked to a rule'
                                        : choice.caption,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF696969),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!occupied)
                            const AppSvgIcon(
                              'assets/icons/rules/c1ae0.svg',
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
