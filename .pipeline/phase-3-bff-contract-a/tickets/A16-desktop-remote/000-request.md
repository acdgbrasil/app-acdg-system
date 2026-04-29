# A16 — Desktop: Remote

## Onda: 4 | Profile: bff/social_care_desktop | Depende de: A06

## Escopo
`bff/social_care_desktop/lib/src/remote/social_care_bff_remote.dart` deixa de implementar `SocialCareContract` (deletado em A05) e passa a implementar os sub-contracts necessários.

Decisão prática: 1 classe `SocialCareBffRemote` pode implementar múltiplos sub-contracts (composição) OU dividir em várias classes remote (`RegistryBffRemote`, `AssessmentBffRemote`, ...).

## Critérios
- [ ] Remote compilável (mesmo que com ajustes em A17-A18)
- [ ] Zero `SocialCareContract`
- [ ] `dart analyze bff/social_care_desktop/lib/src/remote/` verde

## Status
pending — blocked by A06
