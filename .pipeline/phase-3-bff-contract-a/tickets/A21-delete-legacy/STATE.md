# Ticket State: A21-delete-legacy

phase: done
status: closed 2026-05-01 (BFF-side complete; packages/-side deferred to Phase 4)

## Outcome
- BFF-side cleanup: completo (`PatientTranslator` + `mappers/` + comentários mortos a `SocialCareContract` removidos)
- Critérios `grep` BFF passam (zero refs a `SocialCareContract`/`PatientTranslator`/`HttpSocialCareClient`)
- 2036 testes GREEN (perda esperada de 14 = patient_translator_test)
- Inventário de cleanup `packages/social_care/` + `apps/acdg_system/` + `bff/shared/dtos/` documentado em REPORT como herança a Phase 4

## Phase 3 STATE
Fase BFF Contract A: **DONE** após merge deste ticket.

## Phase 4 STATE
Inventário herdado (12 arquivos a deletar + 4 arquivos com refs em apps/) registrado em REPORT.md desta pasta — Phase 4 absorve.
