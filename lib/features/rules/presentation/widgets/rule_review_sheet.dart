import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/overlays/editor_sheet_layout.dart';

Future<SplitRule?> reviewRule(
  BuildContext context,
  RuleInput input, {
  String? id,
}) => showModalBottomSheet<SplitRule>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: const Color(0xFFFBFBFB),
  clipBehavior: Clip.antiAlias,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
  ),
  builder: (_) => _Review(input: input, id: id),
);

class _Review extends ConsumerStatefulWidget {
  const _Review({required this.input, this.id});
  final RuleInput input;
  final String? id;
  @override
  ConsumerState<_Review> createState() => _ReviewState();
}

class _ReviewState extends ConsumerState<_Review> {
  String? _error;
  void _save(RuleStatus status) {
    final rule = ref
        .read(rulesControllerProvider.notifier)
        .save(widget.input, id: widget.id, status: status);
    if (rule != null) {
      Navigator.pop(context, rule);
    } else {
      setState(
        () => _error =
            'This rule can no longer be saved. Return to the form and check its destination and verification status.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(destinationsControllerProvider);
    final verified =
        ref.watch(kycControllerProvider).status == KycStatus.approved;
    final input = widget.input;
    final wallet = data.wallets
        .where((w) => w.id == input.destinationId)
        .firstOrNull;
    final beneficiary = data.beneficiaries
        .where((b) => b.id == input.destinationId)
        .firstOrNull;
    final units = input.units!;
    final value = input.method == AllocationMethod.fixed
        ? Money.format(units)
        : '${units ~/ 100}${units % 100 == 0 ? '' : '.${(units % 100).toString().padLeft(2, '0')}'}%';
    return EditorSheetLayout(
      title: 'Review Split Rule',
      subtitle: 'Confirm your allocation before saving.',
      height: 720,
      onClose: () => Navigator.pop(context),
      bottom: Column(
        spacing: 12,
        children: [
          AppButton(
            label: 'Save Draft',
            outlined: true,
            onPressed: () => _save(RuleStatus.draft),
          ),
          AppButton(
            label: 'Confirm Preview Activation',
            onPressed: verified ? () => _save(RuleStatus.active) : null,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          RuleReviewRow(label: 'Rule Name', value: input.name),
          RuleReviewRow(
            label: 'Destination',
            value: wallet?.name ?? beneficiary?.name ?? 'Unavailable',
          ),
          RuleReviewRow(
            label: 'Category',
            value: wallet?.category ?? beneficiary?.category ?? 'Unavailable',
          ),
          RuleReviewRow(
            label: 'Allocation',
            value:
                '${input.method == AllocationMethod.fixed ? 'Fixed amount' : 'Percentage'} · $value',
          ),
          RuleReviewRow(
            label: 'Priority',
            value: '${input.priority} of 10 (1 is highest)',
          ),
          if (input.method == AllocationMethod.percentage)
            const Text(
              'Percentages use the original confirmed salary, before any other rules are applied.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          Text(
            verified
                ? 'Your rule will be activated on this device.'
                : 'Complete identity verification before activating a rule. You can save this configuration as a draft.',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

class RuleReviewRow extends StatelessWidget {
  const RuleReviewRow({required this.label, required this.value, super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 16,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF696969)),
        ),
      ),
      Expanded(
        flex: 2,
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF171918),
          ),
        ),
      ),
    ],
  );
}
