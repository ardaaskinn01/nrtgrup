import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/formatters.dart';

class AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool allowZero;
  final String? Function(String?)? validator;

  const AmountField({
    super.key,
    required this.controller,
    this.label = 'Tutar (TL)',
    this.hint = '0,00',
    this.allowZero = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: '₺ ',
        prefixStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Lütfen tutar girin';
            }
            final parsed = AppFormatters.parseAmount(value);
            if (parsed == null) {
              return 'Geçerli bir tutar girin';
            }
            if (!allowZero && parsed <= 0) {
              return 'Tutar 0\'dan büyük olmalıdır';
            }
            if (parsed < 0) {
              return 'Tutar negatif olamaz';
            }
            return null;
          },
    );
  }
}
