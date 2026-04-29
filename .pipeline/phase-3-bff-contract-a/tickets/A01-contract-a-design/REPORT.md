# A01 REPORT — Contract A Design

## Status: COMPLETED

## Summary
Pesquisa arquitetural completa sobre todas as ações que o APP (Flutter Web + Desktop) precisa que o BFF entregue. Produzido o documento `handbook/architecture/CONTRACT_A_SPEC.md` com tabelas detalhadas, sub-contract mapping e notas específicas para os próximos 20 tickets.

## Métricas
- **Total de ações mapeadas:** 35 (user-facing) / 49 (endpoints totais incluindo health + ações admin)
- **Endpoints compostos identificados:** 5 (1 novo: batch lookups; 4 já existentes via scatter-gather)
- **Endpoints a remover:** 6 (todos da família `/people/*` ou `/team/people/*`)
- **Backend requests (Swift):** 4 (2 prováveis já existem, 2 são melhorias futuras — nenhum bloqueador)
- **Sub-contracts (Contract B):** 9 (Auth, Registry, Assessment, Care, Protection, Lookup, Team, Audit, Analytics)
- **Features Flutter inventariadas:** 15 (13 em `social_care` + 2 em `people_admin`)

## Arquivos produzidos
- `/Users/gabriel_aderaldo/Desktop/dev/envolve/acdg/frontend/handbook/architecture/CONTRACT_A_SPEC.md` (~500 linhas)

## Descobertas principais
1. **Contract A está ~98% implementado** — a maioria dos endpoints já existe nos handlers do `bff/social_care_web/`. Falta principalmente estruturação (A02–A06), endpoint batch de lookups (A14), e remoção de rotas que vazam topologia (A15).
2. **Phase 2 já começou os 4 Intents corretos** (`register_patient_intent`, `add_family_member_intent`, `register_worker_intent`, `auth_callback_intent`). Faltam ~25 outros Intents equivalentes para cobrir todas as ações.
3. **Scatter-gather já existe** em `POST /api/patients` (registra pessoas + paciente + família + intake + social-identity) e `GET /api/patients/{id}` (enriquecido). Vai ser reforçado em A08.
4. **Batch lookups é a única composição verdadeiramente nova** — hoje o Flutter faz 4 `Future.wait` no `PatientRegistrationViewModel` que serão substituídos por 1 request.

## Notes for next agents (A02..A21)

### Decisões consolidadas neste ticket
- **Sub-contracts finais:** 9 (ver Seção E do SPEC).
- **`PeopleContract` NÃO é sub-contract público** — é cliente interno (`PeopleContextClient`) consumido por UseCases.
- **Pattern de Intents:** 1 Intent por ação do Contract A (em vez de 1 Intent genérico com discriminator). Consistência > DRY aqui.
- **Saga compensation em POST /api/patients:** decisão adiada para A08.

### Regra para A02 (DTOs request)
~25 payloads a criar. Nome padrão: `<action>_payload.dart` (ex: `patient_register_payload.dart`, `update_housing_payload.dart`). Campos `final`, `fromJson`/`toJson`, `@JsonSerializable` se consistente com Phase 1.

### Regra para A03 (DTOs response)
A maioria já existe em `bff/shared/lib/src/model/`. **Reorganizar** para `dto/response/` sem perder nada. Adicionar `LookupsBatchResponse` (novo).

### Regra para A04 (sub-contracts)
9 arquivos em `bff/shared/lib/src/contracts/`. Interfaces puras (abstract). Cada método usa payloads de A02 e responses de A03.

### Regra para A05
Deletar `bff/shared/lib/src/contract/social_care_contract.dart`. Vai quebrar Desktop + Web — ok (A07+ e A16+ consertam).

### Regra para A06
9 fakes com state próprio (Map/List in-memory). Deletar `FakeSocialCareBff` monolítico.

### Regras para A07–A15 (handlers)
- 1 ticket = 1 bounded context
- Cada endpoint = 1 Intent + 1 UseCase
- Handler consome sub-contract de A04
- **Zero** import de `SocialCareContract` (já deletado)
- TDD: test-writer primeiro (Wave 0), implementer depois (Wave 1)

### Regras para A16–A18 (Desktop)
Desktop passa de `implements SocialCareContract` para `implements RegistryContract, AssessmentContract, ...` (múltiplas interfaces). Mesma API pública, topologia interna reorganizada.

### Regra para A19 (gate)
`dart analyze bff/` zero errors em src/. **Testes ignorados** (deprecados desde decisão do usuário).

### Regra para A20 (doc final)
Atualizar `CONTRACT_A_PUBLIC_API.md` com o estado REAL implementado + trade-offs vivenciados.

### Regra para A21 (cleanup)
Deletar: `HttpSocialCareClient` (643L), `PatientTranslator`, `FakeSocialCareBff`, pasta `http/` que criamos como insumo-temporário. **Após A21, Flutter não compila** — normal; Fase 4 (`phase-4-flutter-migration`) conserta.

## Blockers / Ambiguidades
Nenhum bloqueador crítico. Duas sugestões documentadas no SPEC (Seção "Blockers / Questões abertas"):
1. Analytics integration (#8 patient detail enriched) — pode ficar como ticket futuro
2. Saga compensation em POST /api/patients — decisão em A08

## Next action
Executar A02 e A03 em paralelo (DTOs request/response — independentes entre si). A04 depende dos dois.
