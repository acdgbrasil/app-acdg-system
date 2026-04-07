import 'package:flutter_test/flutter_test.dart';
import 'package:core/src/infrastructure/logging/log_level.dart';
import 'package:core/src/infrastructure/logging/sentry_logger_impl.dart';
import '../../testing/fakes/fake_sentry_client.dart';

void main() {
  group('SentryLoggerImpl - Regras de Despacho (DIP & Fakes Manuais)', () {
    late FakeSentryClient fakeSentryClient;
    late SentryLoggerImpl logger;

    setUp(() {
      fakeSentryClient = FakeSentryClient();
      logger = SentryLoggerImpl(sentryClient: fakeSentryClient);
    });

    test('NÃO deve enviar para o Sentry quando o LogLevel for INFO', () {
      logger.log('Usuário acessou a tela', LogLevel.info);

      expect(fakeSentryClient.capturedMessages, isEmpty);
      expect(fakeSentryClient.capturedExceptions, isEmpty);
    });

    test('NÃO deve enviar para o Sentry quando o LogLevel for WARNING', () {
      logger.log('Conexão instável', LogLevel.warning);

      expect(fakeSentryClient.capturedMessages, isEmpty);
      expect(fakeSentryClient.capturedExceptions, isEmpty);
    });

    test(
      'DEVE enviar captureException para o Sentry quando o LogLevel for ERROR com exception atrelada',
      () {
        final exception = Exception('Falha grave na API');
        final stackTrace = StackTrace.current;

        logger.log(
          'Falha na requisição',
          LogLevel.error,
          error: exception,
          stackTrace: stackTrace,
        );

        expect(fakeSentryClient.capturedExceptions, hasLength(1));
        expect(fakeSentryClient.capturedExceptions.first, equals(exception));
        expect(fakeSentryClient.capturedMessages, isEmpty);
      },
    );

    test(
      'DEVE enviar captureMessage para o Sentry quando o LogLevel for FATAL sem exception explícita',
      () {
        logger.log('Estado da ViewModel inconsistente', LogLevel.fatal);

        expect(fakeSentryClient.capturedMessages, hasLength(1));
        expect(
          fakeSentryClient.capturedMessages.first,
          equals('Estado da ViewModel inconsistente'),
        );
      },
    );
  });
}
