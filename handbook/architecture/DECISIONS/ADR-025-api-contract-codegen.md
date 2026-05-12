# ADR-025 — API Contract & Codegen (OpenAPI 3, Dart-authoritative, TS via openapi-typescript)

**Status:** Accepted
**Date:** 2026-05-12
**Deciders:** Phase 6+ Frontend Revival
**Supersedes:** None
**Related:** ADR-002 (BFF pattern), ADR-023 (Bearer forwarding), ADR-024 (Web App Stack), ADR-026 (Security Hardening)

---

## Contexto

ADR-024 introduz dois stacks de linguagem no contexto Aplicação:

- **BFF**: Dart 3.x (Shelf, `apps/social_care_bff/web/`)
- **Web App**: TypeScript 6 (Vite + React, `apps/conecta_web/`)

Sem contrato formal entre os dois, **drift é certeza**:

- Backend muda nome de campo `socialBenefits` → `social_benefits` em `AssessmentContract` e ninguém percebe que o Web ainda manda camelCase.
- Frontend manda `cpf` como `string`, BFF espera `{ raw: string, formatted: string }`.
- Backend adiciona campo obrigatório novo no DTO; Frontend continua omitindo até alguém abrir um ticket de bug em produção.

Esses bugs **não aparecem em testes unitários** (BFF testa BFF, Web testa Web). Aparecem em integração ou produção. Para um sistema com dados de saúde (LGPD), drift de contrato é também risco de exposição (campo errado pode vazar dado errado).

A regra inegociável **R2** do ADR-024 ("toda regra de negócio no BFF") só funciona se o contrato Web↔BFF for **formal e enforce-ável**. Acordo verbal não basta.

### Estado atual (2026-05-12)

- BFF tem contratos como **tipos Dart fortemente tipados** em `apps/social_care_bff/contracts/lib/` (interfaces abstratas: `AuthContract`, `RegistryContract`, `PeopleContract`, `AuditContract`, `AssessmentContract`, `CareContract`, `ProtectionContract`, `LookupContract`, `TeamContract`).
- **Não existe** OpenAPI spec, Swagger, gRPC proto ou GraphQL schema no monorepo (`grep` exaustivo confirmou em turno arquitetural).
- BFF não expõe `/openapi.json` nem `/swagger`.
- Adapters HTTP outbound (ex: `PeopleContextClient`) usam Dio sem validação de schema.

### Princípio aplicado

**Single Source of Truth (SSoT) deve ser a fonte com mais tipo nativo.** Os tipos Dart do BFF são:

- Já existentes.
- Validados estaticamente pelo compilador.
- Source of trust para o BFF (a regra mora aqui — R2).

Sintetizar um schema separado (OpenAPI mantido à mão, proto à mão) cria **dois** sources of truth com possibilidade de divergência. O caminho menos arriscado é **derivar** o schema das definições Dart, automaticamente.

Esse é o caminho ideal. O caminho **pragmático** é diferente — explicado abaixo na seção §Decisão.

---

## Decisão

### Estrutura em duas fases

**Fase 1 — `openapi.yaml` mantido à mão (Phase 6 inicial, ~20 endpoints).**
**Fase 2 — geração automática a partir de Dart contracts (Phase 7+, quando >30 endpoints).**

Justificativa do faseamento:

- Phase 6 tem ~10 contratos com ~3 métodos cada = ~30 operações. OpenAPI YAML para isso tem ~600 linhas. **Manter à mão é viável e tem custo de PR baixo** (linter de YAML + revisão).
- Investir em build_runner Dart→OpenAPI **antes** do contrato estabilizar é over-engineering. Os tipos Dart ainda estão mudando (Fakes em `server.dart`, refactor de Phase 6).
- Quando o contrato estabilizar (Phase 7+) e o YAML manual virar fricção, o investimento em geração se justifica.

### Fluxo Fase 1

