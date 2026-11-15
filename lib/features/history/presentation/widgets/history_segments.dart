import 'package:flutter/material.dart';

class HistorySegments<T> extends StatelessWidget {
  const HistorySegments({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onSelected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: const Color(0x45E4E4E4),
      border: Border.all(color: const Color(0xFFE4E4E4)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in options.entries)
          Semantics(
            container: true,
            button: true,
            selected: entry.key == selected,
            child: InkWell(
              onTap: () => onSelected(entry.key),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: entry.key == selected
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
