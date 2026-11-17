import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/widgets/overlays/success_sheet_layout.dart';

Future<void> showDestinationSuccess(
  BuildContext context, {
  required bool beneficiary,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (sheetContext) => DestinationSuccessSheet(
    beneficiary: beneficiary,
    onClose: () => Navigator.pop(sheetContext),
    onHome: () {
      Navigator.pop(sheetContext);
      context.go('/home');
    },
  ),
);

class DestinationSuccessSheet extends StatelessWidget {
  const DestinationSuccessSheet({
    required this.beneficiary,
    required this.onClose,
    required this.onHome,
    super.key,
  });
  final bool beneficiary;
  final VoidCallback onClose;
  final VoidCallback onHome;
  @override
  Widget build(BuildContext context) => SuccessSheetLayout(
    title: '${beneficiary ? 'Beneficiary' : 'Wallet'} Created Successfully',
    message: 'Saved to your destinations.',
    onClose: onClose,
    onHome: onHome,
  );
}
