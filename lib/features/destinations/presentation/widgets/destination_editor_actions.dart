import 'package:flutter/material.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';

class DestinationEditorActions extends StatelessWidget {
  const DestinationEditorActions({
    required this.onSave,
    required this.onSaveAndCreateRule,
    super.key,
  });

  final VoidCallback onSave;
  final VoidCallback onSaveAndCreateRule;

  @override
  Widget build(BuildContext context) {
    final save = AppButton(label: 'Save', outlined: true, onPressed: onSave);
    final createRule = AppButton(
      label: 'Save and create rule',
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
        Expanded(flex: 2, child: createRule),
      ],
    );
  }
}
