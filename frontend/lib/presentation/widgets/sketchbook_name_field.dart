import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Sketchbook-style title input: Fraunces 600 at 24, no border by default,
/// a sand underline on hover and a terracotta underline on focus. Shared by
/// the place and trip forms so both name fields speak the same language.
class SketchbookNameField extends StatefulWidget {
  const SketchbookNameField({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  State<SketchbookNameField> createState() => _SketchbookNameFieldState();
}

class _SketchbookNameFieldState extends State<SketchbookNameField> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        style: const TextStyle(
          fontFamily: 'Fraunces',
          fontWeight: FontWeight.w600,
          fontSize: 24,
          color: AppColors.text,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: AppColors.muted,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: _hovered ? AppColors.muted : Colors.transparent,
              width: 1,
            ),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
