# Camada de Dados (Data Layer): Pacote Social Care

A camada `data/` é responsável pela comunicação externa, definição de contratos de ação e conversão de informações brutas em modelos tipados.

## 1. Commands (Intents)
Localizados em `lib/src/data/commands/`.
- **Definição:** São objetos de transferência de dados (DTOs internos) imutáveis (`final class ... with Equatable`) que capturam a intenção do usuário no momento de uma ação.
- **Diferença para Models:** Enquanto um Model de Domínio possui regras de negócio ricas e validação na sua criação, o `Intent` é um "snapshot" de dados brutos (strings, inteiros, data/hora) vindos da UI.
- **Exemplo:** `RegisterPatientIntent` possui strings, listas simples e booleans vindos diretamente dos campos do formulário (ex: `firstName`, `rgNumber`, `isHomeless`).

## 2. Models (API DTOs)
- **Definição:** Classes cujo único propósito é a serialização/deserialização JSON do e para o backend (BFF).
- **Regras:**
  - Nenhuma lógica de negócio ou computação complexa permitida.
  - Implementam obrigatoriamente métodos `fromJson`.
  - São usados apenas internamente pela camada Data ou Repositórios; a UI (fora algumas exceções de visualização como `PatientDetail`) nunca deve interagir diretamente com eles.
- **Exemplo:** `PatientSummaryApiModel`, `FamilyMemberDetail`.

## 3. Repositories
Localizados em `lib/src/data/repositories/`.
- **Contratos (Abstract classes):** Definem a interface do repositório devolvendo sempre `Future<Result<T>>`. (ex: `PatientRepository`, `LookupRepository`).
- **Implementações (BFF):** Classes como `BffPatientRepository` encapsulam o cliente HTTP (`SocialCareContract` ou `PatientService`).
- **Responsabilidade do Repositório:** Chamar o serviço HTTP e traduzir os DTOs brutos de resposta para Entidades de Domínio ou Modelos de UI amigáveis (usando classes auxiliares como `PatientDetailTranslator`).

## 4. Services (HTTP Client)
Localizados em `lib/src/data/services/`.
- **`HttpSocialCareClient`:** É a implementação em Dio do BFF para web.
- **Tratamento de Autenticação:** Diferente de clientes puramente mobile que injetam `Authorization` header, este serviço confia no envio automático de cookies `HttpOnly` `SameSite=Strict` da mesma origem e o BFF extrai o `X-Actor-Id` da sessão.
- **Tratamento Global de Erros (`_failureFromResponse` e `_failureFromException`):**
  - Todas as exceções do Dio (timeouts, erros de rede) são capturadas e transformadas em `NetworkError` da família `SocialCareError`.
  - Os códigos de erro padrão da API (ex: `REGP-001`, `PAT-409`) vindo do JSON do BFF são lidos através de expressões regulares ou propriedades e explicitamente mapeados para erros de domínio selados (ex: `DuplicatePatientError`, `PrMemberRequiredError`).
  - O código do backend desconhecido é propagado dentro de um `ServerError` com a mensagem textual para a UI.

## Resumo para IAs
- **Sempre crie um Intent para agrupar dados do View para o UseCase.**
- **Sempre capture `catch` no Service (Dio) e converta para `Failure<SocialCareError>`. Nunca lance exceções nativas para o Repository.**
- **Repository traduz DTO para Domínio. Service traduz HTTP para DTO/Error.**