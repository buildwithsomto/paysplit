import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/kyc/presentation/widgets/kyc_section.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';
import 'package:paysplit/widgets/inputs/app_select_field.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';
import 'package:paysplit/widgets/overlays/choice_sheet.dart';

class ProfileBasicsScreen extends ConsumerStatefulWidget {
  const ProfileBasicsScreen({super.key});
  @override
  ConsumerState<ProfileBasicsScreen> createState() =>
      _ProfileBasicsScreenState();
}

class _ProfileBasicsScreenState extends ConsumerState<ProfileBasicsScreen> {
  late final _phone = TextEditingController(
    text: ref.read(kycControllerProvider).phone,
  );
  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _chooseCountry({bool dialCodeOnly = false}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final state = ref.read(kycControllerProvider);
    final country = await showChoiceSheet(
      context,
      title: dialCodeOnly ? 'Country Calling Code' : 'Residence Country',
      choices: state.countries,
      selected: state.country,
      label: (country) =>
          dialCodeOnly ? '${country.name} (${country.dialCode})' : country.name,
    );
    if (!mounted || country == null) return;
    final controller = ref.read(kycControllerProvider.notifier);
    if (dialCodeOnly) {
      controller.selectDialCode(country.dialCode);
    } else {
      controller.selectCountry(country);
    }
  }

  Future<void> _continue() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await ref
        .read(kycControllerProvider.notifier)
        .submitBasics(_phone.text);
    if (!mounted || !saved) return;
    context.push('/kyc/identity');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycControllerProvider);
    // The saved number arrives after the first frame on a resumed session.
    ref.listen(kycControllerProvider.select((s) => s.phone), (previous, next) {
      if (_phone.text.isEmpty && next.isNotEmpty) _phone.text = next;
    });
    ref.listen(kycControllerProvider.select((s) => s.errors['form']), (
      previous,
      next,
    ) {
      if (next != null) showAppNotice(context, next);
    });
    final loadFailed = state.countries.isEmpty && state.phase.isFailure;
    return AppPageLayout(
      title: 'Profile Verification',
      onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      bottom: loadFailed
          ? AppButton(
              label: 'Try again',
              onPressed: () => ref.read(kycControllerProvider.notifier).load(),
            )
          : AppButton(
              label: 'Continue',
              busy: state.busy || state.countries.isEmpty,
              onPressed: _continue,
            ),
      child: KycSection(
        step: 1,
        title: 'Profile Basics',
        description: loadFailed
            ? state.phase == ContentPhase.offline
                  ? 'You’re offline. Reconnect to load the supported countries.'
                  : 'Supported countries could not be loaded. Try again.'
            : 'Select your operating region and default currency for salary processing.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppInputField(
              label: 'Mobile Phone Number',
              controller: _phone,
              labelGap: 6,
              hint: '803 456 7890',
              error: state.errors['phone'],
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _continue(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              onChanged: (_) =>
                  ref.read(kycControllerProvider.notifier).clearError('phone'),
              prefix: Semantics(
                button: true,
                label: 'Country Calling Code',
                child: InkWell(
                  onTap: () => _chooseCountry(dialCodeOnly: true),
                  child: Container(
                    width:
                        (91 * MediaQuery.textScalerOf(context).scale(16) / 16)
                            .clamp(91, 180),
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            state.dialCode,
                            maxLines: 1,
                            style: AppTypography.input.copyWith(
                              color: AppColors.placeholder,
                            ),
                          ),
                        ),
                        const AppSvgIcon(
                          'assets/icons/kyc/f027b.svg',
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppSelectField(
              label: 'Residence Country',
              value: state.country?.name,
              error: state.errors['country'],
              onPressed: _chooseCountry,
            ),
          ],
        ),
      ),
    );
  }
}
