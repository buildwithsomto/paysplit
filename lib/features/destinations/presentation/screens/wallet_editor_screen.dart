import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/destinations/presentation/controllers/wallet_editor_controller.dart';
import 'package:paysplit/features/destinations/presentation/widgets/category_picker.dart';
import 'package:paysplit/features/destinations/presentation/widgets/destination_editor_actions.dart';
import 'package:paysplit/features/destinations/presentation/widgets/destination_success_sheet.dart';
import 'package:paysplit/features/setup/presentation/widgets/setup_layout.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/features/destinations/data/repositories/destinations_repository.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';
import 'package:paysplit/widgets/inputs/app_select_field.dart';
import 'package:paysplit/widgets/overlays/choice_sheet.dart';
import 'package:paysplit/widgets/overlays/editor_sheet_layout.dart';

Future<void> showWalletEditor(BuildContext context, {Wallet? initial}) async {
  final result = await showModalBottomSheet<({String id, bool createRule})>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => ProviderScope(
      overrides: [
        walletEditorControllerProvider.overrideWith(
          () => WalletEditorController(initial: initial),
        ),
      ],
      child: WalletEditorScreen(initial: initial),
    ),
  );
  if (result == null || !context.mounted) return;
  if (result.createRule) {
    context.push('/rules/new?wallet=${result.id}');
  } else if (initial != null) {
    showAppNotice(context, 'Wallet updated.');
  } else {
    await showDestinationSuccess(context, beneficiary: false);
  }
}

class WalletEditorScreen extends ConsumerStatefulWidget {
  const WalletEditorScreen({this.setup = false, this.initial, super.key});
  final bool setup;
  final Wallet? initial;
  @override
  ConsumerState<WalletEditorScreen> createState() => _WalletEditorScreenState();
}

class _WalletEditorScreenState extends ConsumerState<WalletEditorScreen> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _name.text = initial.name;
      if (initial.targetMinor case final target?) {
        _target.text =
            '${target ~/ 100}.${(target % 100).toString().padLeft(2, '0')}';
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save({bool createRule = false}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final wallet = await ref
        .read(walletEditorControllerProvider.notifier)
        .save(name: _name.text, target: _target.text);
    if (!mounted || wallet == null) return;
    if (widget.setup) {
      context.push('/setup/beneficiary');
    } else {
      Navigator.pop(context, (id: wallet.id, createRule: createRule));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletEditorControllerProvider);
    final controller = ref.read(walletEditorControllerProvider.notifier);
    final accentList = ref.watch(walletAccentsProvider);
    final accents = accentList.value ?? const <WalletAccent>[];
    final accent = state.accent ?? accents.firstOrNull;
    final arrow = widget.setup
        ? 'assets/icons/kyc/f26f0.svg'
        : 'assets/icons/destinations/cefc6.svg';
    ref.listen(walletEditorControllerProvider.select((s) => s.errors['form']), (
      previous,
      next,
    ) {
      if (next != null) showAppNotice(context, next);
    });
    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInputField(
          label: 'Wallet Name *',
          controller: _name,
          hint: 'e.g Children school fees',
          error: state.errors['name'],
          onChanged: (_) => controller.clearError('name'),
        ),
        const SizedBox(height: 16),
        AppSelectField(
          arrowAsset: arrow,
          label: 'Select Category *',
          value: state.category?.name,
          hint: 'Select',
          error: state.errors['category'],
          onPressed: () async {
            final category = await pickCategory(
              context,
              ref,
              title: 'Wallet Category',
              selected: state.category,
            );
            if (category != null && mounted) {
              controller.selectCategory(category);
            }
          },
        ),
        const SizedBox(height: 16),
        AppInputField(
          label: 'Budget Target Amount (₦)',
          controller: _target,
          hint: 'e.g 1,500,000',
          enabled: !state.noTarget,
          error: state.errors['target'],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onChanged: (_) => controller.clearError('target'),
        ),
        Semantics(
          checked: state.noTarget,
          label: 'No Targeted Amount',
          child: InkWell(
            onTap: () => controller.setNoTarget(!state.noTarget),
            child: ExcludeSemantics(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  spacing: 8,
                  children: [
                    SizedBox(
                      width: 16,
                      child: IgnorePointer(
                        child: Checkbox(
                          value: state.noTarget,
                          onChanged: (_) {},
                          side: const BorderSide(color: Color(0xFFD0D5DD)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'No Targeted Amount',
                        style: AppTypography.label,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text('Accent Color', style: AppTypography.label),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: accents.isEmpty
                ? () => ref.invalidate(walletAccentsProvider)
                : () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    final picked = await showChoiceSheet(
                      context,
                      title: 'Accent Color',
                      choices: accents,
                      label: (v) => v.label,
                      selected: accent,
                    );
                    if (picked != null && mounted) {
                      controller.selectAccent(picked);
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEDEDED)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                spacing: 8,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent?.color ?? const Color(0xFFE4E4E4),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      accent?.label ??
                          (accentList.hasError
                              ? 'Colours couldn’t be loaded. Tap to retry'
                              : 'Loading colours…'),
                      style: AppTypography.input.copyWith(color: Colors.black),
                    ),
                  ),
                  AppSvgIcon(arrow),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    if (widget.setup) {
      return SetupLayout(
        step: 2,
        title: 'Create First Wallet',
        onBack: () => context.canPop() ? context.pop() : context.go('/setup'),
        bottom: AppButton(label: 'Next', busy: state.busy, onPressed: _save),
        child: fields,
      );
    }
    return EditorSheetLayout(
      title: widget.initial == null ? 'Create New Wallet' : 'Edit Wallet',
      onClose: () => Navigator.pop(context),
      bottom: DestinationEditorActions(
        busy: state.busy,
        onSave: _save,
        onSaveAndCreateRule: () => _save(createRule: true),
      ),
      child: fields,
    );
  }
}
