import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/features/kyc/data/models/kyc_models.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/settings/presentation/controllers/profile_editor_controller.dart';
import 'package:paysplit/features/settings/presentation/controllers/settings_controller.dart';
import 'package:paysplit/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/buttons/app_text_link.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/feedback/content_status_card.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';
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
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _employer = TextEditingController();
  final _salary = TextEditingController();
  int? _payDay;

  /// What the fields were filled from; only differences are sent on save.
  ProfileForm? _initial;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(settingsControllerProvider).profile;
    if (profile != null) _fill(profile);
    // The calling codes that split the phone number come with the country
    // list, which is only loaded here when verification has not opened yet.
    if (ref.read(kycControllerProvider).countries.isEmpty) {
      Future.microtask(() {
        if (mounted) ref.read(kycControllerProvider.notifier).load();
      });
    }
  }

  /// Splits the calling code off the phone number once the country list
  /// arrives, unless the number has been edited in the meantime.
  void _splitPhone() {
    final profile = ref.read(settingsControllerProvider).profile;
    final initial = _initial;
    if (profile == null || initial == null) return;
    if (initial.dialCode != null || _phone.text != initial.phone) return;
    final form = ProfileForm.of(profile, dialCodes: _dialCodes);
    if (form.dialCode == null) return;
    setState(() {
      _initial = ProfileForm(
        name: initial.name,
        dialCode: form.dialCode,
        phone: form.phone,
        employer: initial.employer,
        salary: initial.salary,
        payDay: initial.payDay,
      );
      _phone.text = form.phone;
    });
  }

  Map<String, String> get _dialCodes => {
    for (final country in ref.read(kycControllerProvider).countries)
      country.code: country.dialCode,
  };

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _employer, _salary]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(UserProfile profile) {
    final form = ProfileForm.of(profile, dialCodes: _dialCodes);
    _initial = form;
    _name.text = form.name;
    _email.text = profile.user.email;
    _phone.text = form.phone;
    _employer.text = form.employer;
    _salary.text = form.salary;
    _payDay = form.payDay;
  }

  ProfileForm get _form => ProfileForm(
    name: _name.text,
    dialCode: _initial?.dialCode,
    phone: _phone.text,
    employer: _employer.text,
    salary: _salary.text,
    payDay: _payDay,
  );

  Future<void> _photo() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final Uint8List bytes;
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Profile image',
            extensions: ['jpg', 'jpeg', 'png', 'webp'],
            mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            uniformTypeIdentifiers: [
              'public.jpeg',
              'public.png',
              'org.webmproject.webp',
            ],
          ),
        ],
      );
      if (file == null) return;
      bytes = await file.readAsBytes();
    } on Object {
      if (mounted) {
        showAppNotice(context, 'That image couldn’t be opened. Try another.');
      }
      return;
    }
    if (!mounted) return;
    final saved = await ref
        .read(settingsControllerProvider.notifier)
        .uploadAvatar(bytes);
    if (mounted && saved) showAppNotice(context, 'Profile photo updated.');
  }

  Future<void> _removePhoto() async {
    final confirmed = await showSettingsConfirmSheet(
      context,
      title: 'Remove profile photo?',
      message: 'Your photo will be removed from your PaySplit account.',
      action: 'Remove Photo',
      icon: '506dc.svg',
    );
    if (!confirmed || !mounted) return;
    final removed = await ref
        .read(settingsControllerProvider.notifier)
        .removeAvatar();
    if (mounted && removed) showAppNotice(context, 'Profile photo removed.');
  }

  Future<void> _save() async {
    final initial = _initial;
    if (initial == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final form = _form;
    final saved = await ref
        .read(profileEditorProvider.notifier)
        .save(initial: initial, form: form);
    if (!mounted || !saved) return;
    final profile = ref.read(settingsControllerProvider).profile;
    if (profile != null) setState(() => _fill(profile));
    showAppNotice(context, 'Profile updated.');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final profile = settings.profile;
    final editorState = ref.watch(profileEditorProvider);
    final errors = editorState.errors;
    final editor = ref.read(profileEditorProvider.notifier);
    final locked = profile?.namesLocked ?? false;
    final kycStatus = KycStatus.fromApi(
      ref.watch(onboardingProvider.select((o) => o.kycStatus)),
    );
    // Fill the form once the profile arrives on a cold open.
    ref.listen(settingsControllerProvider.select((s) => s.profile), (
      previous,
      next,
    ) {
      if (next != null && _initial == null) setState(() => _fill(next));
    });
    ref.listen(kycControllerProvider.select((s) => s.countries), (_, next) {
      if (next.isNotEmpty) _splitPhone();
    });
    ref.listen(settingsControllerProvider.select((s) => s.error), (_, next) {
      if (next != null) showAppNotice(context, next);
    });
    ref.listen(profileEditorProvider.select((s) => s.errors['form']), (
      _,
      next,
    ) {
      if (next != null) showAppNotice(context, next);
    });
    final dialCode = _initial?.dialCode;
    return AppPageLayout(
      title: 'Profile Details',
      headerTop: 17,
      bodyGap: 28,
      onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
      bottom: profile == null
          ? null
          : AppButton(
              label: 'Save Changes',
              busy: editorState.busy,
              onPressed: _save,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (settings.phase != ContentPhase.ready &&
              !(settings.phase == ContentPhase.refreshing &&
                  profile != null)) ...[
            ContentStatusCard(
              phase: settings.phase,
              hasContent: profile != null,
              subject: 'Profile',
              items: 'profile details',
              message: settings.message,
              updatedAt: settings.updatedAt,
              onRetry: ref.read(settingsControllerProvider.notifier).load,
              skeleton: const Column(
                children: [
                  SkeletonBox.circle(88),
                  SizedBox(height: 28),
                  SkeletonForm(fields: 4),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (profile != null) ...[
            Center(
              child: SizedBox(
                width: 108,
                height: 108,
                child: Stack(
                  children: [
                    const ProfileAvatar(size: 100),
                    if (settings.avatarBusy)
                      const Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(right: 8, bottom: 8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0x66FFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  semanticsLabel: 'Updating photo',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton(
                        tooltip: 'Change profile photo',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFFEBEBEB),
                            width: 2,
                          ),
                        ),
                        onPressed: settings.avatarBusy ? null : _photo,
                        icon: const AppSvgIcon(
                          'assets/icons/settings/506dc.svg',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (settings.profileImageUrl != null)
              Center(
                child: AppTextLink(
                  label: 'Remove photo',
                  onPressed: settings.avatarBusy ? null : _removePhoto,
                ),
              ),
            const SizedBox(height: 16),
            AppInputField(
              label: 'Full Name',
              controller: _name,
              readOnly: locked,
              error: errors['name'],
              onChanged: (_) => editor.clearError('name'),
            ),
            if (locked)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Your name matches your verified ID and can’t be changed.',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
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
              keyboardType: TextInputType.phone,
              error: errors['phone'],
              onChanged: (_) => editor.clearError('phone'),
              prefix: dialCode == null
                  ? null
                  : Container(
                      constraints: const BoxConstraints(
                        minWidth: 68,
                        minHeight: 50,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFFD0D5DD)),
                        ),
                      ),
                      child: Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Text(
                          dialCode,
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
                  title: 'Expected Payday',
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
            if (_payDay != null && _payDay! > 28)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'In shorter months your payday falls on the last day.',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
              ),
            const SizedBox(height: 20),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFEDEDED)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/kyc/result'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            const Text(
                              'Identity Verification',
                              style: AppTypography.label,
                            ),
                            Text(kycStatus.label, style: AppTypography.body),
                          ],
                        ),
                      ),
                      const AppSvgIcon(
                        'assets/icons/dashboard/9c184.svg',
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
