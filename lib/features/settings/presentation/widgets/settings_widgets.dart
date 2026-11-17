import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';

const settingsText = TextStyle(
  fontFamily: 'DM Sans',
  fontSize: 16,
  height: 1.6,
  fontWeight: FontWeight.w500,
  color: Color(0xFF323232),
);

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.title, required this.children, super.key});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 10,
    children: [
      Semantics(
        header: true,
        container: true,
        child: Text(title, style: settingsText),
      ),
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.only(left: 36),
                    child: AppSvgIcon(
                      'assets/icons/settings/612b3.svg',
                      width: double.infinity,
                      height: 1,
                    ),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
    this.trailing,
    this.arrow = true,
    super.key,
  });
  final String label, icon;
  final VoidCallback? onTap;
  final bool destructive, arrow;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    container: true,
    enabled: onTap != null,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: trailing == null ? 12 : 0),
        child: Row(
          spacing: 12,
          children: [
            AppSvgIcon('assets/icons/settings/$icon', size: 24),
            Expanded(
              child: Text(
                label,
                style: settingsText.copyWith(
                  color: destructive ? const Color(0xFFB42318) : null,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else if (arrow)
              const RotatedBox(
                quarterTurns: 2,
                child: AppSvgIcon('assets/icons/settings/3736e.svg', size: 18),
              ),
          ],
        ),
      ),
    ),
  );
}

class SettingsToggle extends StatelessWidget {
  const SettingsToggle({
    required this.value,
    required this.onChanged,
    super.key,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 48,
    height: 48,
    child: Center(
      child: Transform.scale(
        scale: .73,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.action,
          activeThumbColor: Colors.white,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFF8A8A8A),
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    ),
  );
}

/// The signed-in user's picture, or the design's default avatar while there
/// is none, it is still loading or it cannot be fetched.
///
/// Reads `AppUser.profileImageUrl` from [accountControllerProvider], so every
/// screen that shows it (Home, Profile, Profile Details) changes together.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({this.size = 50, this.placeholderAsset, super.key});
  final double size;
  final String? placeholderAsset;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(
      accountControllerProvider.select((s) => s.user?.profileImageUrl),
    );
    final placeholder = Image.asset(
      placeholderAsset ??
          'assets/icons/settings/${size > 50 ? 'ab21a.png' : '21511.png'}',
      width: size,
      height: size,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
    );
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || !uri.isScheme('https')) {
      return ClipOval(child: placeholder);
    }
    // Uploads can be several megapixels; decode only what the circle needs.
    final pixels = (size * MediaQuery.devicePixelRatioOf(context) * 2).round();
    return ClipOval(
      child: Image(
        key: ValueKey(url),
        image: ResizeImage(
          NetworkImage(uri.toString()),
          width: pixels,
          height: pixels,
          policy: ResizeImagePolicy.fit,
        ),
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        frameBuilder: (context, child, frame, synchronous) =>
            frame == null && !synchronous ? placeholder : child,
        errorBuilder: (context, error, stack) => placeholder,
      ),
    );
  }
}

/// The round tinted badge that opens a settings sheet or empty state.
class SettingsBadge extends StatelessWidget {
  const SettingsBadge({
    required this.icon,
    this.destructive = false,
    super.key,
  });

  /// A file name in `assets/icons/settings`.
  final String icon;
  final bool destructive;
  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: destructive ? const Color(0x1AFF383C) : AppColors.primaryLight,
    ),
    child: AppSvgIcon('assets/icons/settings/$icon', size: 28),
  );
}

/// Badge, title and one short paragraph: the shared body of settings sheets.
class SettingsMessage extends StatelessWidget {
  const SettingsMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.destructive = false,
    super.key,
  });
  final String icon, title, message;
  final bool destructive;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SettingsBadge(icon: icon, destructive: destructive),
      const SizedBox(height: 20),
      Semantics(
        header: true,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 20,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
          ),
        ),
      ),
      const SizedBox(height: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            height: 20 / 14,
            color: AppColors.body,
          ),
        ),
      ),
    ],
  );
}

Future<T?> _showSettingsSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (sheetContext) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 36),
    child: SingleChildScrollView(
      padding: const EdgeInsets.only(top: 36),
      child: builder(sheetContext),
    ),
  ),
);

/// Asks before an action that signs the user out or removes something.
/// Resolves to true only when the user confirms.
Future<bool> showSettingsConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  required String icon,
  bool destructive = true,
}) async =>
    await _showSettingsSheet<bool>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsMessage(
            icon: icon,
            title: title,
            message: message,
            destructive: destructive,
          ),
          const SizedBox(height: 32),
          Row(
            spacing: 16,
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  outlined: true,
                  onPressed: () => Navigator.pop(sheetContext, false),
                ),
              ),
              Expanded(
                child: destructive
                    ? FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          padding: const EdgeInsets.all(12),
                          textStyle: AppTypography.button,
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(action, textAlign: TextAlign.center),
                      )
                    : AppButton(
                        label: action,
                        onPressed: () => Navigator.pop(sheetContext, true),
                      ),
              ),
            ],
          ),
        ],
      ),
    ) ??
    false;

/// A settings feature the account cannot use yet.
enum UnavailableFeature {
  twoFactor(
    icon: 'd0dc3.svg',
    title: 'Two-factor authentication is coming soon',
    message:
        'An extra sign-in step for your account is on the way. '
        'You’ll be able to set it up here.',
  ),
  deviceManagement(
    icon: '9c560.svg',
    title: 'Device management is coming soon',
    message:
        'Seeing and signing out your other devices one by one is on the '
        'way. Logging out already signs you out everywhere.',
  ),
  biometrics(
    icon: 'f1749.svg',
    title: 'Biometric sign-in is coming soon',
    message:
        'Signing in with your face or fingerprint is on the way. '
        'You’ll be able to turn it on here.',
  ),
  deleteAccount(
    icon: 'a5ed1.svg',
    title: 'Account deletion isn’t available yet',
    message:
        'You can’t close your PaySplit account from the app right now. '
        'Nothing about your account has changed.',
    destructive: true,
  );

  const UnavailableFeature({
    required this.icon,
    required this.title,
    required this.message,
    this.destructive = false,
  });
  final String icon, title, message;
  final bool destructive;
}

/// Says plainly that [feature] cannot be used yet, without starting a flow.
Future<void> showUnavailableSheet(
  BuildContext context,
  UnavailableFeature feature,
) => _showSettingsSheet<void>(
  context,
  builder: (sheetContext) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SettingsMessage(
        icon: feature.icon,
        title: feature.title,
        message: feature.message,
        destructive: feature.destructive,
      ),
      const SizedBox(height: 32),
      AppButton(label: 'Got It', onPressed: () => Navigator.pop(sheetContext)),
    ],
  ),
);
