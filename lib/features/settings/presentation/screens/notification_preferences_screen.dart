import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/settings/presentation/controllers/settings_controller.dart';
import 'package:paysplit/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(
      settingsControllerProvider.select((s) => s.channels),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    return AppPageLayout(
      title: 'Notification',
      headerTop: 17,
      bodyGap: 35,
      onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          for (final channel in NotificationChannel.values)
            MergeSemantics(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => controller.setChannel(
                    channel,
                    !channels.contains(channel),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${switch (channel) {
                              NotificationChannel.push => 'Push',
                              NotificationChannel.sms => 'SMS',
                              NotificationChannel.email => 'Email',
                            }} Notification',
                            style: settingsText.copyWith(fontSize: 14),
                          ),
                        ),
                        SettingsToggle(
                          value: channels.contains(channel),
                          onChanged: (v) => controller.setChannel(channel, v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const Text(
            'Choose which optional notifications you want to receive.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
          const Text(
            'Security, verification, legal and essential service messages cannot be disabled here. Preferences never change transaction execution or status.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
