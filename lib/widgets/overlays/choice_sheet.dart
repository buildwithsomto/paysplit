import 'package:flutter/material.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';

Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> choices,
  required String Function(T) label,
  T? selected,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.white,
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
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final choices = widget.choices
        .where(
          (value) =>
              widget.label(value).toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .55,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.title, style: AppTypography.heading),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (widget.choices.length > 5) ...[
                SliverToBoxAdapter(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],
              if (choices.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No matching options',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: choices.length,
                  itemBuilder: (context, index) {
                    final choice = choices[index];
                    return ListTile(
                      title: Text(widget.label(choice)),
                      selected: choice == widget.selected,
                      trailing: choice == widget.selected
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => Navigator.pop(context, choice),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
