// lib/presentation/widgets/common/custom_textfield.dart

import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool required;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool readOnly;
  final int? maxLines;
  final Widget? suffix;

  const LabeledTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.required = false,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.readOnly = false,
    this.maxLines = 1,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTheme.fieldLabel),
              if (required)
                const Text(' *',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffix,
            ),
            validator: validator,
            onChanged: onChanged,
            keyboardType: keyboardType,
            readOnly: readOnly,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
