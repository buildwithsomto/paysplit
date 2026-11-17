import 'package:flutter/material.dart';
import 'package:paysplit/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/config/app_config.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paysplit/features/settings/presentation/controllers/settings_controller.dart';
import 'package:paysplit/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_back_button.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/feedback/content_status_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    // Reopening Profile checks for changes made elsewhere.
    Future.microtask(() {
      if (mounted) ref.read(settingsControllerProvider.notifier).load();
    });
  }

  Future<void> _copyAccountId(String accountId) async {
    await Clipboard.setData(ClipboardData(text: accountId));
    if (mounted) showAppNotice(context, 'Account ID copied.');
  }

  Future<void> _logout() async {
    final confirmed = await showSettingsConfirmSheet(
      context,
      icon: '07bbb.svg',
      title: 'Log out of PaySplit?',
      message: 'You’ll be signed out on this device and any other device.',
      action: 'Log Out',
    );
    if (!confirmed || !mounted) return;
    setState(() => _loggingOut = true);
    // The router returns to login once the session ends.
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) setState(() => _loggingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(accountControllerProvider.select((s) => s.user));
    final settings = ref.watch(settingsControllerProvider);
    final accountId = settings.profile?.accountId ?? '';
    final name = user?.fullName ?? '';
    final email = user?.email ?? '';
    // The dashboard behind this screen uses light status bar icons.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlay,
      child: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: RefreshIndicator(
                color: AppColors.action,
                onRefresh: () =>
                    ref.read(settingsControllerProvider.notifier).load(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                    if (settings.phase.isFailure) ...[
                      ContentStatusCard(
                        phase: settings.phase,
                        hasContent: settings.hasData,
                        subject: 'Profile',
                        items: 'profile details',
                        message: settings.message,
                        updatedAt: settings.updatedAt,
                        onRetry: () => ref
                            .read(settingsControllerProvider.notifier)
                            .load(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 4,
                          children: [
                            Semantics(
                              button: true,
                              container: true,
                              label: 'Edit profile details',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => context.push('/profile/details'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
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
                                              name.isEmpty
                                                  ? 'Your profile'
                                                  : name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              email.isEmpty
                                                  ? 'Account details'
                                                  : email,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 40),
                              child: Row(
                                spacing: 8,
                                children: [
                                  const Text(
                                    'Account ID:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                  if (accountId.isNotEmpty) ...[
                                    Flexible(
                                      child: Text(
                                        accountId,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Copy account ID',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          _copyAccountId(accountId),
                                      icon: const AppSvgIcon(
                                        'assets/icons/settings/b02e1.svg',
                                        size: 16,
                                      ),
                                    ),
                                  ] else if (settings.phase.isBusy)
                                    Semantics(
                                      label: 'Loading account ID',
                                      child: Container(
                                        width: 104,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEDEDED),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const Text(
                                      'Unavailable',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF757575),
                                      ),
                                    ),
                                ],
                              ),
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
                          onTap: () => showUnavailableSheet(
                            context,
                            UnavailableFeature.twoFactor,
                          ),
                        ),
                        SettingsRow(
                          label: 'Device Management',
                          icon: '9c560.svg',
                          onTap: () => showUnavailableSheet(
                            context,
                            UnavailableFeature.deviceManagement,
                          ),
                        ),
                        SettingsRow(
                          label: 'Biometrics',
                          icon: 'f1749.svg',
                          onTap: () => showUnavailableSheet(
                            context,
                            UnavailableFeature.biometrics,
                          ),
                          // Stays off until biometric sign-in exists.
                          trailing: const IgnorePointer(
                            child: ExcludeSemantics(
                              child: SettingsToggle(
                                value: false,
                                onChanged: null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (ref.watch(appConfigProvider).sandboxToolsEnabled) ...[
                      const SizedBox(height: 12),
                      // Test backends only; hidden in production builds.
                      SettingsGroup(
                        title: 'Sandbox',
                        children: [
                          SettingsRow(
                            label: 'Simulate Salary Credit',
                            icon: '60afd.svg',
                            onTap: () => context.push('/sandbox'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    SettingsGroup(
                      title: 'Actions',
                      children: [
                        SettingsRow(
                          label: 'Logout',
                          icon: '07bbb.svg',
                          destructive: true,
                          arrow: false,
                          onTap: _loggingOut ? null : _logout,
                          trailing: _loggingOut
                              ? const SizedBox.square(
                                  dimension: 48,
                                  child: Center(
                                    child: SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.error,
                                        semanticsLabel: 'Logging out',
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        SettingsRow(
                          label: 'Delete Account',
                          icon: 'a5ed1.svg',
                          destructive: true,
                          arrow: false,
                          onTap: () => showUnavailableSheet(
                            context,
                            UnavailableFeature.deleteAccount,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