```
                                     ┌──────────────────────────────────┐
                                     │ apps/social_care_bff/contracts/  │
                                     │   openapi/openapi.yaml           │
                                     │   ← MANTIDO À MÃO                │
                                     │   ← REVISADO em todo PR          │
                                     │     que mude contrato Dart       │
                                     └──────────────────────────────────┘
                                          │                          │
                                          │                          │
                                          ▼                          ▼
                          ┌────────────────────────┐  ┌────────────────────────┐
                          │ BFF Dart (Shelf)       │  │ Web App (TS 6)         │
                          │                        │  │                        │
                          │ Tipos Dart NATIVOS são │  │ codegen via            │
                          │ SoT no runtime.        │  │ openapi-typescript     │
                          │                        │  │   → src/api/generated/ │
                          │ Lint test em CI        │  │      types.ts          │
                          │ valida que             │  │                        │
                          │ openapi.yaml bate com  │  │ Hooks tipados via      │
                          │ contracts/lib/.        │  │ TanStack Query +       │
                          │                        │  │ tipos gerados.         │
                          └────────────────────────┘  └────────────────────────┘
                                          │
                                          │
                                          ▼
                          ┌────────────────────────┐
                          │ BFF expõe              │
                          │   GET /openapi.json    │
                          │ em dev/staging         │
                          │ (autenticado, role     │
                          │  admin) para Swagger   │
                          │  UI / testes manuais.  │
                          │                        │
                          │ DESABILITADO em prod   │
                          │ por default (R4).      │
                          └────────────────────────┘
```

### Regras concretas — Fase 1

1. **Localização do spec:** `apps/social_care_bff/contracts/openapi/openapi.yaml`. Versionado em git.
2. **Source of authority no runtime:** os tipos Dart de `apps/social_care_bff/contracts/lib/` permanecem source of truth para o **comportamento** do BFF. O YAML é a **representação compartilhada** do contrato — não substitui os tipos Dart.
3. **CI sync test (BLOCKING):** todo PR que tocar `apps/social_care_bff/contracts/lib/**/*.dart` OU `openapi/openapi.yaml` roda um teste que valida correspondência entre os dois. Mecânica detalhada em §Future enforcement.
4. **Codegen TS:** `bun run codegen:api` em `apps/conecta_web/` executa `openapi-typescript ../social_care_bff/contracts/openapi/openapi.yaml --output src/api/generated/types.ts`. Output é **gitignored** (regenerado em cada CI).
5. **Validação runtime Dart:** opcional na Fase 1, recomendada em Fase 2. Para Fase 1, BFF confia nos tipos Dart estáticos; validação extra de payload entra apenas em endpoints com input externo direto (ex: webhooks Zitadel).
6. **Exposição do spec:** `GET /openapi.json` no BFF retorna o YAML serializado como JSON, **apenas em dev/staging**, **autenticado**, **role `admin`**. Em produção, o endpoint retorna 404 (R4: app interno, mas sem expor surface adicional).
7. **Versionamento de contrato:** spec inclui `info.version` com a tag SemVer do monorepo. CI injeta automaticamente. Cliente Web inclui esse valor em header `X-Contract-Version` em cada request → BFF compara → log de mismatch (não bloqueio, mas observável).
8. **Breaking change policy:** mudança breaking (renomear campo, mudar tipo, remover endpoint) **sempre** abre PR conjunto Web+BFF. Lint CI proíbe merge se mudança em `openapi.yaml` for breaking e Web não foi atualizado no mesmo PR (detecção: diff semântico via `openapi-diff` CLI).

### Regras concretas — Fase 2 (futura, Phase 7+)

Quando o spec passar de ~50 operações ou quando a fricção de manter YAML à mão começar a aparecer em retros:

1. **Build_runner Dart** lê anotações em `*Contract` classes e gera `openapi.yaml` automaticamente. Spec deixa de ser commit-tracked, vira artefato gerado em CI.
2. **Anotações por método:** `@ApiOperation(path: '/api/patients', method: HttpMethod.post, ...)` ou similar.
3. **Validação runtime opcional via parser de schema** (e.g., `package:json_schema` + spec gerado).
4. Migração é **transparente para o Web** — `openapi.yaml` final continua sendo o mesmo formato.

Decisão de migrar para Fase 2 é registrada em ADR separado (provavelmente ADR-035–040 range).

### Por que não OpenAPI gerado a partir dos contracts Dart **agora**

| Razão | Detalhamento |
|---|---|
| Contratos ainda mudando | Phase 6 vai estabilizar tipos. Anotar contratos voláteis = retrabalho. |
| Ecossistema Dart→OpenAPI imaturo | Não há gerador canônico Dart→OpenAPI de qualidade alta em 2026-05 (validei via pub.dev). Custo de implementar build_runner próprio é ~1 sprint. Não compensa para 30 operações. |
| YAML à mão escala até ~50 ops | OpenAPI YAML é repetitivo mas não complexo. 600 linhas para 30 ops é gerenciável. |
| Time pode aprender o spec | Manter YAML à mão familiariza time com o formato. Quando migrar para gerado, sabe debugar. |

