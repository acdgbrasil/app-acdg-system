# Ticket State: A05-delete-social-care-contract

phase: done
agent: maestro (manual)
status: completed 2026-04-17

## Completed
- [x] social_care_contract.dart deletado
- [x] Export removido de shared.dart
- [x] 11 sub-contracts exportados diretamente
- [x] bff/shared/lib: 0 errors (3 warnings em FakeSocialCareBff — A06 resolve)

## Breaking impact esperado
- bff/social_care_web/lib: 10 errors (A07-A15 consertam)
- bff/social_care_desktop/lib: 28 errors (A16-A18 consertam)
- FakeSocialCareBff: 2 errors (A06 substitui)
- Testes ignorados: 46 errors (deprecados)
