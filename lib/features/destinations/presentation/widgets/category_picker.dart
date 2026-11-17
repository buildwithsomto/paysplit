import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/features/destinations/data/models/destination_category.dart';
import 'package:paysplit/features/destinations/data/repositories/destinations_repository.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/overlays/choice_sheet.dart';

/// Opens the category list under [title] and returns the user's choice.
///
/// Returns null when the sheet is dismissed, or when the list could not be
/// loaded: a notice then says why, and the next call loads it again.
Future<DestinationCategory?> pickCategory(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  DestinationCategory? selected,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final List<DestinationCategory> categories;
  try {
    categories = await ref.read(categoriesProvider.future);
  } on Object catch (error) {
    ref.invalidate(categoriesProvider);
    if (context.mounted) {
      showAppNotice(
        context,
        describeError(error, fallback: 'Categories could not be loaded.'),
      );
    }
    return null;
  }
  if (!context.mounted) return null;
  return showChoiceSheet(
    context,
    title: title,
    choices: categories,
    label: (category) => category.name,
    selected: selected,
  );
}
