import 'package:flutter/material.dart';

/// A label and its value on one line, used in rule and split summaries.
class RuleReviewRow extends StatelessWidget {
  const RuleReviewRow({required this.label, required this.value, super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        // The label keeps its own width, up to most of the row, so a short
        // one such as "Balance before split" is not broken over two lines.
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * .6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF696969)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF171918),
            ),
          ),
        ),
      ],
    ),
  );
}
