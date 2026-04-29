# A06 — Fakes per Sub-Contract

## Onda: 2 | Profile: bff/shared/testing | Depende de: A05 ✅

## Escopo
Substituir o `FakeSocialCareBff` monolítico (~400 linhas, implementava a god-interface já deletada) por **11 fakes especializados** — 1 por sub-contract.

## Fakes a criar em `bff/shared/lib/src/testing/`

| # | Fake | Implementa | Uso principal |
|---|------|-----------|---------------|
| 1 | `FakeAnalyticsBff` | AnalyticsContract | testes handler analytics (A08) |
| 2 | `FakeAssessmentBff` | AssessmentContract | testes handler assessment (A10) |
| 3 | `FakeAuditBff` | AuditContract | testes handler audit (A09) |
| 4 | `FakeAuthBff` | AuthContract | testes handler auth (A07) |
| 5 | `FakeCareBff` | CareContract | testes handler care (A11) |
| 6 | `FakeHealthBff` | HealthContract | infra testes |
| 7 | `FakeLookupBff` | LookupContract | testes handler lookup (A13, A14) |
| 8 | `FakePeopleBff` | PeopleContract | testes handler registry + team |
| 9 | `FakeProtectionBff` | ProtectionContract | testes handler protection (A12) |
| 10 | `FakeRegistryBff` | RegistryContract | testes handler registry (A08, A09) |
| 11 | `FakeTeamBff` | TeamContract | testes handler team (A15) |

## Princípios
- **State in-memory** — cada fake guarda em `Map`/`List` privados
- **Sem lógica de negócio** — só CRUD básico para simular resposta do backend
- **Retornar `Result<T>`** — `Ok(valor)` em sucesso, `Error` em cenários configuráveis
- **Sem dependências externas** — puro in-memory
- **Nome: `Fake<BoundedContext>Bff`** — sem sufixo `Impl`
- **Construtores:** default sem args para uso simples

## TDD

### Wave 0 — test-writer
Para cada um dos 11 fakes, criar 1 arquivo de teste "smoke" em `bff/shared/test/testing/fakes/` com 2-3 testes mínimos:
- **Test 1**: fake implementa o contract (só compile-check — cria instância, declara tipo como o contract)
- **Test 2**: operação CRUD básica (ex: create + retrieve — verifica que state é preservado)
- **Test 3** (opcional): cenário de erro configurável

**Testes devem falhar no início** — as classes não existem.

### Wave 1 — implementer
- Implementa os 11 fakes seguindo os testes
- Deleta `fake_social_care_bff.dart`
- Atualiza `shared.dart` (remove export do monolítico, adiciona 11 novos)
- `dart analyze bff/shared/lib` zero errors
- Todos os 11 testes smoke GREEN

## Critérios de aceitação
- [ ] 11 arquivos de fake em `bff/shared/lib/src/testing/`
- [ ] 11 arquivos de teste smoke em `bff/shared/test/testing/fakes/`
- [ ] `fake_social_care_bff.dart` **deletado**
- [ ] `shared.dart` atualizado (1 export removido, 11 adicionados)
- [ ] `dart analyze bff/shared/lib` zero errors
- [ ] `dart test bff/shared/test/testing/fakes/` todos verdes

## Não faça
- Não crie fakes com lógica complexa (saga, compensação, etc.) — são test doubles
- Não mexa em `contract/` (tickets anteriores trataram)
- Não tente consertar BFF Web/Desktop (A07-A18)

## Status
ready to dispatch Wave 0
