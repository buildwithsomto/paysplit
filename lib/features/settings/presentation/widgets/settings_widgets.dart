import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/settings/presentation/controllers/settings_controller.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

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
          activeTrackColor: const Color(0xFF006BAA),
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

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({this.size = 50, this.placeholderAsset, super.key});
  final double size;
  final String? placeholderAsset;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(settingsControllerProvider.select((s) => s.avatar));
    return ClipOval(
      child: bytes == null
          ? Image.asset(
              placeholderAsset ??
                  'assets/icons/settings/${size > 50 ? 'ab21a.png' : '21511.png'}',
              width: size,
              height: size,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            )
          : Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
    );
  }
}

Future<bool> confirmPreviewAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
