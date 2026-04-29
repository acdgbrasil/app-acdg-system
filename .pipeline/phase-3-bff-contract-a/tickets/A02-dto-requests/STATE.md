# Ticket State: A02-dto-requests

phase: implementation
agent: TDD (test-writer + implementer in sequence)
status: COMPLETED — Wave 0 (tests RED) + Wave 1 (implementation GREEN) ambos concluídos.

## Waves

- [x] Wave 0 — test-writer (2026-04-16): 5 round-trip tests em `bff/shared/test/contract/dto/requests/` (registry/admit + governance/). Todos falham por classes não existirem. Ver `002-tests/REPORT.md`.
- [x] Wave 1 — implementer (2026-04-16): 5 DTOs criados em `contract/dto/requests/` (registry/admit + governance/ nova pasta) + 5 exports em `shared.dart` + build_runner gerou os `.g.dart`. 20 testes passam (4 registry + 16 governance). `dart analyze lib` zero errors. REPORT inline na resposta do agent (não gravado em arquivo por política do harness).

## Overall

A02 ticket completed. Pronto para dependentes (mappers, remotos, handlers) consumirem os DTOs.
