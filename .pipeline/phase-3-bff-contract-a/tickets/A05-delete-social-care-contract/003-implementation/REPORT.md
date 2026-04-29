# A05 REPORT — Delete SocialCareContract

## Status: COMPLETED

## Ações executadas
1. **Deletado:** `bff/shared/lib/src/contract/social_care_contract.dart`
2. **Removido export** de `social_care_contract.dart` em `bff/shared/lib/shared.dart`
3. **Adicionados exports** dos 11 sub-contracts diretamente em `shared.dart` (antes eram re-exportados via god-interface)

## Validação

### `bff/shared/lib` (limpo!)
```
dart analyze bff/shared/lib
→ 53 issues: 0 errors, 3 warnings, 50 infos
```
Os 3 warnings são em `fake_social_care_bff.dart` (métodos com @override apontando para classe que não existe mais). Esperado — A06 substitui este fake monolítico.

### `bff/` (breakage esperado — 90 errors)
| Arquivo | Errors | Será consertado em |
|---------|:------:|--------------------|
| `bff/social_care_desktop/lib/src/storage/offline_first_repository.dart` | 25 | **A16-A17** |
| `bff/social_care_desktop/lib/src/sync/sync_engine.dart` | 2 | **A18** |
| `bff/social_care_desktop/lib/src/storage/local_cache_contract.dart` | 1 | **A17** |
| `bff/social_care_desktop/lib/src/remote/social_care_bff_remote.dart` | 1 | **A16** |
| `bff/social_care_web/lib/src/handlers/*.dart` (7 handlers) | 7 | **A07-A15** |
| `bff/social_care_web/lib/src/use_cases/*.dart` (2) | 2 | **A07-A15** |
| `bff/social_care_web/lib/src/remote/social_care_api_client.dart` | 1 | **A16-ish** (pode ser movido) |
| `bff/social_care_web/lib/src/server/app_router.dart` | 1 | **A07-A15** (wiring) |
| `bff/social_care_web/bin/server.dart` | 2 | **A07-A15** |
| `bff/shared/lib/src/testing/fake_social_care_bff.dart` | 2 | **A06** (delete) |
| **tests (todos os módulos)** | 46 | **ignorados** (deprecados) |

**Total errors em src/ (produção):** 44
**Total errors em test/:** 46 (ignorados)

## Principal consequência
`FakeSocialCareBff` em `bff/shared/lib/src/testing/` ficou com 3 warnings (métodos @override inválidos). **NÃO foi deletado** neste ticket — é trabalho do A06 (que vai substituí-lo por fakes por sub-contract).

## Próximos tickets e seu escopo

| Ticket | Conserta |
|--------|----------|
| **A06** — Fakes per contract | `FakeSocialCareBff` → 11 fakes especializados |
| **A07-A15** — Web handlers/use_cases | 13 arquivos em `social_care_web/lib` |
| **A16-A18** — Desktop | 4 arquivos em `social_care_desktop/lib` |

## Princípio respeitado
Conforme plano original e autorização do usuário:
- Breaking changes livres
- Testes deprecados (ignorar)
- Desktop não em produção (pode quebrar temporariamente)
- "Deleta em A05, A06+A07+A16 consertam"

## Next
A06 — Fakes per sub-contract (11 arquivos) + delete FakeSocialCareBff.
