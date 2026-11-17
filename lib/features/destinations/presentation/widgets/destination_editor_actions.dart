import 'package:flutter/material.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';

/// "Save" and "Create Rule", as on the wallet and beneficiary overlays.
class DestinationEditorActions extends StatelessWidget {
  const DestinationEditorActions({
    required this.onSave,
    required this.onSaveAndCreateRule,
    this.busy = false,
    super.key,
  });

  /// Null disables the button, for example while the form is still loading.
  final VoidCallback? onSave, onSaveAndCreateRule;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final save = AppButton(
      label: 'Save',
      outlined: true,
      busy: busy,
      onPressed: onSave,
    );
    final createRule = AppButton(
      label: 'Create Rule',
      busy: busy,
      onPressed: onSaveAndCreateRule,
    );
    if (MediaQuery.textScalerOf(context).scale(14) > 18) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [save, createRule],
      );
    }
    return Row(
      spacing: 16,
      children: [
        Expanded(child: save),
        Expanded(child: createRule),
      ],
    );
  }
}
