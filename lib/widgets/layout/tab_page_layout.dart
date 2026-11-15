import 'package:flutter/material.dart';

/// A tab body; the navigation shell owns its Scaffold and system bars.
class TabPageLayout extends StatelessWidget {
  const TabPageLayout({required this.title, required this.child, super.key});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ColoredBox(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 17),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.2,
                color: Color(0xFF171918),
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: child,
          ),
        ),
      ),
    ],
  );
}
