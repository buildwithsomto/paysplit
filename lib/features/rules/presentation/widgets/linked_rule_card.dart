import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

class LinkedRuleCard extends ConsumerWidget {
  const LinkedRuleCard({
    required this.destinationId,
    required this.beneficiary,
    super.key,
  });
  final String destinationId;
  final bool beneficiary;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule = ref
        .watch(rulesControllerProvider)
        .where((r) => r.destinationId == destinationId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Linked Rule',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF171918),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE4E4E4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              if (rule == null)
                const Text(
                  'No linked rule',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                )
              else
                InkWell(
                  onTap: () => context.push('/rules/${rule.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 12,
                        children: [
                          const Text(
                            'Allocation Method/Value',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4F4E55),
                            ),
                          ),
                          Text(
                            'Last Modified: ${DateFormat('MMM, d y').format(rule.updatedAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF727A90),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        rule.allocationLabel,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF121212),
                        ),
                      ),
                      // The design shows only the allocation; a paused rule
                      // says so because it will not run.
                      if (rule.status == RuleStatus.paused)
                        const Text(
                          'Paused',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF555653),
                          ),
                        ),
                    ],
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => context.push(
                  rule == null
                      ? '/rules/new?${beneficiary ? 'beneficiary' : 'wallet'}=$destinationId'
                      : '/rules/new?id=${rule.id}',
                ),
                icon: const AppSvgIcon(
                  'assets/icons/destinations/d7710.svg',
                  size: 16,
                ),
                label: Text(rule == null ? 'Create Rule' : 'Reconfigure Rule'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFEBF6FE),
                  side: const BorderSide(color: Color(0xFFC2E5FC)),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
