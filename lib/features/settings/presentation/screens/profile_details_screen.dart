import 'dart:ui' as ui;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/settings/presentation/controllers/profile_editor_controller.dart';
import 'package:paysplit/features/settings/presentation/controllers/settings_controller.dart';
import 'package:paysplit/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_controller.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/feedback/preview_notice.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';
import 'package:paysplit/widgets/inputs/app_select_field.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';
import 'package:paysplit/widgets/overlays/choice_sheet.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({super.key});
  @override
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  late final TextEditingController _name, _email, _phone, _employer, _salary;
  int? _payDay;
  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    final kyc = ref.read(kycControllerProvider);
    final salary = ref.read(setupControllerProvider);
    _name = TextEditingController(
      text: '${auth.firstName} ${auth.lastName}'.trim(),
    );
    _email = TextEditingController(text: auth.email);
    _phone = TextEditingController(text: kyc.phone);
    _employer = TextEditingController(text: salary.employer);
    _salary = TextEditingController(text: salary.salaryInput);
    _payDay = salary.payDay;
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _employer, _salary]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _photo() async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Profile image',
            extensions: ['jpg', 'jpeg', 'png'],
            mimeTypes: ['image/jpeg', 'image/png'],
            uniformTypeIdentifiers: ['public.jpeg', 'public.png'],
          ),
        ],
      );
      if (file == null || !mounted) {
        return;
      }
      if (await file.length() > 5 * 1024 * 1024) {
        if (mounted) {
          showPreviewNotice(context, 'Choose a JPG or PNG smaller than 5 MB.');
        }
        return;
      }
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 300,
        allowUpscaling: false,
      );
      try {
        final frame = await codec.getNextFrame();
        try {
          final data = await frame.image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (!mounted || data == null) {
            return;
          }
          ref
              .read(settingsControllerProvider.notifier)
              .setAvatar(data.buffer.asUint8List());
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
      if (!mounted) {
        return;
      }
      showPreviewNotice(
        context,
        'Photo selected locally. Nothing was uploaded.',
      );
    } catch (_) {
      if (mounted) {
        showPreviewNotice(
          context,
          'Unable to open that image. Choose a valid JPG or PNG.',
        );
      }
    }
  }

  void _save() {
    if (!ref
        .read(profileEditorProvider.notifier)
        .save(
          name: _name.text,
          phone: _phone.text,
          employer: _employer.text,
          salary: _salary.text,
          payDay: _payDay,
        )) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    showPreviewNotice(context, 'Profile saved on this device.');
  }

  @override
  Widget build(BuildContext context) {
    final kyc = ref.watch(kycControllerProvider);
    final errors = ref.watch(profileEditorProvider);
    final editor = ref.read(profileEditorProvider.notifier);
    final locked = kyc.status.identityFieldsLocked;
    return AppPageLayout(
      title: 'Profile Details',
      headerTop: 17,
      bodyGap: 28,
      onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 108,
              height: 108,
              child: Stack(
                children: [
                  const ProfileAvatar(size: 100),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton(
                      tooltip: 'Choose profile photo',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFFEBEBEB),
                          width: 2,
                        ),
                      ),
                      onPressed: _photo,
                      icon: const AppSvgIcon('assets/icons/settings/506dc.svg'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (ref.watch(
            settingsControllerProvider.select((s) => s.avatar != null),
          ))
            TextButton(
              onPressed: () =>
                  ref.read(settingsControllerProvider.notifier).clearAvatar(),
              child: const Text('Remove local photo'),
            ),
          const SizedBox(height: 16),
          AppInputField(
            label: 'Full Name',
            controller: _name,
            readOnly: locked,
            error: errors['name'],
            onChanged: (_) => editor.clearError('name'),
          ),
          const SizedBox(height: 12),
          AppInputField(
            label: 'Email Address',
            controller: _email,
            readOnly: true,
            hint: 'Not provided',
          ),
          const SizedBox(height: 12),
          AppInputField(
            label: 'Mobile Phone Number',
            controller: _phone,
            readOnly: locked,
            keyboardType: TextInputType.phone,
            error: errors['phone'],
            onChanged: (_) => editor.clearError('phone'),
            prefix: Container(
              constraints: const BoxConstraints(minWidth: 68, minHeight: 50),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFD0D5DD))),
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  kyc.dialCode,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppInputField(
            label: 'Employer',
            controller: _employer,
            error: errors['employer'],
            onChanged: (_) => editor.clearError('employer'),
          ),
          const SizedBox(height: 12),
          AppInputField(
            label: 'Monthly Salary Amount (₦)',
            controller: _salary,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            error: errors['salary'],
            onChanged: (_) => editor.clearError('salary'),
          ),
          const SizedBox(height: 12),
          AppSelectField(
            label: 'Expected Payday',
            hint: 'Select',
            value: _payDay == null ? null : 'Day $_payDay',
            error: errors['day'],
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              final day = await showChoiceSheet<int>(
                context,
                title: 'Expected payday',
                choices: List.generate(31, (i) => i + 1),
                label: (v) => 'Day $v',
                selected: _payDay,
              );
              if (day != null && mounted) {
                setState(() => _payDay = day);
                editor.clearError('day');
              }
            },
          ),
          const SizedBox(height: 20),
          AppButton(label: 'Save Local Changes', onPressed: _save),
          const SizedBox(height: 16),
          Text(
            'Verification: ${kyc.status.label}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () => context.push(
              kyc.status == KycStatus.unverified ? '/kyc' : '/kyc/result',
            ),
            child: const Text('View verification and next steps'),
          ),
          Text(
            locked
                ? 'Identity details are read-only while verification is approved, under review or requires re-verification. Sensitive changes and email updates require verification.'
                : 'Changing your email requires re-verification.',
            style: const TextStyle(fontSize: 12, height: 1.5),
          ),
          if (_payDay != null && _payDay! > 28)
            const Text(
              'For shorter months, the expected payday is the last calendar day. This does not trigger transfers.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
        ],
      ),
    );
  }
}
