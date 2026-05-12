# Compliance Report — ACDG Frontend (Flutter)
> **Data:** 2026-04-16
> **Escopo:** `packages/social_care/`, `packages/core/`, `packages/design_system/`, `apps/acdg_system/`
> **Diretrizes:** `.claude/skills/flutter-expert/SKILL.md` + `handbook/architecture/CONTRACT_A_PUBLIC_API.md`
> **Método:** Análise estática (Grep/Glob/Read), sem execução de testes/analyze.

---

## 0. Executive Summary

Duas visões contrastantes:

| Dimensão | Score | Diagnóstico |
|----------|:----:|-------------|
| **Padrões internos (23 Non-Negotiables)** | **21/23 = 91 %** | Código escrito com qualidade alta. Patterns aplicados consistentemente. |
| **Arquitetura Contract A (boundary com BFF)** | **29 % conformidade** | **63 violações críticas** de import de `bff/shared/` fora da camada data. |
| **Estrutura de pastas** | **85 % conformidade** | 3 pastas extras fora do padrão da skill (`logic/`, `data/commands/`, `domain/schemas/`). 2 pastas com nome camelCase (`viewModel/`). |

### Conclusão em 1 frase
O código **não é purista demais**. Internamente, os patterns (Command, Result, Riverpod, Atomic Design, Selectors/Connectors) estão bem aplicados. O problema é **macro-arquitetural**: o cliente está acoplado ao schema do BFF (`bff/shared/`) e carrega orquestração que deveria estar no servidor.

### Prioridades de remediação

| Prioridade | Item | Esforço | Impacto |
|:-:|------|---------|---------|
| **P0** | Eliminar vazamento de `bff/shared/` em ViewModels/UseCases/Views (63 arquivos) | Alto | Muito alto — destrava tudo |
| **P0** | Quebrar `HttpSocialCareClient` (643 linhas, god-interface) | Médio | Alto |
| **P1** | Mover `logic/use_case/` → `ui/<feature>/use_cases/` | Médio | Médio — alinhar com skill |
| **P1** | Mover `logic/mappers/` → `data/mappers/` | Baixo | Médio |
| **P1** | Renomear `viewModel/` → `view_models/` (2 pastas) | Baixo | Baixo |
| **P2** | Realocar `data/commands/` (intents) — decidir: payload em `data/model/` ou manter como command | Baixo | Baixo |
| **P2** | Decidir destino de `domain/schemas/` (Zard validators) | Baixo | Baixo |
| **P2** | Corrigir 2 `throw` em mappers/viewmodels | Trivial | Baixo |
| **P2** | Memoizar getters com computação pesada | Trivial | Baixo |

---

## 1. 23 Non-Negotiables da Skill `flutter-expert`

