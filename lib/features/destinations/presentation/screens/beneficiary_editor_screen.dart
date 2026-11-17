import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/features/destinations/data/repositories/destinations_repository.dart';
import 'package:paysplit/features/destinations/presentation/controllers/beneficiary_editor_controller.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/destinations/presentation/widgets/category_picker.dart';
import 'package:paysplit/features/destinations/presentation/widgets/destination_editor_actions.dart';
import 'package:paysplit/features/destinations/presentation/widgets/destination_success_sheet.dart';
import 'package:paysplit/features/setup/presentation/widgets/setup_layout.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/buttons/app_text_link.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/feedback/verification_notice.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';
import 'package:paysplit/widgets/inputs/app_select_field.dart';
import 'package:paysplit/widgets/overlays/choice_sheet.dart';
import 'package:paysplit/widgets/overlays/editor_sheet_layout.dart';

/// Opens the form to add a beneficiary, or to edit [initial].
Future<void> showBeneficiaryEditor(
  BuildContext context, {
  Beneficiary? initial,
}) async {
  final result = await showModalBottomSheet<({String id, bool createRule})>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
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
    showAppNotice(context, 'Beneficiary updated.');
  } else {
    await showDestinationSuccess(context, beneficiary: true);
  }
}

class BeneficiaryEditorScreen extends ConsumerStatefulWidget {
  const BeneficiaryEditorScreen({this.setup = false, this.initial, super.key});
  final bool setup;

  /// The saved beneficiary to edit; null adds a new one. Its account number
  /// and narration are not on the list record, so the form loads them.
  final Beneficiary? initial;
  @override
  ConsumerState<BeneficiaryEditorScreen> createState() =>
      _BeneficiaryEditorScreenState();
}