### Por que não gRPC / Connect-RPC

| Razão | Detalhamento |
|---|---|
| Server-side Dart | Shelf + gRPC server existe mas é caminho menos batido. Trocar a HTTP layer atual do BFF custaria muito. |
| Browser nativo | gRPC requer Connect-RPC ou gRPC-Web (proxy translation). Adiciona camada. |
| Pool de devs | Engenheiros React rotina é REST + OpenAPI; gRPC fica nicho. |
| Streaming | Não temos requisito atual de streaming bidirecional. Se aparecer, ADR específico. |

### Por que não GraphQL

| Razão | Detalhamento |
|---|---|
| BFF já é o agregador | GraphQL faz mais sentido quando você tem N microserviços e precisa de cliente componível. Aqui já temos o BFF como ponto único — GraphQL adiciona camada sem solver problema novo. |
| Cache normalizado | GraphQL tem custo de cache (Apollo, Relay). TanStack Query + REST tem fetch cache trivial. |
| Server-side Dart | `graphql_server2` existe mas tem ecossistema pequeno. |
| N+1 problem | GraphQL convida a queries arbitrárias do cliente, criando N+1 que precisam ser caçados com dataloaders. REST com endpoints específicos (BFF agrega exatamente o que cada tela precisa) evita. |

---

## Consequências

### Positivas

| Ganho | Como se materializa |
|---|---|
| **Drift de contrato detectado em CI, não em produção** | Sync test bloqueia merge se Dart e YAML divergem. |
| **Tipos TS zero-runtime** | `openapi-typescript` gera só `interface` e `type` — nada vai pro bundle. |
| **Hooks TanStack Query tipados** | `useQuery<paths['/api/patients']['get']['responses']['200']['content']['application/json']>(…)`. |
| **Versionamento de contrato observável** | Header `X-Contract-Version` revela mismatch em runtime sem quebrar UX. |
| **Refactor de campo no BFF propaga** | Renomear campo em Dart obriga atualizar YAML, regenera TS, força Web atualizar (ou CI quebra). |
| **Spec compartilhável** | YAML em git é artefato consumível por outros consumidores (e.g., futuro app mobile, integração externa, testes de contrato Pact). |
| **Migração para Fase 2 é transparente** | Mesmo formato YAML; só muda quem produz. |

### Negativas / Custos

| Custo | Como mitigamos |
|---|---|
| **YAML à mão é trabalho repetitivo** | Aceito na Fase 1. Migrar para Fase 2 quando ROI inverter. |
| **CI sync test exige diligência** | Test fail é didático: força PR a tocar os dois lados. Sem isso, drift acontece. |
| **`X-Contract-Version` adiciona ~30 bytes/request** | Trivial. |
| **`/openapi.json` em dev/staging adiciona surface** | Mitigação: autenticado + role admin + 404 em prod (R4). |
| **Time aprende YAML OpenAPI** | Investimento que paga em produtividade de cada PR de contrato. |
| **Codegen TS roda em todo build Web** | `openapi-typescript` é rápido (~200ms para 30 ops). Trivial. |

### Quebras se as regras forem violadas

| Violação | Consequência | Detecção |
|---|---|---|
| Adicionar endpoint no BFF sem atualizar YAML | Web não tem tipo. Hook TanStack Query usa `any`. Compilador TS permite (porque `any`). Bug em produção. | Sync test bloqueia merge. |
| Mudar tipo de campo em Dart sem atualizar YAML | Backend retorna shape novo, Web parseia shape antigo, render quebra. | Sync test bloqueia merge. |
| Web usar `as any` ou `// @ts-expect-error` em response da API | Burla o contrato no caller. | `eslint-plugin-no-restricted-syntax` proibindo `as any` em arquivos `src/api/`. |
| `/openapi.json` exposto em produção | Vazamento de surface (atacante mapeia endpoints). | Test E2E: `GET /openapi.json` em prod retorna 404. |
| Mudança breaking em YAML sem PR conjunto Web+BFF | Deploy quebra produção. | `openapi-diff` em CI: breaking change requer label `breaking-change-approved` + branch que toca Web. |

