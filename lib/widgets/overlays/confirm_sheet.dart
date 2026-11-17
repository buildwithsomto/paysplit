import 'package:flutter/material.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';

/// Asks before an action that removes something or moves money, in the app's
/// own sheet style. Resolves to true only when the user confirms.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 36),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.sheetTitle,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.sheetBody,
              ),
              const SizedBox(height: 28),
              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      outlined: true,
                      onPressed: () => Navigator.pop(sheetContext, false),
                    ),
                  ),
                  Expanded(
                    child: destructive
                        ? FilledButton(
                            onPressed: () => Navigator.pop(sheetContext, true),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(action, textAlign: TextAlign.center),
                          )
                        : AppButton(
                            label: action,
                            onPressed: () => Navigator.pop(sheetContext, true),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ??
    false;
