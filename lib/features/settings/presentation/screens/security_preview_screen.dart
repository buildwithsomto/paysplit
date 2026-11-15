import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';

class SecurityPreviewScreen extends StatelessWidget {
  const SecurityPreviewScreen({this.biometrics = false, super.key});
  final bool biometrics;
  @override
  Widget build(BuildContext context) => AppPageLayout(
    title: biometrics ? 'Biometrics' : '2 Factor Authentication',
    headerTop: 17,
    bodyGap: 35,
    onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AppSvgIcon(
            'assets/icons/settings/${biometrics ? 'f1749.svg' : 'd0dc3.svg'}',
            size: 40,
          ),
        ),
        const Text(
          'Not enabled',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        Text(
          biometrics
              ? 'Biometric sign-in is unavailable.'
              : 'Two-factor authentication adds a verification step at sign-in. Setup is unavailable.',
        ),
        AppButton(
          label: biometrics ? 'Enable Biometrics' : 'Set Up 2FA',
          onPressed: null,
        ),
      ],
    ),
  );
}

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _acknowledged = false;
  @override
  Widget build(BuildContext context) => AppPageLayout(
    title: 'Delete Account',
    headerTop: 17,
    bodyGap: 35,
    onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        const Text(
          'Account closure',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const Text(
          'Closing an account affects access to your salary account, wallets and scheduled split rules. Balances, pending transactions and identity checks must be reviewed before a closure request can be accepted.',
        ),
        const Text(
          'Required financial records may be retained under the applicable policy.',
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('I understand the impact of account closure.'),
          value: _acknowledged,
          onChanged: (v) => setState(() => _acknowledged = v ?? false),
        ),
        const AppButton(label: 'Request Account Closure', onPressed: null),
        const Text('Account closure is unavailable.'),
      ],
    ),
  );
}