---

## Alternativas consideradas

### Alternativa 1 — OpenAPI gerado direto de Dart contracts (Fase 2 imediata)

**Adiada para Fase 2.** Investimento desproporcional ao benefício imediato. Phase 6 estabiliza contratos primeiro.

### Alternativa 2 — Contratos TS codegen direto de Dart (sem OpenAPI intermediário)

**Rejeitada.** Faria sentido se Web fosse o único consumidor para sempre. Mas:

- Futuro mobile (Phase 7+) pode querer tipos Swift ou Kotlin → OpenAPI tem geradores maduros para ambos.
- Integração externa (auditor, integração com outro sistema SUAS) consome OpenAPI nativamente.
- OpenAPI é formato neutro, sobrevive a troca de stack do Web.

### Alternativa 3 — gRPC + Connect-RPC

**Rejeitada.** Já argumentado em §Decisão.

### Alternativa 4 — GraphQL

**Rejeitada.** Já argumentado em §Decisão.

### Alternativa 5 — Sem contrato formal — Web confia no que BFF retorna

**Rejeitada categoricamente.** É exatamente o estado de drift que motivou este ADR.

### Alternativa 6 — Pact / contract testing em vez de schema

**Rejeitada como alternativa principal; mantida como complemento futuro.** Pact valida contrato via teste consumidor↔provedor, sem precisar de schema central. É bom como **detecção** mas ruim como **comunicação** — não dá ao engenheiro Web autocomplete em `useQuery`.

OpenAPI + Pact podem coexistir: OpenAPI dá tipos, Pact valida comportamento. Pact opcional em Phase 7+ se aparecer regressão de contrato não pegada pelo sync test.

---

## Future enforcement

### Sync test (FASE 1) — BLOCKING no CI

Mecânica simplificada: para cada `*Contract` em `apps/social_care_bff/contracts/lib/`, o teste extrai assinaturas de método via reflexão de código (parser AST do Dart) e compara contra os `paths` declarados em `openapi.yaml`. Discrepância → fail.

```dart
// apps/social_care_bff/contracts/test/architecture/openapi_sync_test.dart (FUTURE)
//
// Garante que TODA classe abstrata *Contract em lib/ tem uma path operation
// declarada em ../openapi/openapi.yaml com a mesma assinatura.
//
// Falhas comuns que este teste pega:
//  - Novo método em contrato sem rota correspondente.
//  - Renomear campo em parâmetro/retorno sem propagar.
//  - Remover endpoint do YAML sem deletar método do contrato.

import 'dart:io';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:analyzer/dart/analysis/utilities.dart';

void main() {
  test('every Contract method has matching openapi path (ADR-025)', () {
    final yamlText = File('openapi/openapi.yaml').readAsStringSync();
    final yaml = loadYaml(yamlText) as YamlMap;
    final declaredPaths = (yaml['paths'] as YamlMap).keys.toSet();

    final contractDir = Directory('lib');
    final contractFiles = contractDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_contract.dart'));

    final expectedPaths = <String>{};
    for (final f in contractFiles) {
      final parsed = parseString(content: f.readAsStringSync());
      // (AST walk extracts @ApiOperation(...) annotations or convention-based mapping)
      // ...
    }

    expect(expectedPaths.difference(declaredPaths), isEmpty,
        reason: 'Contract methods sem rota em openapi.yaml');
    expect(declaredPaths.difference(expectedPaths), isEmpty,
        reason: 'Rotas em openapi.yaml sem método correspondente');
  });
}
```

**Quando aplicar:** no primeiro PR que adicione `openapi.yaml` ao monorepo. Antes disso, o teste seria sempre verde.

### `openapi-diff` breaking change detection — BLOCKING em mudança breaking

```yaml
# .github/workflows/openapi-diff.yml (FUTURE)
on:
  pull_request:
    paths:
      - 'apps/social_care_bff/contracts/openapi/openapi.yaml'
jobs:
  diff:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Detect breaking changes
        run: |
          npx @apidevtools/openapi-diff \
            origin/main:apps/social_care_bff/contracts/openapi/openapi.yaml \
            apps/social_care_bff/contracts/openapi/openapi.yaml \
            --fail-on-incompatible
      - name: Require Web update on breaking change
        if: failure()
        run: |
          if ! git diff --name-only origin/main...HEAD | grep -q '^apps/conecta_web/'; then
            echo "Breaking change em openapi.yaml SEM mudanças em apps/conecta_web/"
            echo "Adicione label 'breaking-change-approved' ou inclua o Web no PR"
            exit 1
          fi
```

