import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';
import 'package:paysplit/widgets/overlays/editor_sheet_layout.dart';

/// A single-choice picker in the same sheet style as the design's
/// "Choose Wallet" overlay. Longer lists get a search field.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> choices,
  required String Function(T) label,
  T? selected,
}) => showModalBottomSheet<T>(
  context: context,
  // Above the tab bar, which would otherwise cover the last choices.
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => _ChoiceSheet<T>(
    title: title,
    choices: choices,
    label: label,
    selected: selected,
  ),
);

class _ChoiceSheet<T> extends StatefulWidget {
  const _ChoiceSheet({
    required this.title,
    required this.choices,
    required this.label,
    this.selected,
  });
  final String title;
  final List<T> choices;
  final String Function(T) label;
  final T? selected;
  @override
  State<_ChoiceSheet<T>> createState() => _ChoiceSheetState<T>();
}

class _ChoiceSheetState<T> extends State<_ChoiceSheet<T>> {
  static const _rowExtent = 64.0;
  String _query = '';

  bool get _searchable => widget.choices.length > 6;

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final choices = query.isEmpty
        ? widget.choices
        : widget.choices
              .where(
                (value) => widget.label(value).toLowerCase().contains(query),
              )
              .toList();
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    // Short lists hug their rows; long ones stop short of the status bar.
    final wanted =
        96 + (_searchable ? 72 : 0) + widget.choices.length * _rowExtent + 40;
    final height = math.min(
      wanted,
      (media.size.height - media.padding.top) * .78 - keyboard,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: math.max(height, 240),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EditorSheetHeader(
              title: widget.title,
              onClose: () => Navigator.pop(context),
            ),
            if (_searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: TextField(
                  style: AppTypography.input,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: AppTypography.input.copyWith(
                      color: AppColors.placeholder,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 8),
                      child: AppSvgIcon(
                        'assets/icons/history/ecde4.svg',
                        size: 20,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minHeight: 48),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    border: appInputBorder(AppColors.border),
                    enabledBorder: appInputBorder(AppColors.border),
                    focusedBorder: appInputBorder(AppColors.action),
                  ),
                ),
              ),
            Expanded(
              child: choices.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No matching options',
                        textAlign: TextAlign.center,
                        style: AppTypography.body,
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        media.padding.bottom + 24,
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: choices.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final choice = choices[index];
                        return _ChoiceRow(
                          label: widget.label(choice),
                          selected: choice == widget.selected,
                          onTap: () => Navigator.pop(context, choice),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? const BorderSide(color: AppColors.action)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF171918),
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: AppColors.action,
                  )
                else
                  const AppSvgIcon('assets/icons/rules/c1ae0.svg', size: 18),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
