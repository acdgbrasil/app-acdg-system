# A18 — Desktop: Sync

## Onda: 4 | Profile: bff/social_care_desktop | Depende de: A17

## Escopo
`bff/social_care_desktop/lib/src/sync/sync_engine.dart` consome DTOs novos. Action types da SyncQueue atualizados.

## Critérios
- [ ] `SyncEngine._dispatchAction` usa DTOs de A02
- [ ] Zero `SocialCareContract` ou `PatientTranslator`
- [ ] `dart analyze bff/social_care_desktop/lib/src/sync/` verde

## Status
pending — blocked by A17
