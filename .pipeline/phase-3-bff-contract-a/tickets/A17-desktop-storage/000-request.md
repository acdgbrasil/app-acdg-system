# A17 — Desktop: Storage (offline-first)

## Onda: 4 | Profile: bff/social_care_desktop | Depende de: A16

## Escopo
`bff/social_care_desktop/lib/src/storage/` (LocalSocialCareRepository, OfflineFirstRepository) alinhado com os payloads/responses novos.

Hoje mistura DTOs antigos e novos (estado da phase-2). Objetivo: consistência total com os novos DTOs de A02/A03.

## Critérios
- [ ] `LocalSocialCareRepository` e `OfflineFirstRepository` usam só DTOs novos
- [ ] Drift schema ajustado se necessário (sem quebrar dados existentes caso haja — Desktop não em prod)
- [ ] `dart analyze bff/social_care_desktop/lib/src/storage/` verde

## Status
pending — blocked by A16
