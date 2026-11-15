import 'package:flutter/material.dart';

/// Compact Figma filter with accessible hit areas and horizontal overflow.
class AppFilterTabs<T> extends StatelessWidget {
  const AppFilterTabs({
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    super.key,
  });
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        border: Border.all(color: const Color(0xFFE4E4E4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in values)
            Semantics(
              selected: selected == value,
              button: true,
              child: Material(
                color: selected == value ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(value),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 48,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          label(value),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
