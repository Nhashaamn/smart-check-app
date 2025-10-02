import 'package:flutter/material.dart';

class TextFieldCustom extends StatelessWidget {
  final TextEditingController Controller;
  final bool obscureText;
  final FocusNode? focusNode;
  final Function(String)? onSubmitted;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final IconData? prefixIcon;

  const TextFieldCustom({
    super.key,
    required this.Controller,
    this.obscureText = false,
    this.focusNode,
    this.onSubmitted,
    this.hintText,
    this.hintStyle,
    this.textStyle,
    this.prefixIcon, 
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: Controller,
        obscureText: obscureText,
        focusNode: focusNode,
        style: textStyle ?? const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF419C9C).withOpacity(0.2), // Matches the background theme
          hintText: hintText,
          hintStyle: hintStyle ?? const TextStyle(color: Colors.white70),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: Colors.white70,
                  size: 20,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF419C9C).withOpacity(0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Color(0xFF419C9C),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textInputAction: TextInputAction.next,
        onSubmitted: onSubmitted,
      ),
    );
  }
}