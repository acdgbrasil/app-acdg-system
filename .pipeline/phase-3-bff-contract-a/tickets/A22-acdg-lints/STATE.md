# Ticket State: A22-acdg-lints

phase: request
status: pending — scheduled for post-A21 cleanup or early phase-4 tooling

## Por que foi criado
Emergiu de A10 → P2b definition. `PATTERN_MATCHING_POLICY.md §P2b` + ADR-019 pinam regras (catch without stack, intent parser sem obs, parse error público) que `dart analyze` built-in não detecta. Code review humano é fallback frágil.

## Bloqueio
- [ ] A19 (analyze verde final) deve estar fechado — custom_lint não pode rodar sobre código já quebrado

## Próxima ação
Quando chegarmos pós-A21: ler `000-request.md`, scaffold do package `packages/acdg_lints/`, começar com rule `catch_without_stack_in_adapter`.
