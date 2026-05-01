# Ticket State: A19-final-analyze

phase: done
status: closed 2026-05-01

## Outcome
- 3 BFF módulos verdes em `dart analyze` em src/ (zero errors)
- 2050 testes GREEN (549 shared + 1075 web + 426 desktop)
- 2 infos não-bloqueantes em `rg_document.dart` listados em REPORT.md

## Pré-requisito BFF-side absorvido
2 errors em arquivos legados não exportados foram resolvidos como precondition:
- Deletado: `bff/social_care_web/lib/src/remote/social_care_api_client.dart` (+ test) — god-class implementando `SocialCareContract` deletada em A05
- Refatorado: `bff/social_care_web/lib/src/handlers/health_handler.dart` (+ test) — agora depende de `HealthContract` canônico (sub-contract A04)

## Item descartado
"Marcar test/ deprecated" não executado — as suites são canônicas (TDD A07-A18), não legacy. Justificativa em REPORT.md.

## Next
A20 — Contract A docs.
