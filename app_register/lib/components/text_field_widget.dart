import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TextFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscure;
  final bool multiline;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Color? fillColor;

  const TextFieldWidget({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscure = false,
    this.multiline = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.fillColor,
  });

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  late bool _obscured;
  late bool _hasError;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscure;
    _hasError = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.label!,
              style: theme.bodyMedium.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: widget.fillColor ?? theme.alternate,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasError ? theme.error : const Color(0xFFE1E1E1),
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: _obscured && widget.obscure,
            maxLines: widget.multiline ? 4 : 1,
            keyboardType: widget.keyboardType,
            validator: (v) {
              final err = widget.validator?.call(v);
              setState(() {
                _hasError = err != null;
                _errorText = err;
              });
              return err;
            },
            onChanged: (v) {
              setState(() => _hasError = false);
              widget.onChanged?.call(v);
            },
            style: theme.bodyMedium.copyWith(color: theme.primaryText),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: theme.bodyMedium.copyWith(color: theme.secondaryText),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: theme.secondaryText, size: 20)
                  : null,
              suffixIcon: widget.obscure
                  ? IconButton(
                      icon: Icon(
                        _obscured ? Icons.visibility_off : Icons.visibility,
                        color: theme.secondaryText,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    )
                  : widget.suffixIcon != null
                      ? Icon(widget.suffixIcon, color: theme.secondaryText, size: 20)
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              _errorText!,
              style: theme.bodySmall.copyWith(color: theme.error),
            ),
          ),
      ],
    );
  }
}
