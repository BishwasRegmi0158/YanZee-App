import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';

class PillTextFormField extends FormField<String> {
  PillTextFormField({
    super.key,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    super.validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) : super(
          initialValue: controller.text,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          builder: (state) {
            var decoration = authPillInputDecoration(
              hint: hint,
              icon: icon,
              suffixIcon: suffixIcon,
            );
            if (state.hasError) {
              decoration = decoration.copyWith(
                enabledBorder: decoration.errorBorder,
                focusedBorder: decoration.errorBorder,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: authPillShadow,
                  ),
                  child: TextField(
                    controller: controller,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    inputFormatters: inputFormatters,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AuthColors.pillText,
                    ),
                    onChanged: state.didChange,
                    decoration: decoration,
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 6, right: 12),
                    child: Text(
                      state.errorText ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AuthColors.errorText,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}