class _BeneficiaryEditorScreenState
    extends ConsumerState<BeneficiaryEditorScreen> {
  final _account = TextEditingController();
  final _narration = TextEditingController();
  final _bankName = TextEditingController();
  bool _loadingBanks = false;
  String? _bankError;

  /// False while the saved narration is still being loaded. Saving waits for
  /// it, so an edit never replaces the narration with an empty field.
  late bool _narrationReady = widget.initial == null;

  BeneficiaryEditorController get _controller =>
      ref.read(beneficiaryEditorControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;
    _account.text = initial.maskedAccountNumber;
    _bankName.text = initial.bank;
    ref.listenManual(beneficiaryDetailProvider(initial.id), (_, next) {
      // A detail that is being fetched again may hold the narration from
      // before the last edit, so only a settled answer fills the form.
      final detail = next.isLoading ? null : next.value;
      if (detail == null || _narrationReady) return;
      _account.text = detail.accountNumber;
      _narration.text = detail.narration ?? '';
      setState(() => _narrationReady = true);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _account.dispose();
    _narration.dispose();
    _bankName.dispose();
    super.dispose();
  }

  Future<void> _chooseBank() async {
    if (_loadingBanks) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _loadingBanks = true;
      _bankError = null;
    });
    List<Bank>? banks;
    try {
      banks = await ref.read(banksProvider.future);
    } on Object catch (error) {
      // A failed lookup is retried on the next tap. The reason stays under
      // the field, where it is still visible once the keyboard returns.
      ref.invalidate(banksProvider);
      if (mounted) {
        setState(
          () => _bankError = describeError(
            error,
            fallback: 'Banks could not be loaded. Tap to try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingBanks = false);
    }
    if (banks == null || !mounted) return;
    final bank = await showChoiceSheet(
      context,
      title: 'Bank Name',
      choices: banks,
      label: (value) => value.name,
      selected: ref.read(beneficiaryEditorControllerProvider).bank,
    );
    if (bank != null && mounted) {
      _controller.selectBank(bank, accountNumber: _account.text);
    }
  }

  Future<void> _save({bool createRule = false}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final beneficiary = await _controller.save(
      accountNumber: _account.text,
      narration: _narration.text,
    );
    if (!mounted || beneficiary == null) return;
    if (widget.setup) {
      context.push('/setup/rule?beneficiary=${beneficiary.id}');
    } else {
      Navigator.pop(context, (id: beneficiary.id, createRule: createRule));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(beneficiaryEditorControllerProvider);
    final editing = state.editing;
    ref.listen(
      beneficiaryEditorControllerProvider.select((s) => s.errors['form']),
      (previous, next) {
        if (next != null) showAppNotice(context, next);
      },
    );
    final arrow = widget.setup
        ? 'assets/icons/kyc/f26f0.svg'
        : 'assets/icons/destinations/cefc6.svg';
    final initial = widget.initial;
    final resolvedName = editing ? initial?.name : state.resolvedName;
    final detail = initial == null
        ? null
        : ref.watch(beneficiaryDetailProvider(initial.id));
    final detailFailed =
        !_narrationReady &&
        detail != null &&
        detail.hasError &&
        !detail.isLoading;
    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.errors['kyc'] case final message?) ...[
          VerificationNotice(message: message),
          const SizedBox(height: 16),
        ],
        if (editing)
          AppInputField(
            label: 'Bank Name',
            controller: _bankName,
            readOnly: true,
          )
        else
          AppSelectField(
            arrowAsset: arrow,
            label: 'Bank Name *',
            value: state.bank?.name,
            hint: _loadingBanks ? 'Loading banks…' : 'Select bank',
            error: state.errors['bank'] ?? _bankError,
            onPressed: _chooseBank,
          ),
        const SizedBox(height: 16),
        AppInputField(
          label: 'Account Number (10 Digits)',
          controller: _account,
          hint: '10-digit account number',
          readOnly: editing,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          error: state.errors['account'],
          onChanged: editing ? null : _controller.resolve,
        ),
        if (state.resolving)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              spacing: 8,
              children: [
                SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                Text('Checking account name…', style: TextStyle(fontSize: 14)),
              ],
            ),
          )
        else if (resolvedName != null && resolvedName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              label: 'Account name $resolvedName, verified',
              child: ExcludeSemantics(
                child: Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Text(
                        resolvedName,
                        style: AppTypography.label.copyWith(
                          color: AppColors.positive,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.positive,
                    ),
                  ],
                ),
              ),
            ),
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
              title: 'Beneficiary Category',
              selected: state.category,
            );
            if (category != null && mounted) {
              _controller.selectCategory(category);
            }
          },
        ),
        const SizedBox(height: 16),
        AppInputField(
          label: 'Payment Narration / Reference Note (optional)',
          controller: _narration,
          hint: _narrationReady ? 'e.g Payment for rent' : 'Loading…',
          enabled: _narrationReady,
          maxLines: widget.setup ? 3 : 1,
          textInputAction: TextInputAction.done,
          inputFormatters: [LengthLimitingTextInputFormatter(100)],
          error:
              state.errors['narration'] ??
              (detailFailed ? 'The saved note couldn’t be loaded.' : null),
          onChanged: (_) => _controller.clearError('narration'),
        ),
        if (detailFailed && initial != null)
          Align(
            alignment: Alignment.centerLeft,
            child: AppTextLink(
              label: 'Try again',
              onPressed: () =>
                  ref.invalidate(beneficiaryDetailProvider(initial.id)),
            ),
          ),
      ],
    );
    if (widget.setup) {
      return SetupLayout(
        step: 3,
        title: 'Create First Recipient/Beneficiary',
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/setup/wallet'),
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              label: 'Create Split Rule',
              busy: state.busy,
              onPressed: _narrationReady ? _save : null,
            ),
            // A beneficiary needs a verified identity and a reachable bank
            // lookup; the first rule can still be set up for the wallet.
            Center(
              child: AppTextLink(
                label: 'Skip for now',
                onPressed: state.busy
                    ? null
                    : () => context.push('/setup/rule'),
              ),
            ),
          ],
        ),
        child: fields,
      );
    }
    return EditorSheetLayout(
      title: editing ? 'Edit Beneficiary' : 'Add Beneficiary',
      onClose: () => Navigator.pop(context),
      bottom: DestinationEditorActions(
        busy: state.busy,
        onSave: _narrationReady ? _save : null,
        onSaveAndCreateRule: _narrationReady
            ? () => _save(createRule: true)
            : null,
      ),
      child: fields,
    );
  }
}
