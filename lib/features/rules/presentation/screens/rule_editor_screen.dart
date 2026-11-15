import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/rule_editor_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/features/rules/presentation/widgets/rule_destination_sheet.dart';
import 'package:paysplit/features/rules/presentation/widgets/rule_review_sheet.dart';
import 'package:paysplit/features/setup/presentation/widgets/setup_layout.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';
import 'package:paysplit/widgets/inputs/app_select_field.dart';
import 'package:paysplit/widgets/overlays/choice_sheet.dart';
import 'package:paysplit/widgets/overlays/editor_sheet_layout.dart';

class RuleEditorRoute extends ConsumerWidget {
  const RuleEditorRoute({
    this.id,
    this.destinationId,
    this.type = RuleDestinationType.wallet,
    this.setup = false,
    super.key,
  });
  final String? id;
  final String? destinationId;
  final RuleDestinationType type;
  final bool setup;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.read(rulesControllerProvider);
    final existing = rules
        .where(
          (r) => id != null ? r.id == id : r.destinationId == destinationId,
        )
        .firstOrNull;
    return ProviderScope(
      overrides: [
        ruleEditorControllerProvider.overrideWith(
          () => RuleEditorController(
            initial: existing,
            destinationId: destinationId,
            type: type,
          ),
        ),
      ],
      child: RuleEditorScreen(initial: existing, setup: setup),
    );
  }
}

class RuleEditorScreen extends ConsumerStatefulWidget {
  const RuleEditorScreen({this.initial, this.setup = false, super.key});
  final SplitRule? initial;
  final bool setup;
  @override
  ConsumerState<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends ConsumerState<RuleEditorScreen> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _value = TextEditingController(text: widget.initial?.input.value);
  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _review() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final input = ref
        .read(ruleEditorControllerProvider.notifier)
        .review(name: _name.text, value: _value.text);
    if (input == null) return;
    final saved = await reviewRule(context, input, id: widget.initial?.id);
    if (saved == null || !mounted) return;
    final router = GoRouter.of(context);
    if (widget.setup) {
      router.go('/home');
      router.push('/setup/progress');
    } else {
      final route = ModalRoute.of(context);
      final navigator = Navigator.of(context, rootNavigator: true);
      router.pop();
      // Wait for the departing editor to release its navigator scope.
      await route?.completed;
      if (navigator.mounted) router.push('/rules/saved?id=${saved.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ruleEditorControllerProvider);
    final controller = ref.read(ruleEditorControllerProvider.notifier);
    final destinations = ref.watch(destinationsControllerProvider);
    final isWallet = state.type == RuleDestinationType.wallet;
    final destinationName = isWallet
        ? destinations.wallets
              .where((w) => w.id == state.destinationId)
              .firstOrNull
              ?.name
        : destinations.beneficiaries
              .where((b) => b.id == state.destinationId)
              .firstOrNull
              ?.name;
    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        AppInputField(
          label: 'Rule Name *',
          controller: _name,
          hint: 'e.g Emergency Buffer',
          error: state.errors['name'],
          onChanged: (_) => controller.clearError('name'),
        ),
        AppSelectField(
          label: 'Priority',
          value: '${state.priority}',
          error: state.errors['priority'],
          onPressed: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            final priority = await showChoiceSheet(
              context,
              title: 'Priority (1 is highest)',
              choices: List.generate(10, (i) => i + 1),
              label: (v) => '$v',
              selected: state.priority,
            );
            if (priority != null && mounted) controller.setPriority(priority);
          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            const Text('Destination Type *', style: AppTypography.label),
            _DestinationTypeTile(
              wallet: true,
              selected: isWallet,
              onPressed: () => controller.setType(RuleDestinationType.wallet),
            ),
            const SizedBox(height: 0),
            _DestinationTypeTile(
              wallet: false,
              selected: !isWallet,
              onPressed: () =>
                  controller.setType(RuleDestinationType.beneficiary),
            ),
          ],
        ),
        AppSelectField(
          label: isWallet ? 'Select Wallet *' : 'Select Beneficiary *',
          value: destinationName,
          error: state.errors['destination'],
          onPressed: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            final id = await showRuleDestinationSheet(
              context,
              state.type,
              ruleId: widget.initial?.id,
            );
            if (id != null && mounted) controller.setDestination(id);
          },
        ),
        AppInputField(
          label: 'Allocation Method & Value',
          controller: _value,
          hint: state.method == AllocationMethod.fixed
              ? 'amount in naira'
              : 'percentage',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          error: state.errors['value'],
          onChanged: (_) => controller.clearError('value'),
          prefix: Semantics(
            button: true,
            label: 'Allocation method',
            child: InkWell(
              onTap: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                final method = await showChoiceSheet(
                  context,
                  title: 'Allocation method',
                  choices: AllocationMethod.values,
                  label: (v) => v == AllocationMethod.fixed
                      ? 'Fixed amount'
                      : 'Percentage of original salary',
                  selected: state.method,
                );
                if (method != null && mounted && method != state.method) {
                  controller.setMethod(method);
                  _value.clear();
                }
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 50),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                margin: const EdgeInsets.only(right: 10),
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Color(0xFFD0D5DD))),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    Text(
                      state.method == AllocationMethod.fixed ? 'Fixed' : '%',
                      style: AppTypography.input.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                    const AppSvgIcon('assets/icons/rules/f027b.svg', size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    if (widget.setup) {
      return SetupLayout(
        step: 4,
        title: 'Create Split Rule',
        onBack: () => context.canPop() ? context.pop() : context.go('/setup'),
        bottom: AppButton(label: 'Review & Complete Setup', onPressed: _review),
        child: fields,
      );
    }
    return EditorSheetLayout(
      title: widget.initial == null ? 'Create Split Rule' : 'Edit Split Rule',
      subtitle: 'Configure automatic distribution of incoming funds',
      height: 814,
      bottomPadding:
          MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).top <
              814
          ? 24
          : 36,
      onClose: () => context.pop(),
      bottom: AppButton(label: 'Review Split Rule', onPressed: _review),
      child: fields,
    );
  }
}

class _DestinationTypeTile extends StatelessWidget {
  const _DestinationTypeTile({
    required this.wallet,
    required this.selected,
    required this.onPressed,
  });
  final bool wallet;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    inMutuallyExclusiveGroup: true,
    button: true,
    child: Material(
      color: selected ? const Color(0x80FFFFFF) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.black : const Color(0xFFE8E8E8),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: AppSvgIcon(
                  'assets/icons/rules/${wallet ? (selected ? 'd7477' : '2aabd') : (selected ? 'bc455' : 'a12a2')}.svg',
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet ? 'Move to Wallet' : 'Send to Beneficiary',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      wallet
                          ? 'Internal budget, savings account.'
                          : 'External bank payout',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const AppSvgIcon('assets/icons/rules/e6f13.svg')
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5E7EA),
                      width: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
