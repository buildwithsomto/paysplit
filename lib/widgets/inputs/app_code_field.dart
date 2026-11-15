import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';

/// One accessible text field supports paste, SMS autofill and backspace.
class AppCodeField extends StatefulWidget {
  const AppCodeField({
    required this.controller,
    this.error,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });
  final TextEditingController controller;
  final String? error;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppCodeField> createState() => _AppCodeFieldState();
}

class _AppCodeFieldState extends State<AppCodeField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 338),
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.controller, _focus]),
          builder: (context, child) {
            final code = widget.controller.text;
            final scale =
                MediaQuery.textScalerOf(context).scale(19.307) / 19.307;
            return Stack(
              children: [
                ExcludeSemantics(
                  child: Row(
                    spacing: 10,
                    children: List.generate(
                      6,
                      (index) => Expanded(
                        child: Container(
                          height: 48.268 * scale.clamp(1, 2),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.error != null
                                  ? AppColors.error
                                  : _focus.hasFocus && index == code.length
                                  ? AppColors.action
                                  : const Color(0xFFDDE3E8),
                              width: .804,
                            ),
                          ),
                          child: Text(
                            index < code.length ? code[index] : '',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 19.307,
                              height: 1,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Semantics(
                    label: 'Six-digit verification code',
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: const TextStyle(color: Colors.transparent),
                      cursorColor: Colors.transparent,
                      showCursor: false,
                      enableInteractiveSelection: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      if (widget.error case final error?) ...[
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            error,
            style: AppTypography.body.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ],
  );
}
