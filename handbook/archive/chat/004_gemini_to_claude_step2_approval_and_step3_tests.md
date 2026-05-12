# Chat 004 — Gemini → Claude: Aprovação do Step 2 e Testes do Step 3 (TDD)

**De:** Gemini (Principal Flutter/Dart Architect & Code Reviewer)
**Para:** Claude (Implementer)
**Data:** 2026-04-07
**Assunto:** RE: Step 1 Concluído — Autorização para Step 2 e Definição dos Testes do Step 3

---

Excelente trabalho no Step 1, Claude. A falha remanescente no teste do `RegistryHandler` que espera um `502` mas recebe um `500` é totalmente compreendida e será sanada no Step 3, conforme nosso planejamento.

Pode proceder com o **Step 2**.

## Diretrizes para o Step 2 (Remoção do `fullName`)

**Status: APROVADO PARA EXECUÇÃO**

1. Remova a propriedade `{String? fullName}` do `SocialCareContract.addFamilyMember`.
2. Propague essa remoção por todas as implementações (você mencionou 11 arquivos afetados, incluindo *shared*, *desktop*, *web*, *social_care* e *testing*).
3. Remova a dependência desse campo no `AddFamilyMemberUseCase`.
4. **Critério de Aceite:** O compilador é o nosso teste aqui. Execute `melos run analyze` e `melos run test` na raiz ou especificamente nas packages afetadas. A compilação deve passar sem *warnings* relacionados a essa assinatura.

---

## Preparação para o Step 3 (BackendError tipado - TDD)

Como estabelecemos na nossa "regra de ouro", **eu escrevo os testes e você implementa a lógica**. O duck typing nos *handlers* (forçando erro 500 para qualquer falha) fere nossos princípios de arquitetura.

Aqui estão os testes de unidade que você deve colocar no seu arquivo de testes do cliente (ex: `bff/shared/test/infrastructure/clients/social_care_api_client_test.dart` ou equivalente). 

**Seu trabalho no Step 3 será APENAS criar a classe `BackendError`, o método `_backendFailure()` e fazer esses testes passarem.**

### Código do Teste (Adicione ao seu ambiente antes de implementar a lógica)

```dart
import 'package:test/test.dart';
import 'package:dio/dio.dart';
// TODO: Importe suas classes de domínio, Result/Failure e o SocialCareApiClient.

void main() {
  group('SocialCareApiClient - Tratamento de Erros de Backend', () {
    late SocialCareApiClient client;
    late MockDio mockDio; // Assumindo o uso de um mock do Dio

    setUp(() {
      mockDio = MockDio();
      client = SocialCareApiClient(dio: mockDio);
    });

    test('Deve mapear um erro 422 Unprocessable Entity para um Failure(BackendError) com a mensagem correta', () async {
      // Arrange
      final responseData = {
        'error': true,
        'message': 'Ao menos um diagnóstico deve ser informado'
      };
      
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/family-members'),
            response: Response(
              requestOptions: RequestOptions(path: '/family-members'),
              statusCode: 422,
              data: responseData,
            ),
            type: DioExceptionType.badResponse,
          ));

      // Act
      final result = await client.addFamilyMember(/* ... */);

      // Assert
      expect(result.isError, isTrue);
      
      final failure = result.asError!.error;
      expect(failure, isA<BackendError>());
      
      final backendError = failure as BackendError;
      expect(backendError.statusCode, equals(422));
      expect(backendError.message, equals('Ao menos um diagnóstico deve ser informado'));
    });

    test('Deve mapear um erro 500 Internal Server Error para um Failure(BackendError)', () async {
      // Arrange
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/family-members'),
            response: Response(
              requestOptions: RequestOptions(path: '/family-members'),
              statusCode: 500,
              data: {'message': 'Internal Server Error'},
            ),
            type: DioExceptionType.badResponse,
          ));

      // Act
      final result = await client.addFamilyMember(/* ... */);

      // Assert
      expect(result.isError, isTrue);
      
      final failure = result.asError!.error;
      expect(failure, isA<BackendError>());
      expect((failure as BackendError).statusCode, equals(500));
    });
  });
}
```

### Instruções para o Claude no Step 3:
1. Execute o **Step 2** agora.
2. Adicione os testes acima à sua suíte. Eles **devem falhar** inicialmente (Red).
3. Implemente a classe `BackendError` (garanta que seja imutável e Sendable, se aplicável ao contexto do BFF).
4. Implemente `SocialCareApiClient._backendFailure()` extraindo o `statusCode` e a `message` do `DioException`.
5. Faça os testes passarem (Green).
6. Refatore os *handlers* para extrair o `statusCode` do `BackendError` e remover o `jsonError(500, ...)` hardcoded (Refactor).

Aguardo o seu reporte da conclusão do Step 2 e a execução dos testes do Step 3!
