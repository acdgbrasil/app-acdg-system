import 'dart:ui';
import 'package:flutter/material.dart';

enum RegistrationErrorType { network, server }

class RegistrationErrorModal extends StatelessWidget {
  final RegistrationErrorType type;
  final String? errorCode;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const RegistrationErrorModal({
    super.key,
    this.type = RegistrationErrorType.server,
    this.errorCode,
    required this.onRetry,
    required this.onClose,
  });

  static const _brown = Color(0xFF261D11);
  static const _brown50 = Color(0x80261D11);
  static const _brown20 = Color(0x33261D11);
  static const _brown10 = Color(0x1A261D11);
  static const _bg = Color(0xFFF2E2C4);
  static const _bgWhite = Color(0xFFFFFBF4);
  static const _green = Color(0xFF4F8448);
  static const _red = Color(0xFFA6290D);
  static const _redBg2 = Color(0x1FA6290D);

  bool get _isNetwork => type == RegistrationErrorType.network;

  String get _title => _isNetwork ? 'Sem conexão' : 'Erro no servidor';

  String get _description => _isNetwork
      ? 'Verifique sua internet e tente novamente. Seus dados não foram perdidos.'
      : 'Algo deu errado ao salvar o cadastro. Seus dados estão seguros, tente novamente.';

  String get _defaultCode =>
      _isNetwork ? 'ERR_NETWORK_TIMEOUT' : 'HTTP 500 — Internal Server Error';

  static Future<void> show(
    BuildContext context, {
    RegistrationErrorType type = RegistrationErrorType.server,
    String? errorCode,
    required VoidCallback onRetry,
    required VoidCallback onClose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x73261D11),
      builder: (_) => RegistrationErrorModal(
        type: type,
        errorCode: errorCode,
        onRetry: onRetry,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.fromLTRB(36, 40, 36, 32),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D261D11),
                  blurRadius: 64,
                  offset: Offset(0, 24),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _redBg2,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _isNetwork ? Icons.wifi_off_rounded : Icons.warning_rounded,
                    size: 36,
                    color: _red,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  _title,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: _brown,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  _description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: _brown50,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),

                // Error code
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _brown10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    errorCode ?? _defaultCode,
                    style: const TextStyle(
                      fontFamily: 'Consolas',
                      fontSize: 12,
                      color: _brown50,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Fechar
                    OutlinedButton(
                      onPressed: onClose,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        side: const BorderSide(color: _brown20, width: 1.5),
                      ),
                      child: const Text(
                        'Fechar',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                          color: _brown,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Tentar novamente
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: _bgWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text(
                        'Tentar novamente',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
