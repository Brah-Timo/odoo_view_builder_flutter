// lib/presentation/widgets/common/custom_button.dart

import 'package:flutter/material.dart';
import '../../../config/theme.dart';

enum ButtonVariant { primary, secondary, danger, ghost }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonVariant variant;
  final bool loading;
  final bool fullWidth;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.loading = false,
    this.fullWidth = false,
  });

  Color get _bgColor => switch (variant) {
        ButtonVariant.primary => AppTheme.primaryColor,
        ButtonVariant.secondary => AppTheme.accentColor,
        ButtonVariant.danger => AppTheme.errorColor,
        ButtonVariant.ghost => Colors.transparent,
      };

  @override
  Widget build(BuildContext context) {
    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
        else if (icon != null)
          Icon(icon, size: 16, color: Colors.white),
        if (icon != null || loading) const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );

    if (fullWidth) {
      child = Center(child: child);
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _bgColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: child,
      ),
    );
  }
}