### Codegen TS — em cada CI Web build

```bash
# apps/conecta_web/package.json (scripts)
{
  "scripts": {
    "codegen:api": "openapi-typescript ../social_care_bff/contracts/openapi/openapi.yaml --output src/api/generated/types.ts",
    "build": "bun run codegen:api && vite build",
    "dev": "bun run codegen:api && vite",
    "typecheck": "tsc --noEmit"
  }
}
```

`src/api/generated/types.ts` é **gitignored**. Regenerado em todo dev/build/CI. Se YAML mudar, types mudam, TS compiler quebra arquivos que ainda usam shape antigo. **Drift detectado em segundos.**

---

## Open questions

1. **Generator Dart→OpenAPI para Fase 2:** build_runner próprio (custo: ~1 sprint, controle total) ou pacote `swagger_dart_code_generator` (custo: ~3 dias, menos controle, suporte limitado a algumas convenções). Decisão para ADR Fase 2.
2. **Validação runtime no BFF:** vale a pena validar payloads de entrada contra schema (com `json_schema` ou similar) ou confiar nos tipos Dart estáticos? Inclinação: validar apenas em endpoints com input não-confiável (webhooks Zitadel). Decidir caso a caso.
3. **Versão do contrato em URL (`/v1/...`) ou só em header `X-Contract-Version`?** Header é menos invasivo, mas convenção REST favorece URL. Decisão deferida para PR do primeiro endpoint.
4. **Pact / contract testing complementar:** se aparecer regressão de contrato não pegada pelo sync test, adicionar Pact. Não decidir antes.
5. **i18n no contrato:** mensagens de erro retornadas pelo BFF — em PT-BR fixo, ou códigos + Web traduz? Inclinação: códigos + Web traduz (PT-BR único hoje, mas mantém flexibilidade). Decisão deferida.

---

## Riscos não cobertos por este ADR

- **Contratos para WebSockets/SSE.** OpenAPI 3.1 suporta parcialmente; se aparecer requisito, AsyncAPI 3.0 pode complementar. Fora de escopo.
- **Contratos para uploads multipart de arquivo grande.** OpenAPI suporta `multipart/form-data`, mas o codegen TS varia em qualidade. Cobertura: dia em que primeiro upload de arquivo aterrissar.
- **Backward compatibility de clientes mobile futuros.** Se Phase 7+ trouxer app Swift consumindo o mesmo contrato, breaking change policy precisa cobrir todos os clientes — não só Web. ADR específico quando o caso surgir.
- **Performance de codegen com >200 ops.** `openapi-typescript` é rápido até alguns milhares de ops; abaixo desse limite, irrelevante.

---

## LGPD mapping

| Artigo | Controle | Aderência via ADR-025 |
|---|---|---|
| Art. 37 (registro de operações) | Contrato formal permite auditar quais dados pessoais cada endpoint manipula | **Atendido**: spec OpenAPI é input para inventário de tratamento de dados pessoais (RIPD/DPIA). |
| Art. 46 (medidas técnicas) | Sync test em CI evita exposição acidental de campo sensível por drift | **Atendido**: campo `cpf` adicionado em DTO sem revisão de PR é impossível (sync test pega). |
| Art. 47 (compartilhamento controlado) | `/openapi.json` autenticado + role admin + 404 em prod | **Atendido**: surface do contrato não vaza para anônimos. |

---

## Referências

- **ADRs relacionados**: ADR-002, ADR-023, ADR-024, ADR-026
- **OpenAPI 3.1.0 spec**: https://spec.openapis.org/oas/v3.1.0
- **openapi-typescript** (TS codegen): https://openapi-ts.dev/
- **openapi-diff** (breaking change): https://github.com/oasdiff/oasdiff
- **AsyncAPI** (para WebSockets/SSE futuro): https://www.asyncapi.com/
- **Pact** (contract testing complementar): https://pact.io/
- **Robert C. Martin, Clean Architecture** — Common Closure Principle e Stable Dependencies Principle aplicam-se a contratos compartilhados.
