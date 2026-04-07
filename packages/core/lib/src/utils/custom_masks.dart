import 'package:flutter/services.dart';

/// Classe base selada para máscaras customizadas.
///
/// Usamos [sealed] para garantir que todas as variações de máscaras
/// sejam conhecidas em tempo de compilação.
sealed class CustomMasks extends TextInputFormatter {
  final String mask;

  CustomMasks({required this.mask});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Remove tudo que não for dígito por padrão (limpeza)
    final cleanText = newValue.text.replaceAll(RegExp(r'\D'), '');
    final StringBuffer formatted = StringBuffer();

    int textIndex = 0;
    int maskIndex = 0;

    // Percorre a máscara e reconstrói a string
    while (maskIndex < mask.length && textIndex < cleanText.length) {
      if (mask[maskIndex] == '#') {
        formatted.write(cleanText[textIndex]);
        textIndex++;
      } else {
        formatted.write(mask[maskIndex]);
      }
      maskIndex++;
    }

    return TextEditingValue(
      text: formatted.toString(),
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Máscara específica para Telefone (Brasil).
///
/// Lógica inteligente: alterna entre (##) ####-#### e (##) #####-####
/// dependendo da quantidade de números digitados.
final class PhoneMask extends CustomMasks {
  PhoneMask() : super(mask: '(##) #####-####');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final cleanText = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Escolhe a máscara correta baseada no tamanho (fixo ou celular)
    final String effectiveMask = cleanText.length <= 10
        ? '(##) ####-####'
        : '(##) #####-####';

    final StringBuffer formatted = StringBuffer();
    int textIndex = 0;
    int maskIndex = 0;

    while (maskIndex < effectiveMask.length && textIndex < cleanText.length) {
      if (effectiveMask[maskIndex] == '#') {
        formatted.write(cleanText[textIndex]);
        textIndex++;
      } else {
        formatted.write(effectiveMask[maskIndex]);
      }
      maskIndex++;
    }

    return TextEditingValue(
      text: formatted.toString(),
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
