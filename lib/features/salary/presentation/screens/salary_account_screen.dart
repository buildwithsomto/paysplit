import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/salary/presentation/controllers/salary_account_controller.dart';
import 'package:paysplit/features/salary/presentation/widgets/salary_account_status_card.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/feedback/preview_notice.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';

class SalaryAccountScreen extends ConsumerWidget {
  const SalaryAccountScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sample = ref.watch(salaryAccountProvider.select((s) => s.hasDetails));
    return AppPageLayout(
      title: 'Account Details',
      bodyGap: 27,
      onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!sample ||
              ref.watch(salaryAccountProvider).expectedSalaryDate != null) ...[
            const SalaryAccountStatusCard(),
            const SizedBox(height: 20),
          ],
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFEAF6FF), Colors.white],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          const Expanded(
                            child: Text(
                              'Account Number',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF171918),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: sample
                                ? 'Copy sample account number'
                                : 'Account not available',
                            onPressed: sample
                                ? () async {
                                    await Clipboard.setData(
                                      const ClipboardData(text: '0000000000'),
                                    );
                                    if (context.mounted) {
                                      showPreviewNotice(
                                        context,
                                        'Sample number copied. This is not a bank account.',
                                      );
                                    }
                                  }
                                : null,
                            icon: const AppSvgIcon(
                              'assets/icons/dashboard/d637b.svg',
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      SelectableText(
                        sample ? '0000000000' : 'Not available',
                        style: const TextStyle(
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w700,
                          fontSize: 36,
                          color: Color(0xFF171918),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Name',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.placeholder,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sample ? 'Paul Clarke · Sample' : 'Not provisioned',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF171918),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Bank Name',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.placeholder,
                        ),
                      ),
                      Text(
                        sample
                            ? 'Demo bank / PaySplit'
                            : 'Awaiting provider connection',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            sample
                ? 'Sample account number. Do not send funds.'
                : 'Your dedicated account details will appear here after verification and account provisioning.',
          ),
        ],
      ),
    );
  }
}
