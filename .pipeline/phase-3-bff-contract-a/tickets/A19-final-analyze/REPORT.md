# A19 — Final dart analyze REPORT

## Status: GREEN (zero errors em src/ dos 3 BFFs)

Closed: 2026-05-01

## Resultado por módulo

| Módulo | Errors | Warnings | Infos |
|--------|:------:|:--------:|:-----:|
| `bff/shared/lib/` | 0 | 0 | 2 |
| `bff/social_care_web/lib/` | 0 | 0 | 0 |
| `bff/social_care_desktop/lib/` | 0 | 0 | 0 |

## Pré-requisitos resolvidos antes do gate

A19 originalmente estava bloqueado por 2 errors de tipo (`SocialCareContract` não existe — deletada em A05) em arquivos legados não exportados:

1. **Deletado:** `bff/social_care_web/lib/src/remote/social_care_api_client.dart`
   - 917 LoC implementando god-interface `SocialCareContract`
   - Não estava exportado em `social_care_web.dart` (comentário em linha 23 confirmava status legacy)
   - Causa do error `implements_non_class` + 52 warnings `override_on_non_overriding_member` + 6 infos `use_null_aware_elements`
   - Diretório `lib/src/remote/` removido (vazio)

2. **Deletado:** `bff/social_care_web/test/remote/social_care_api_client_test.dart`
   - Test correspondente ao arquivo acima (parte das "2 falhas pré-existentes A21" mencionadas no STATE)
   - Diretório `test/remote/` removido (vazio)

3. **Refatorado:** `bff/social_care_web/lib/src/handlers/health_handler.dart`
   - Antes: `typedef HealthContractFactory = SocialCareContract Function(Session)` → `Undefined class 'SocialCareContract'`
   - Depois: `typedef HealthContractFactory = HealthContract Function(Session)` (sub-contract canônico criado em A04, exportado de `package:shared/shared.dart:141`)

4. **Refatorado:** `bff/social_care_web/test/handlers/health_handler_test.dart`
   - `_FailingContract extends FakeSocialCareBff` → `implements HealthContract` (composição em vez de herança da god-fake deletada)
   - `late FakeSocialCareBff fakeBff` → `late FakeHealthBff fakeBff` (fake canônico em `bff/shared/lib/src/testing/fake_health_bff.dart`)

## Test suites pós-cleanup

| Módulo | Tests | Status |
|--------|:-----:|:------:|
| `bff/shared/` | 549 | GREEN |
| `bff/social_care_web/` | 1075 | GREEN |
| `bff/social_care_desktop/` | 426 | GREEN (+1 skip pré-existente) |
| **Total** | **2050** | **GREEN** |

Ganho líquido: as 2 falhas pré-existentes mencionadas no STATE (A21 backlog) foram resolvidas neste ticket via cleanup acima — não restam falhas.

## Infos restantes (não bloqueantes)

`bff/shared/lib/src/domain/kernel/rg_document.dart:162,166` — `use_null_aware_elements`:
- Sugestão de migrar `if (x != null) x` para `?x` em spread/collection. Cosmético, não-bloqueante.
- Candidato a sweep futuro de modernização (não dentro do escopo de A19).

## Item descartado: "Marcar test/ como deprecated"

O ticket original (escrito em 2026-04-17) listava como sub-tarefa:

> Marcar pastas `test/` de todos os 3 módulos como deprecated (arquivo `DEPRECATED.md` em cada)

**Não executado por mismatch com a realidade:** essa diretriz foi escrita quando os "testes BFF pré-existentes" (93 errors herdados) eram tidos como descartáveis. Mas durante A07-A18 toda a suite foi reescrita TDD-first e os 2050 testes atuais são canônicos e load-bearing — incluindo `health_handler_test.dart` que acabou de ser refatorado neste ticket. Marcar como deprecated criaria débito silencioso (REGRA #2 — anti-pattern análogo a "skip sem justificativa").

Os únicos 2 testes legados restantes (`health_handler_test.dart` legado + `social_care_api_client_test.dart`) foram tratados acima — refatorado e deletado, respectivamente.

## Comandos de verificação

```bash
dart analyze bff/shared/lib/         # 2 issues found (infos)
dart analyze bff/social_care_web/lib/      # No issues found!
dart analyze bff/social_care_desktop/lib/  # No issues found!

cd bff/shared && flutter test            # 549 GREEN
cd bff/social_care_web && flutter test   # 1075 GREEN
cd bff/social_care_desktop && flutter test  # 426 GREEN +1 skip
```

## Próximo

A20 — atualizar `handbook/architecture/CONTRACT_A_PUBLIC_API.md` e `CONTRACT_A_SPEC.md` com estado final.
