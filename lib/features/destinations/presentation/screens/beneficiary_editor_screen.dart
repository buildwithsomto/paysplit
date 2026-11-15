import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/destinations/presentation/controllers/beneficiary_editor_controller.dart';
import 'package:paysplit/features/destinations/presentation/widgets/destination_editor_actions.dart';
import 'package:paysplit/features/destinations/presentation/widgets/destination_success_sheet.dart';
import 'package:paysplit/features/setup/presentation/widgets/setup_layout.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';
import 'package:paysplit/widgets/inputs/app_select_field.dart';
import 'package:paysplit/widgets/overlays/choice_sheet.dart';
import 'package:paysplit/widgets/overlays/editor_sheet_layout.dart';

Future<void> showBeneficiaryEditor(
  BuildContext context, {
  BeneficiaryViewData? initial,
}) async {
  final result = await showModalBottomSheet<({String id, bool createRule})>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFBFBFB),
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => ProviderScope(
      overrides: [
        beneficiaryEditorControllerProvider.overrideWith(
          () => BeneficiaryEditorController(initial: initial),
        ),
      ],
      child: BeneficiaryEditorScreen(initial: initial),
    ),
  );
  if (result == null || !context.mounted) return;
  if (result.createRule) {
    context.push('/rules/new?beneficiary=${result.id}');
  } else if (initial != null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Changes saved locally.')));
  } else {
    await showDestinationSuccess(context, beneficiary: true);
  }
}

class BeneficiaryEditorScreen extends ConsumerStatefulWidget {
  const BeneficiaryEditorScreen({this.setup = false, this.initial, super.key});
  final bool setup;
  final BeneficiaryViewData? initial;
  @override
  ConsumerState<BeneficiaryEditorScreen> createState() =>
      _BeneficiaryEditorScreenState();
}

class _BeneficiaryEditorScreenState
    extends ConsumerState<BeneficiaryEditorScreen> {
  final _bank = TextEditingController();
  final _account = TextEditingController();
  final _name = TextEditingController();
  final _narration = TextEditingController();
  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _name.text = initial.name;
      _bank.text = initial.bank;
      _account.text = initial.accountNumber;
      _narration.text = initial.narration;
    }
  }

  @override
  void dispose() {
    _bank.dispose();
    _account.dispose();
    _name.dispose();
    _narration.dispose();
    super.dispose();
  }

  void _save({bool createRule = false}) {
    FocusManager.instance.primaryFocus?.unfocus();
    final beneficiary = ref
        .read(beneficiaryEditorControllerProvider.notifier)
        .save(
          name: _name.text,
          bank: _bank.text,
          accountNumber: _account.text,
          narration: _narration.text,
        );
    if (beneficiary == null) return;
    if (widget.setup) {
      context.push('/setup/rule?beneficiary=${beneficiary.id}');
    } else {
      Navigator.pop(context, (id: beneficiary.id, createRule: createRule));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(beneficiaryEditorControllerProvider);
    final controller = ref.read(beneficiaryEditorControllerProvider.notifier);
    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        AppInputField(
          label: 'Bank Name *',
          controller: _bank,
          hint: 'e.g Access Bank',
          error: state.errors['bank'],
          onChanged: (_) => controller.clearError('bank'),
        ),
        AppInputField(
          label: 'Account Number (10 Digits)',
          controller: _account,
          hint: '10-digit account number',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          error: state.errors['account'],
          onChanged: (_) => controller.clearError('account'),
        ),
        AppInputField(
          label: 'Beneficiary Name *',
          controller: _name,
          hint: 'Name on the account',
          error: state.errors['name'],
          onChanged: (_) => controller.clearError('name'),
        ),
        const Text(
          'Account-name verification is pending the bank API.',
          style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF667085)),
        ),
        AppSelectField(
          arrowAsset: widget.setup
              ? 'assets/icons/kyc/f26f0.svg'
              : 'assets/icons/destinations/cefc6.svg',
          label: 'Select Category *',
          value: state.category,
          hint: 'Select',
          error: state.errors['category'],
          onPressed: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            final category = await showChoiceSheet(
              context,
              title: 'Beneficiary category',
              choices: beneficiaryCategories,
              label: (v) => v,
              selected: state.category,
            );
            if (category != null && mounted) {
              controller.selectCategory(category);
            }
          },
        ),
        AppInputField(
          label: 'Payment Narration (optional)',
          controller: _narration,
          hint: 'e.g Payment for rent',
          maxLines: widget.setup ? 3 : 1,
          textInputAction: TextInputAction.done,
          error: state.errors['narration'],
          onChanged: (_) => controller.clearError('narration'),
        ),
      ],
    );
    if (widget.setup) {
      return SetupLayout(
        step: 3,
        title: 'Create First Recipient/Beneficiary',
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/setup/wallet'),
        bottom: AppButton(label: 'Create Split Rule', onPressed: _save),
        child: fields,
      );
    }
    return EditorSheetLayout(
      title: widget.initial == null ? 'Add Beneficiary' : 'Edit Beneficiary',
      onClose: () => Navigator.pop(context),
      bottom: DestinationEditorActions(
        onSave: _save,
        onSaveAndCreateRule: () => _save(createRule: true),
      ),
      child: fields,
    );
  }
}
