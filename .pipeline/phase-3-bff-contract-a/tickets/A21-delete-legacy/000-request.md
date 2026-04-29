# A21 — Delete Legacy

## Onda: 5 | Profile: cleanup | Depende de: A19, A20

## Escopo
Remover código legado que ficou como "convive temporariamente" durante a fase:

### Em `packages/social_care/`
- [ ] `packages/social_care/lib/src/data/services/http_social_care_client.dart` — 643L, implementa contrato morto
- [ ] `packages/social_care/lib/src/data/services/http/` — split que fizemos agora; também pode ir (Flutter migration fará novos em Fase 4)
- [ ] `PatientTranslator` (ACL primitivo — referenciado 16× no http client)
- [ ] `PatientDetailTranslator` (se ainda existir em `ui/home/`)
- [ ] `bff_patient_repository.dart` (legacy — Fase 4 criará novo)

**NOTA:** deletar esses arquivos quebra o Flutter inteiro. **OK**, porque Fase 4 vai reimplementar. Entre A21 e Fase 4, o app Flutter não compila. É um commit de "fim de fase BFF — app quebrado, próxima fase conserta".

### Em `bff/`
- [ ] Pastas `test/` deprecated — deletar se o usuário autorizar (senão deixa com `DEPRECATED.md`)

## Critérios
- [ ] `grep -r "SocialCareContract"` retorna vazio no projeto todo
- [ ] `grep -r "PatientTranslator"` idem
- [ ] `grep -r "HttpSocialCareClient"` idem
- [ ] `dart analyze bff/` zero errors em src/
- [ ] (Flutter fica quebrado — Fase 4 conserta)

## Status
pending — blocked by A19, A20

## Finalização
Após A21 merged, STATE.md da fase vira `phase: done`. Abrir Fase 4 (`.pipeline/phase-4-flutter-migration/`) para continuar.
