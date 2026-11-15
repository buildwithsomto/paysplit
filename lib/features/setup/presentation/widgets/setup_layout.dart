import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_theme.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_back_button.dart';

/// The salary checklist's shared Scaffold. Each step supplies fields and action.
class SetupLayout extends StatelessWidget {
  const SetupLayout({
    required this.step,
    required this.title,
    required this.onBack,
    required this.child,
    required this.bottom,
    super.key,
  });
  final int step;
  final String title;
  final VoidCallback onBack;
  final Widget child;
  final Widget bottom;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: AppTheme.systemOverlay,
    child: Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppBackButton(onPressed: onBack),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Configure your Salary Partitions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 20,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: SizedBox(
                      width: 250,
                      child: Text(
                        'Set up your salary and destinations for automated distribution.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          height: 20 / 14,
                          color: AppColors.body,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 37),
                  _SetupProgress(step: step),
                  const SizedBox(height: 20),
                  SvgPicture.asset(
                    'assets/icons/setup/97f0b.svg',
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.75,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 32),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 18, 16, 36),
        child: bottom,
      ),
    ),
  );
}

class _SetupProgress extends StatefulWidget {
  const _SetupProgress({required this.step});
  final int step;
  @override
  State<_SetupProgress> createState() => _SetupProgressState();
}

class _SetupProgressState extends State<_SetupProgress> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final assets = [
      '91349.svg',
      widget.step >= 2 ? 'fe5d7.svg' : '0b7f8.svg',
      widget.step >= 3 ? '6c63c.svg' : '59366.svg',
      widget.step >= 4 ? 'b403d.svg' : '0d2a7.svg',
    ];
    return Semantics(
      button: true,
      label:
          'Setup step ${widget.step} of 4. ${_expanded ? 'Collapse' : 'Expand'} checklist',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBF6FE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: i < widget.step
                              ? const Color(0xFFD2EDFF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: i < widget.step
                              ? null
                              : Border.all(
                                  color: const Color(0xFFC8C8C8),
                                  width: .667,
                                ),
                        ),
                        child: AppSvgIcon(
                          'assets/icons/setup/${assets[i]}',
                          size: 16,
                        ),
                      ),
                      if (i < 3)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Container(
                            width: 20,
                            height: 2,
                            color: i < widget.step
                                ? const Color(0xFF248CD9)
                                : const Color(0xFFC7C7CC),
                          ),
                        ),
                    ],
                    const Spacer(),
                    RotatedBox(
                      quarterTurns: _expanded ? 1 : 3,
                      child: const SizedBox.square(
                        dimension: 32,
                        child: OverflowBox(
                          minWidth: 33,
                          maxWidth: 33,
                          minHeight: 33,
                          maxHeight: 33,
                          child: AppSvgIcon(
                            'assets/icons/setup/1ea1b.svg',
                            size: 33,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_expanded)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      '1. Salary income\n2. First wallet\n3. First beneficiary\n4. Split rule and review',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
