# C04 — CLI Family Commands

## Onda: 3 | Profile: feature | Depende de: C03

## Escopo

```bash
acdg family add <patient-id> --member-cpf=X --first-name=Y --relationship=Z
acdg family remove <patient-id> --member-id=<uuid>
acdg family assign-caregiver <patient-id> --member-id=<uuid>
acdg family update-identity <patient-id> --gender=X --pronoun=Y [...]
```

### Sub-contracts BFF consumidos
- `RegistryContract` (addFamilyMember, removeFamilyMember, assignPrimaryCaregiver, updateSocialIdentity)

### Detalhes

- **add** é endpoint composto — registra pessoa no PeopleContext + cria FamilyMember no SocialCare em transação saga.
- **assign-caregiver** marca um family-member como caregiver principal.
- **update-identity** atualiza pronome, gender, etc do paciente principal (não do family member).

## Pipeline

W0 (test-writer) → W1 (flutter-bff-implementer) → W2 (flutter-code-reviewer) → W3 (flutter-quality-checker)

## Critérios

- [ ] 4 comandos funcionais
- [ ] Tests cobrindo saga edge cases (PeopleContext fail → SocialCare rollback)
- [ ] `dart analyze` zero issues

## Status
pending — blocked by C03
