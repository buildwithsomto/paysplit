import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/features/salary/presentation/controllers/salary_account_controller.dart';
import 'package:paysplit/features/salary/presentation/widgets/salary_account_status_card.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/feedback/content_status_card.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';

/// "Account Details": the bank account salary is paid into.
class SalaryAccountScreen extends ConsumerWidget {
  const SalaryAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salaryAccountProvider);
    final account = state.account;
    final accounts = account?.accounts ?? const [];
    return AppPageLayout(
      title: 'Account Details',
      bodyGap: 27,
      onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.phase != ContentPhase.ready &&
              !(state.phase == ContentPhase.refreshing && account != null)) ...[
            ContentStatusCard(
              phase: state.phase,
              hasContent: account != null,
              subject: 'Account details',
              items: 'account details',
              message: state.message,
              updatedAt: state.updatedAt,
              onRetry: ref.read(salaryAccountProvider.notifier).load,
              skeleton: const Column(
                spacing: 16,
                children: [
                  SkeletonBox.card(height: 120),
                  SkeletonDetail(rows: 3),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (account != null && !account.isActive) ...[
            const SalaryAccountStatusCard(),
            const SizedBox(height: 20),
          ],
          // Before the account is active the API returns no numbers; an
          // empty card keeps the screen's shape until they arrive.
          if (account != null && accounts.isEmpty)
            _AccountCard(accountName: account.accountName)
          else
            for (final (index, funding) in accounts.indexed) ...[
              if (index > 0) const SizedBox(height: 16),
              _AccountCard(
                number: funding.accountNumber,
                accountName: funding.accountName,
                bankName: funding.bankName,
              ),
            ],
          if (account != null && account.isActive) ...[
            const SizedBox(height: 20),
            const Text(
              'Share these details with your employer. Salary paid into this account is split by your rules.',
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({this.number, this.accountName, this.bankName});
  final String? number, accountName, bankName;

  @override
  Widget build(BuildContext context) {
    final number = this.number;
    return Container(
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
                  children: [
                    // The copy icon sits a fixed distance in, as designed,
                    // not at the card's right edge.
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 180),
                        child: const Text(
                          'Account Number',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF171918),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: number == null
                          ? 'Account number not available yet'
                          : 'Copy account number',
                      onPressed: number == null
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: number),
                              );
                              if (context.mounted) {
                                showAppNotice(
                                  context,
                                  'Account number copied.',
                                );
                              }
                            },
                      icon: Opacity(
                        opacity: number == null ? .4 : 1,
                        child: const AppSvgIcon(
                          'assets/icons/dashboard/d637b.svg',
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                if (number == null)
                  const Text(
                    '—  —  —  —',
                    style: TextStyle(
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w700,
                      fontSize: 36,
                      color: Color(0xFFB8BCC4),
                    ),
                  )
                else
                  SelectableText(
                    number,
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Name',
                  style: TextStyle(fontSize: 12, color: AppColors.placeholder),
                ),
                const SizedBox(height: 6),
                Text(
                  accountName ?? '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF171918),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Bank Name:',
                  style: TextStyle(fontSize: 12, color: AppColors.placeholder),
                ),
                Text(
                  bankName ?? 'Available once your account is ready',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
