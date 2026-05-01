# Discuss Context: phase-3-flutter-acl

## Mode: questions (resolvido 2026-04-16 — usuário autorizou execução com defaults recomendados)

## Resolução das Questões
- **Q1 — data/commands/**: (C) dividir caso a caso. Decisão adiada para T18; não afeta T01.
- **Q2 — domain/schemas/**: (A) validators migram para `data/model/` em T18.
- **Q3 — logic/use_case/**: (A) mover para `ui/<feature>/use_cases/` conforme cada ticket de feature consumir.
- **Q4 — HttpSocialCareClient split**: interfaces enxutas por service, retornam payloads, mapper no Repository.
- **Q5 — Delete HttpSocialCareClient**: em T19 junto com lint.
- **Q6 — Testes mínimos/ticket**: ViewModel (unit) + Repository (unit) + 1 widget test de Page.
- **Q7 — Ordem**: serializar T04–T06; paralelizar T07–T14 após T06 estável.
- **Q8 — Nomes**: domain sem sufixo (`Patient`, `FamilyMember`); payloads com sufixo (`PatientRegisterPayload`, `PatientDetailResponse`).

## Decisões já tomadas
- **Breaking changes permitidos** (usuário confirmou)
- **Piloto: Housing** (ficha simples, baixo risco)
- **Estratégia: Strangler Fig** (feature por feature, legado convive com novo)
- **Ordem oficial da skill:** Model → Service → Repository → UseCase → ViewModel → View
- **Referência canonical:** `handbook/architecture/CONTRACT_A_PUBLIC_API.md`

## Open Items — requerem decisão antes de T01

### Q1. O que fazer com `packages/social_care/lib/src/data/commands/`?
Hoje tem: `register_patient_intent.dart`, `family_intents.dart`, `assessment_intents.dart`, `intervention_intents.dart`, `registry_intents.dart`.

**Alternativas:**
- **A)** Renomear para `data/model/*_payload.dart` (se são DTOs de entrada do BFF — Contract A)
- **B)** Mover para `ui/<feature>/models/` (se são estruturas internas de ViewModel)
- **C)** Dividir: parte vira payload, parte vira model de UI

**Recomendação:** (C) — examinar uso caso a caso.

### Q2. O que fazer com `packages/social_care/lib/src/domain/schemas/`?
Hoje tem: `social_care_schemas.dart` com validação via Zard (CPF, nomes, family member).

**Alternativas:**
- **A)** Mover validators para `data/model/` próximo aos payloads
- **B)** Inlinar validação em UseCases como métodos privados
- **C)** Criar pasta própria `domain/validators/` (skill não menciona, mas faz sentido)

**Recomendação:** (A) — validators viram parte dos `*_payload.dart`, que já nascem validáveis.

### Q3. `logic/use_case/` — mover TODOS para `ui/<feature>/use_cases/`?
Skill §Package Structure espera UseCases dentro da feature. Hoje estão centralizados em `logic/use_case/`.

**Alternativas:**
- **A)** Mover todos (alinha com skill; pode gerar imports cross-feature se UseCases forem reutilizados)
- **B)** Manter centralizados (mais pragmático se vários features compartilham o mesmo UseCase)
- **C)** Híbrido: UseCases 1-feature em `ui/<feature>/use_cases/`; UseCases compartilhados em `data/use_cases/shared/`

**Recomendação:** (A) — alinhar com skill. Se reutilização aparecer, re-avaliar para (C).

### Q4. `HttpSocialCareClient` — estratégia de split (T03)
Quebrar em 6 services: `PatientService`, `AssessmentService`, `CareService`, `ProtectionService`, `LookupService`, `AuditService`.

**Decisão técnica:**
- **Todos usam o mesmo `Dio` base?** (sugestão: SIM; injetado via provider comum)
- **Mantêm `implements SocialCareContract`?** (sugestão: NÃO — cada um tem sua interface enxuta; god-interface é parte do problema)
- **Retornam `Result<T>` com domain models OU com payloads?** (sugestão: payloads; conversão para domain acontece no Repository via Mapper)

**Recomendação:** interfaces por service (ex: `PatientServiceContract`), retornam payloads, Repository chama mapper.

### Q5. Deletar `HttpSocialCareClient` — quando?
Hoje é usado pelo Flutter Web via `HttpSocialCareClient implements SocialCareContract`. O Desktop tem `SocialCareBffRemote` (que permanece).

**Estratégia:**
- Fase 1–2 (T01–T15): convive com os novos services
- Fase 3 (T16–T17): fluxos compostos migram
- Fase 4 (T19): ativar lint → se passar, T19 **também deleta** `HttpSocialCareClient`

**Pergunta:** deletar em T19 ou em ticket separado T20?

**Recomendação:** T19 inclui delete (atômico: lint verde → legado deletado).

### Q6. Testes — escopo mínimo por ticket
A skill exige `flutter-test-writer` em toda pipeline. Para tickets P0 críticos:

- Tests mínimos por ticket: ViewModel (unit) + Repository (unit) + 1 widget test de Page.
- Tests pesados (wizard, family modal) em tickets específicos.
- **Concorda?**

### Q7. Ordem de execução
Respeitar dependências declaradas no STATE.md:
```
T01 → T02 + T03 (parallel) → T04 (pilot) → T05..T15 (parallel ok após T04) → T16 → T17 → T18 → T19
```

**Pergunta:** paralelizar T05..T15? É possível tecnicamente mas consome muita review humana. Recomendação: **serializar** inicialmente; paralelizar quando o template estiver estável (após T06).

### Q8. Nome do domain model do Flutter vs BFF
Conflito potencial: `bff/shared/Patient` vs `packages/social_care/.../domain/models/Patient`.

**Alternativas:**
- **A)** Nomes iguais, namespaces diferentes (Dart import prefixing se precisar — raro)
- **B)** Domain do Flutter usa sufixo neutro tipo `Patient` (sem prefixo), payload usa `PatientRegisterPayload`, `PatientDetailPayload`

**Recomendação:** (B) — domain models ficam com nome curto; payloads têm sufixo `*Payload` ou `*Response`/`*Request`.

## User Preferences (a confirmar)
- Prefere PT-BR UI labels via design tokens: **SIM** (já é política)
- Quer Sentry capture em cada ticket quando houver `Result.error` no Repository: **?**
- Pref CI: rodar `melos run test` em PR: **?**

## Próximo passo
Usuário revisa Q1–Q8 e responde. Após isso, T01 (Domain Models Foundation) pode começar.
