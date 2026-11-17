import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/settings/presentation/controllers/settings_controller.dart';
import 'package:paysplit/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});
  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  @override
  void initState() {
    super.initState();
    // The toggles show the saved choices at once and refresh in place.
    Future.microtask(() {
      if (mounted) {
        ref.read(settingsControllerProvider.notifier).loadPreferences();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsControllerProvider.select((s) => s.error), (_, next) {
      if (next != null) showAppNotice(context, next);
    });
    final ready = ref.watch(
      settingsControllerProvider.select((s) => s.preferences != null),
    );
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
                  onTap: !ready
                      ? null
                      : () => controller.setChannel(
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
                            '${channel.label} Notification',
                            style: settingsText.copyWith(fontSize: 14),
                          ),
                        ),
                        SettingsToggle(
                          value: channels.contains(channel),
                          onChanged: (v) {
                            if (ready) controller.setChannel(channel, v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const Text(
            'Choose how you hear about salary credits, completed splits, transfers and account updates. Only email is delivered right now; your push and SMS choices are saved for when they launch.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
