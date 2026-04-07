# Missão: Arquitetura, People-Context e Observabilidade (Sentry)

> **Contexto:** Esta missão foi iniciada pelo Gemini (Architect/Code Reviewer). Seguindo as regras do projeto, o Gemini criou o design, estruturou os testes em TDD (Test-Driven Development) e agora o Claude (Implementer) deve assumir para finalizar o código de produção que fará os testes passarem.

**Leia com atenção as 3 frentes de trabalho abaixo.**

---

## 1. Correção das Violações de Arquitetura (Gold Standard ACDG)
O teste `packages/social_care/test/architecture/architectural_guard_test.dart` e `widget_isolation_test.dart` estão falhando porque há métodos privados `_buildLeftColumn`, `_buildRightColumn`, etc., quebrando a regra de Componentes Atômicos (UI Pura e Otimização de `const`).

**Onde atuar:**
- `packages/social_care/lib/src/ui/patient_registration/view/components/forms/reference_person/family_member_modal.dart`
- `packages/social_care/lib/src/ui/family_composition/view/components/add_member_modal.dart`

**O que fazer:**
- Extraia os métodos `_build(...)` para `StatelessWidget` reais e independentes no final do arquivo ou em sub-pastas (ex: `_LeftColumn extends StatelessWidget`). Passe os parâmetros e callbacks (`onChanged`, `formState`) corretamente.

---

## 2. Integração do `people-context` no BFF (Orquestração Correta)
A UI não deve mais exibir `personId` (ex: `a3f2c1d8...`), e sim o Nome e Idade. O contrato não deve possuir `fullName` em `addFamilyMember`. O trabalho duro fica no BFF.

Os testes de TDD **já foram escritos e estão falhando** em: `bff/social_care_web/test/handlers/registry_handler_test.dart`.

**Onde atuar:**
- `bff/shared/lib/src/contract/social_care_contract.dart`: Remova `{String? fullName}` da interface de `addFamilyMember`. O domínio não conhece o nome avulso para esse fim.
- `bff/social_care_web/lib/src/remote/people_context_client.dart`: Adicione o método `Future<Result<Map<String, dynamic>>> getPerson(String personId)` para bater na rota `GET /api/v1/people/:personId`.
- `bff/social_care_web/lib/src/handlers/registry_handler.dart`:
  1. No `_fetchPatients` e `_fetchPatient`: Após pegar os dados do Backend em Swift, consulte o `peopleContext.getPerson(personId)` e **injetar/enrich** o JSON da resposta com `fullName` e `birthDate` tanto para o paciente principal quanto para os `familyMembers`.
  2. No `_addFamilyMember`: Remova o envio do `fullName` para o Backend Swift. Orquestre tudo pegando o nome do body, gerando no `people-context` e mandando só o `prRelationshipId` e `member` limpo pro Swift.
- `bff/shared/lib/src/infrastructure/dtos/patient_remote.dart`: Não esqueça de mapear (ou tratar no JSON) os campos enriquecidos (ex: no App, os DTOs vão precisar ler o `fullName`).

---

## 3. TDD para Observabilidade (Sentry + Crashlytics)
Precisamos ter observabilidade decente usando **Sentry** (muito superior ao Crashlytics nativo no quesito Full-Stack/BFF + Flutter, APM de Dio e Tracing distribuído).

Um teste de TDD foi criado em `packages/core/test/utils/acdg_logger_test.dart`.

**O que fazer:**
1. Instale no pacote `core` e no root `apps/acdg_system`: `sentry_flutter`.
2. Se usar requisições web no App, instale `sentry_dio` na camada de `network`.
3. Abra `packages/core/lib/src/utils/acdg_logger.dart` e altere a função `initialize()`:
   - Se `kDebugMode`: mantenha o log no `dart:developer`.
   - Se **produção** (`!kDebugMode`): Não faça print! Em vez disso:
     - Erros graves (`Level.SEVERE`, `Level.SHOUT`): Chame `Sentry.captureException(record.error, stackTrace: record.stackTrace)`.
     - Outros logs: Adicione ao rastro com `Sentry.addBreadcrumb(...)`.
4. Garanta que o teste passe e a solução não vase abstrações do Sentry desnecessariamente para os ViewModels e UseCases (que só conhecem `AcdgLogger.get('Módulo')`).

---

**Sucesso, Claude!** Todos os testes devem rodar verde após a sua implementação:
```bash
# Rodar todos os testes de social_care (inclui testes de Arquitetura da UI)
cd packages/social_care && flutter test

# Rodar todos os testes do BFF web (inclui People Context Enrichment)
cd bff/social_care_web && dart test

# Rodar testes do core (AcdgLogger Sentry)
cd packages/core && flutter test
```
