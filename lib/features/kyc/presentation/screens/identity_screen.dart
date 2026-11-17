import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/kyc/data/models/kyc_models.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/kyc/presentation/widgets/kyc_section.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/buttons/app_text_link.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/feedback/dashed_outline.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';
import 'package:paysplit/widgets/inputs/app_select_field.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';
import 'package:paysplit/widgets/overlays/choice_sheet.dart';

class IdentityScreen extends ConsumerStatefulWidget {
  const IdentityScreen({super.key});
  @override
  ConsumerState<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends ConsumerState<IdentityScreen> {
  final _number = TextEditingController();
  bool _picking = false;
  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _selectRegion() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final region = await showChoiceSheet(
      context,
      title: 'Identity Verification Method',
      choices: IdentityRegion.values,
      selected: ref.read(kycControllerProvider).region,
      label: (value) => value == IdentityRegion.nigeria
          ? 'Nigerian Identity'
          : 'International Identity',
    );
    if (!mounted || region == null) return;
    _number.clear();
    ref.read(kycControllerProvider.notifier).selectRegion(region);
  }

  Future<void> _selectDocument() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final state = ref.read(kycControllerProvider);
    final document = await showChoiceSheet(
      context,
      title: 'Identity Document',
      choices: state.documents,
      selected: state.document,
      label: (value) => value.label,
    );
    if (!mounted || document == null) return;
    _number.clear();
    ref.read(kycControllerProvider.notifier).selectDocument(document);
  }

  Future<void> _pickFile({bool back = false}) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Identity document',
            extensions: ['jpg', 'jpeg', 'png'],
            uniformTypeIdentifiers: ['public.jpeg', 'public.png'],
            mimeTypes: ['image/jpeg', 'image/png'],
          ),
        ],
      );
      if (file == null || !mounted) return;
      // Held in memory for the upload only; never written to app storage.
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      ref
          .read(kycControllerProvider.notifier)
          .selectFile(file.name, bytes, back: back);
    } on Object {
      if (mounted) {
        showAppNotice(context, 'Unable to open this file. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _continue() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final state = ref.read(kycControllerProvider);
    // Already accepted by the server: move on without spending an attempt.
    if ((state.verification?.identity.passed ?? false) &&
        _number.text.isEmpty &&
        state.documentName == null) {
      context.push('/kyc/liveness');
      return;
    }
    final passed = await ref
        .read(kycControllerProvider.notifier)
        .submitIdentity(_number.text);
    if (!mounted || !passed) return;
    _number.clear();
    context.push('/kyc/liveness');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycControllerProvider);
    final nigeria = state.region == IdentityRegion.nigeria;
    final identity = state.verification;
    final verified = identity != null && identity.identity.passed
        ? [
            identity.identityMethod?.label ?? 'identity document',
            ?identity.maskedIdNumber,
          ].join(' ')
        : null;
    ref.listen(kycControllerProvider.select((s) => s.errors['form']), (
      previous,
      next,
    ) {
      if (next != null) showAppNotice(context, next);
    });
    return AppPageLayout(
      title: 'Profile Verification',
      onBack: () => context.go('/kyc'),
      bottom: AppButton(
        label: state.busy ? 'Verifying' : 'Continue',
        busy: state.busy,
        onPressed: _continue,
      ),
      child: KycSection(
        step: 2,
        title: 'Select Verification Region',
        description: verified == null
            ? 'Provide government identification credentials corresponding to your country.'
            : 'Your $verified is verified. Continue to the face check, or submit a different ID.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSelectField(
              label: 'Identity Verification Method',
              value: nigeria ? 'Nigerian Identity' : 'International Identity',
              onPressed: _selectRegion,
            ),
            const SizedBox(height: 32),
            AppSelectField(
              value: state.document.label,
              onPressed: _selectDocument,
            ),
            SizedBox(height: nigeria ? 12 : 16),
            if (nigeria) ...[
              AppInputField(
                label: state.document.label,
                controller: _number,
                hint: 'e.g., 22234918239',
                error: state.errors['identity'],
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _continue(),
                onChanged: (_) => ref
                    .read(kycControllerProvider.notifier)
                    .clearError('identity'),
              ),
              if (state.document == IdentityDocument.bvn)
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppTextLink(
                    prefix: 'Don’t know your BVN? ',
                    label: 'Dial *565*0#',
                    onPressed: () => showAppNotice(
                      context,
                      'Use *565*0# from the phone number registered with your bank.',
                    ),
                  ),
                ),
            ] else ...[
              const Text('File Upload', style: AppTypography.label),
              const SizedBox(height: 12),
              _DocumentUpload(
                name: state.documentName,
                picking: _picking || state.busy,
                error: state.errors['file'],
                onPick: _pickFile,
                onRemove: () =>
                    ref.read(kycControllerProvider.notifier).removeFile(),
              ),
              if (state.document == IdentityDocument.driversLicense &&
                  state.documentName != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Back of licence (optional)',
                  style: AppTypography.label,
                ),
                const SizedBox(height: 12),
                _DocumentUpload(
                  name: state.backDocumentName,
                  picking: _picking || state.busy,
                  error: state.errors['backFile'],
                  onPick: () => _pickFile(back: true),
                  onRemove: () => ref
                      .read(kycControllerProvider.notifier)
                      .removeFile(back: true),
                ),
              ],
              const SizedBox(height: 8),
              const Text('JPG or PNG, up to 2 MB.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _DocumentUpload extends StatelessWidget {
  const _DocumentUpload({
    required this.name,
    required this.error,
    required this.picking,
    required this.onPick,
    required this.onRemove,
  });
  final String? name;
  final String? error;
  final bool picking;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DashedOutline(
        color: error == null ? AppColors.primaryBorder : AppColors.error,
        child: Container(
          constraints: const BoxConstraints(minHeight: 115),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: switch (name) {
            null => Center(
              child: TextButton.icon(
                onPressed: picking ? null : onPick,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.action,
                  side: const BorderSide(color: Color(0xFFC2E5FC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const AppSvgIcon('assets/icons/kyc/27ce3.svg', size: 20),
                label: Text(picking ? 'Opening…' : 'Upload file'),
              ),
            ),
            final name => Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove file',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          },
        ),
      ),
      if (error case final error?) ...[
        const SizedBox(height: 8),
        Text(error, style: AppTypography.body.copyWith(color: AppColors.error)),
      ],
    ],
  );
}
