import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/settings/presentation/controllers/settings_controller.dart';
import 'package:paysplit/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/feedback/preview_notice.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';

class DeviceManagementScreen extends ConsumerWidget {
  const DeviceManagementScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    return AppPageLayout(
      title: 'Device Management',
      headerTop: 17,
      bodyGap: 35,
      onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          if (state.devices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No active device sessions.'),
            ),
          for (final (index, device) in state.devices.indexed)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  if (device.current)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16813A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            AppSvgIcon(
                              'assets/icons/settings/ceb68.svg',
                              size: 8,
                            ),
                            Text(
                              'Active Device · Sample',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 10,
                                color: Colors.white,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          tooltip: 'Remove ${device.name} sample session',
                          icon: const AppSvgIcon(
                            'assets/icons/settings/764d0.svg',
                          ),
                          onPressed: () async {
                            final confirmed = await confirmPreviewAction(
                              context,
                              title: 'Remove sample session?',
                              message: 'Remove ${device.name} from this list?',
                              action: 'Remove sample',
                            );
                            if (confirmed && context.mounted) {
                              ref
                                  .read(settingsControllerProvider.notifier)
                                  .removeSampleDevice(device.id);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF323232),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Expanded(
                        child: Text(
                          device.location,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Last seen ${device.lastSeen}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.6,
                            color: Color(0xFF737373),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 0),
          if (state.devices.isNotEmpty)
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0x1AFF383C),
                foregroundColor: const Color(0xFFB42318),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const AppSvgIcon(
                'assets/icons/settings/635da.svg',
                size: 14,
              ),
              label: const Text('Log Out All Devices'),
              onPressed: () async {
                final confirmed = await confirmPreviewAction(
                  context,
                  title: 'Clear sample sessions?',
                  message: 'Remove all devices from this list?',
                  action: 'Clear samples',
                );
                if (confirmed && context.mounted) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .clearSampleDevices();
                  showPreviewNotice(
                    context,
                    'Sample sessions cleared. No real devices were logged out.',
                  );
                }
              },
            ),
          if (state.sampleAccount)
            const Text(
              'Sample devices and locations from the design. These are not a list of devices signed in to your account.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
        ],
      ),
    );
  }
}