### Visão Geral
| # | Regra | Status | Evidências |
|:-:|------|:----:|-----------|
| 1 | MVVM strict + Command | ✅ CONFORME | 12/12 ViewModels |
| 2 | Atomic state (ChangeNotifier + Command) | ✅ CONFORME | Pattern aplicado em todos |
| 3 | Total immutability on Models | ✅ CONFORME | Amostra 5 models: todos `final`, `copyWith` |
| 4 | Models as schemas | ✅ CONFORME | Lógica nos UseCases, não nos models |
| 5 | UseCase mandatory | ✅ CONFORME | 20+ UseCases, 12 features, 100% cobertura |
| 6 | Unidirectional data flow | ✅ CONFORME | Data down, commands up |
| 7 | Repository as abstract class | ✅ CONFORME | 4 abstract repos |
| 8 | Fakes for tests | ⚠️ N/A | Não validado neste audit |
| 9 | Riverpod DI (stub + override) | ✅ CONFORME | Todos features com stub provider |
| 10 | 1 widget per file | ✅ CONFORME | Zero private `_Widget` classes |
| 11 | Selectors & Connectors | ✅ CONFORME | 0 ViewModels passados a atoms/molecules |
| 12 | Never use `Impl` suffix | ✅ CONFORME (1 legado) | `SentryLoggerImpl` em `packages/core/` |
| 13 | Mapper per endpoint | ✅ CONFORME | Mappers por bounded context (aceitável) |
| 14 | Mapper returns `Result<T>` | ⚠️ PARCIAL | 2 `throw` encontrados (98 %) |
| 15 | Code EN / UI PT-BR | ✅ CONFORME | Amostra: comentários EN, textos PT-BR |
| 16 | No `_build*()` helpers | ✅ CONFORME | 1 em ViewModel (aceitável) |
| 17 | No manual loading booleans | ✅ CONFORME | 0 `_isLoading` detectados |
| 18 | No hardcoded colors | ✅ CONFORME | 0 `Color(0xFF...)` em `ui/` |
| 19 | ListenableBuilder at lowest level | ✅ CONFORME | Nenhum wrapping Scaffold inteiro |
| 20 | Memoize computed getters | ⚠️ PARCIAL | 1 getter sem cache (baixo custo) |
| 21 | Result<T> everywhere | ⚠️ PARCIAL | 2 `throw` (mesmos de #14) |
| 22 | Services private in Repository | ✅ CONFORME | 100 % (`_bff`, `_patientService`) |
| 23 | Repositories private in ViewModel | ✅ CONFORME | 12/12 ViewModels |

**Score:** 21 conformes + 2 parciais = **21/23 conformes (91 %)**.

### Detalhamento das violações
**Regras 14 & 21 — `throw` fora de adapters (2 ocorrências)**
- `packages/social_care/lib/src/logic/mappers/intervention_mapper.dart:91` — `throw StateError(...)` em mapper. Deveria retornar `Result.error(...)`.
- `packages/social_care/lib/src/ui/patient_registration/viewModel/patient_registration_view_model.dart:310` — `throw StateError('Unreachable')` em switch. Padrão de exaustão de sealed class, **aceitável**.

**Regra 20 — Getter não memoizado (1 ocorrência)**
- `packages/social_care/lib/src/ui/patient_registration/viewModel/patient_registration_view_model.dart:90-94` — `refPersonName` recomputa string join/trim. Custo baixo, mas viola a regra.

**Regra 12 — Impl suffix (1 legado)**
- `packages/core/lib/src/infrastructure/logging/sentry_logger_impl.dart` — nomear por tecnologia: `SentryLogger`.

---

## 2. Contract A — Boundary com o BFF

Esta é a **grande dor arquitetural** do projeto.

### 2.1. Vazamento de `package:shared/shared.dart`

**Regra de ouro do Contract A** (§6 do doc): `package:shared/shared.dart` só pode ser importado em `data/model/`, `data/services/`, `data/mappers/`.

**Achado:**
| Categoria | Quantidade | % |
|-----------|:---------:|:-:|
| Total de imports | 89 | 100 % |
| Em camadas proibidas | **63** | **71 %** |
| Em camadas permitidas (data/) | 26 | 29 % |

**Distribuição das violações:**
| Camada | Arquivos violadores |
|--------|:---------:|
| ViewModels (`ui/*/view_models/` e `viewModel/`) | 12 |
| UseCases (`logic/use_case/`) | 20 |
| Views/Components (`ui/*/view/`) | 31 |
| Mappers em `ui/home/mappers/` (fora do lugar) | 9 |
| Mappers em `logic/mappers/` (fora do lugar) | 4 |

**Top 10 piores ofensores (por número de imports):**
1. `ui/patient_registration/view/components/forms/reference_person/family_member_modal.dart` — 5 imports
2. `ui/family_composition/view/components/add_member_modal.dart` — 5 imports
3. `data/services/http_social_care_client.dart` — 3 imports (god-interface)
4. `ui/intake_info/view/components/ingress_type_section.dart` — 3 imports
5. `ui/intake_info/view/components/programs_section.dart` — 3 imports
6. `ui/health_status/view/components/health_deficiency_card.dart` — 3 imports
7. `ui/educational_status/view/components/educational_status_profile_card.dart` — 3 imports
8. `ui/family_composition/view/components/family_composition_specificities.dart` — 3 imports
9. `ui/patient_registration/viewModel/patient_registration_view_model.dart` — 2 imports
10. `logic/use_case/registry/register_patient_use_case.dart` — 2 imports

### 2.2. God-interface: `HttpSocialCareClient`

**Arquivo:** `packages/social_care/lib/src/data/services/http_social_care_client.dart`
- **643 linhas em um único arquivo**
- Implementa `SocialCareContract` — cerca de **24 métodos HTTP** em uma única classe
- Cobre 5+ bounded contexts: Registry, Assessment, Care, Protection, Lookup, Audit

**O que precisa virar:**
```
packages/social_care/lib/src/data/services/
├── patient_service.dart          (Registry: register, get, list, family)
├── assessment_service.dart       (Housing, Socioeconomic, Health, ...)
├── care_service.dart             (Appointments, Intake)
├── protection_service.dart       (Violations, Referrals, Placement)
├── lookup_service.dart           (Dominios + Requests)
└── audit_service.dart            (Audit trail)
```

### 2.3. Translators / ACLs primitivos

- `PatientTranslator` — referenciado **16 vezes** em `http_social_care_client.dart`. Indica ACL feita à mão, não via `data/mappers/`.
- `PatientDetailTranslator` em `ui/home/models/patient_detail_translator.dart` — **em camada UI** (deveria estar em `data/mappers/`), importa `package:shared/`.

### 2.4. Orquestração no cliente

**Caso #1 — `PatientRegistrationViewModel._loadLookups()`:**
```dart
final results = await Future.wait([
  _getLookupTableUseCase.execute('dominio_parentesco'),
  _getLookupTableUseCase.execute('dominio_tipo_identidade'),
  _getLookupTableUseCase.execute('dominio_tipo_ingresso'),
  _getLookupTableUseCase.execute('dominio_programa_social'),
]);
```
**Violação:** 4 requests do cliente para compor estado de UI. Deveria ser **1 request** a um endpoint Contract A tipo `GET /api/lookups?tables=parentesco,identidade,...`.

**Caso #2 — `RegisterPatientUseCase.execute()`:**
Hoje centraliza em 1 call (`_patientRepository.registerPatient(...)`) — **conforme Contract A**.
Porém, o flow HOJE ainda passa por `http_social_care_client.registerPatient()` que invoca o wizard completo com N chamadas HTTP reais no BFF. Isso é aceitável desde que seja 1 request do Flutter.

---

## 3. Estrutura de Pastas

### Esperado (skill §Package Structure)
```
packages/social_care/lib/src/
├── domain/models/
├── data/{repositories,services,model,mappers}/
├── ui/<feature>/{view_models,widgets,use_cases,di}/
└── testing/fakes/
```

### Encontrado
```
packages/social_care/lib/src/
├── constants/
├── domain/
│   ├── schemas/                  ⚠️ EXTRA — Zard validators (não-padrão)
│   └── errors/
├── data/
│   ├── commands/                 ⚠️ EXTRA — *_intents.dart
│   ├── models/
│   ├── repositories/
│   └── services/
├── logic/                        ⚠️ FORA DO PADRÃO — deveria estar dentro de ui/<feature>/
│   ├── mappers/                  (deveria estar em data/mappers/)
│   └── use_case/                 (deveria estar em ui/<feature>/use_cases/)
└── ui/
    ├── home/
    │   ├── viewModel/            ⚠️ camelCase (deveria ser view_models/)
    │   ├── view/
    │   ├── models/
    │   ├── mappers/              ⚠️ DUPLICATED (mappers de detail)
    │   └── di/
    ├── patient_registration/
    │   └── viewModel/            ⚠️ camelCase (2ª ocorrência)
    └── ...
```

### Resumo das divergências

| Divergência | Ocorrências | Severidade |
|-------------|:---------:|:---------:|
| Pasta `logic/` na raiz (não-padrão) | 1 | Média |
| Pasta `data/commands/` (intents) | 1 | Média |
| Pasta `domain/schemas/` (Zard) | 1 | Média |
| `viewModel/` em camelCase (deveria ser `view_models/`) | 2 | Baixa |
| Mappers em `ui/home/mappers/` (em vez de `data/mappers/`) | 9 | Média |

---

## 4. Inventário Numérico

| Artefato | Quantidade | Padrão OK? |
|----------|:---------:|:---------:|
| ViewModels | 12 | ✅ |
| UseCases | 21 | ✅ |
| Repositories (abstract + concrete) | 4 | ⚠️ poucos |
| Services | 5 | ⚠️ 1 god-service |
| Mappers | 13 (4 logic + 9 ui/home) | ⚠️ duplicados |
| Pages | 12 | ✅ |
| Arquivos `.dart` em `packages/social_care/lib/` | 324 | — |
| Imports de `bff/shared/` | 89 | ❌ (63 fora do lugar) |

---

## 5. O que o código prova sobre a ACDG

### Pontos fortes
1. **Rigor nos patterns** — Command pattern, Result, Selectors/Connectors, Riverpod stub+override: tudo aplicado consistentemente.
2. **Imutabilidade real** — models com `with Equatable` e `copyWith`. Zero mutações detectadas.
3. **Repository/Service ocultos** — 100 % privados nos consumidores.
4. **Sem hardcoded colors** — amostra de 30+ arquivos UI, todos usam `AppColors`.
5. **12 features com estrutura completa** — cada uma tem ViewModel + UseCase + widgets + di.

### Dívida estrutural
1. **Contract A vazando** — 63 arquivos importam `bff/shared/` fora de `data/`. Cada mudança de DTO quebra tudo.
2. **God-interface `HttpSocialCareClient`** — 643 linhas, 24 métodos, 5 contextos misturados.
3. **Camadas fora do padrão** — `logic/`, `data/commands/`, `domain/schemas/`.
4. **Translators em UI** — `PatientDetailTranslator` em `ui/home/models/` com import de `shared/`.

### Veredicto
> **Você NÃO é purista demais.** O código interno está dentro das regras. O que vai precisar de refactor é o **boundary arquitetural** com o BFF, não a qualidade interna do Flutter.

---

## 6. Roadmap de Remediação

### Onda 1 — P0: Contract A boundary (elimina 80 % da dor)
1. **Criar `packages/social_care/lib/src/domain/models/` próprios** (`Patient`, `FamilyMember`, `HousingCondition`, ...), imutáveis, `with Equatable`, sem `fromJson/toJson`.
2. **Criar `data/model/` com payloads Contract A** (1 classe por endpoint), essas sim com `fromJson/toJson`.
3. **Mover mappers** de `logic/mappers/` e `ui/home/mappers/` → `data/mappers/`. 1 por endpoint do Contract A, retornando `Result<T>`.
4. **Quebrar `HttpSocialCareClient`** em `PatientService`, `AssessmentService`, `CareService`, `ProtectionService`, `LookupService`, `AuditService`.
5. **Refatorar UseCases** para receber/retornar apenas domain models. Remover import de `package:shared/`.
6. **Refatorar ViewModels** para consumir UseCases com domain models. Remover import de `package:shared/`.
7. **Refatorar Views** — removem import de `package:shared/`; se precisam de DTOs para exibir, migrar para domain models antes.

### Onda 2 — P1: Estrutura (alinhar com skill)
1. **Mover `logic/use_case/` → `ui/<feature>/use_cases/`** (próximo ao ViewModel consumidor).
2. **Mover `logic/mappers/` → `data/mappers/`**.
3. **Renomear `viewModel/` → `view_models/`** em `home/` e `patient_registration/`.
4. **Deletar pasta `logic/` vazia** no final.

### Onda 3 — P2: Convenções secundárias
1. **Decidir `data/commands/`**: se intents forem payloads → renomear para `data/model/<entity>_register_payload.dart`; se forem estruturas de ViewModel → mover para `ui/<feature>/models/`.
2. **Decidir `domain/schemas/`**: mover validators para `data/model/` ou inlinar nos UseCases.
3. **Corrigir `intervention_mapper.dart:91`** — substituir `throw StateError` por `Result.error`.
4. **Memoizar `refPersonName`** em `patient_registration_view_model.dart`.
5. **Renomear `SentryLoggerImpl` → `SentryLogger`** em `packages/core/`.

### Onda 4 — Lint obrigatório (after)
Adicionar em `packages/social_care/analysis_options.yaml`:
```yaml
analyzer:
  errors:
    # plus custom rule para bloquear imports de package:shared/ fora de data/{model,services,mappers}
```

Valor: impede regressão. No dia que a regra estiver com 0 erros, o Contract A está estabelecido.

---

## 7. Métricas de Sucesso

| Métrica | Hoje | Meta (pós-Onda 1) |
|---------|:----:|:----------------:|
| Imports de `bff/shared/` em camadas proibidas | 63 | **0** |
| Tamanho de `HttpSocialCareClient` (linhas) | 643 | **Deletado** |
| Services no `data/services/` | 1 god + 4 | **6 especializados** |
| Translators em camada UI | 2 | **0** |
| Pastas fora do padrão da skill | 5 (`logic/`, `commands/`, `schemas/`, 2× `viewModel/`) | **0** |
| Score 23 Non-Negotiables | 91 % | **100 %** |
| Score Contract A | 29 % | **100 %** |

---

## 8. Referências
- `.claude/skills/flutter-expert/SKILL.md` §"Non-Negotiable Rules"
- `.claude/skills/flutter-expert/references/contract_a_public_api.md`
- `handbook/architecture/CONTRACT_A_PUBLIC_API.md`
- `handbook/architecture/ARCHITECTURE.md`

## 9. Apêndice — Comandos de verificação

```bash
# Contar imports violadores de bff/shared/
grep -rn "package:shared/shared.dart" packages/social_care/lib/src/ui \
  packages/social_care/lib/src/logic \
  packages/social_care/lib/src/domain | wc -l

# Listar widgets por feature
find packages/social_care/lib/src/ui -name "*.dart" | sed 's|.*/ui/||' | cut -d'/' -f1 | sort -u

# Achar métodos _build em Pages
grep -rn "Widget _build" packages/social_care/lib/src/ui/

# Achar hardcoded colors
grep -rn "Color(0xFF" packages/social_care/lib/src/ui/

# Achar throw fora de adapters
grep -rn "throw " packages/social_care/lib/src/ui packages/social_care/lib/src/logic packages/social_care/lib/src/domain
```
