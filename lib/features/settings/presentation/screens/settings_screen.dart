import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/app/startup/reset_preview_session.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paysplit/features/settings/presentation/controllers/settings_controller.dart';
import 'package:paysplit/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_back_button.dart';
import 'package:paysplit/widgets/feedback/preview_notice.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final sample = ref.watch(
      settingsControllerProvider.select((s) => s.sampleAccount),
    );
    final name = '${auth.firstName} ${auth.lastName}'.trim();
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                Row(
                  children: [
                    AppBackButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/home'),
                    ),
                    Expanded(
                      child: Semantics(
                        header: true,
                        container: true,
                        child: const Text(
                          'Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF171918),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 17),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 4,
                      children: [
                        Semantics(
                          button: true,
                          container: true,
                          label: 'Edit profile details',
                          child: InkWell(
                            onTap: () => context.push('/profile/details'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                spacing: 6,
                                children: [
                                  const ProfileAvatar(),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      spacing: 4,
                                      children: [
                                        Text(
                                          name.isEmpty ? 'Your profile' : name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          auth.email.isEmpty
                                              ? 'Account details'
                                              : auth.email,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF757575),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const AppSvgIcon(
                                    'assets/icons/settings/0243f.svg',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Row(
                          spacing: 8,
                          children: [
                            const Text(
                              'Account ID:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                sample ? 'SAMPLE0842196' : 'Not assigned',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            if (sample)
                              IconButton(
                                tooltip: 'Copy sample account ID',
                                onPressed: () async {
                                  await Clipboard.setData(
                                    const ClipboardData(text: 'SAMPLE0842196'),
                                  );
                                  if (context.mounted) {
                                    showPreviewNotice(
                                      context,
                                      'Sample account ID copied.',
                                    );
                                  }
                                },
                                icon: const AppSvgIcon(
                                  'assets/icons/settings/b02e1.svg',
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SettingsGroup(
                  title: 'Main',
                  children: [
                    SettingsRow(
                      label: 'Account Details',
                      icon: '60afd.svg',
                      onTap: () => context.push('/salary-account'),
                    ),
                    SettingsRow(
                      label: 'Notification Preference',
                      icon: '9f3cc.svg',
                      onTap: () => context.push('/profile/notifications'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SettingsGroup(
                  title: 'Security',
                  children: [
                    SettingsRow(
                      label: 'Change Password',
                      icon: '63159.svg',
                      onTap: () => context.push('/profile/password'),
                    ),
                    SettingsRow(
                      label: '2 Factor Authentication',
                      icon: 'd0dc3.svg',
                      onTap: () => context.push('/profile/security?kind=mfa'),
                    ),
                    SettingsRow(
                      label: 'Device Management',
                      icon: '9c560.svg',
                      onTap: () => context.push('/profile/devices'),
                    ),
                    SettingsRow(
                      label: 'Biometrics',
                      icon: 'f1749.svg',
                      onTap: () =>
                          context.push('/profile/security?kind=biometrics'),
                      trailing: const IgnorePointer(
                        child: ExcludeSemantics(
                          child: SettingsToggle(value: false, onChanged: null),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SettingsGroup(
                  title: 'Actions',
                  children: [
                    SettingsRow(
                      label: 'Logout',
                      icon: '07bbb.svg',
                      destructive: true,
                      arrow: false,
                      onTap: () async {
                        final confirmed = await confirmPreviewAction(
                          context,
                          title: 'Log out?',
                          message:
                              'This clears your setup and preferences on this device.',
                          action: 'Log out',
                        );
                        if (confirmed && context.mounted) {
                          resetPreviewSession(ref);
                          context.go('/login');
                        }
                      },
                    ),
                    SettingsRow(
                      label: 'Delete Account',
                      icon: 'a5ed1.svg',
                      destructive: true,
                      arrow: false,
                      onTap: () => context.push('/profile/delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
