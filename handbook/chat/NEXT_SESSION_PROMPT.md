# Prompt para próxima sessão Claude

Copie e cole isso ao iniciar:

---

## Contexto

Leia os seguintes arquivos na ordem:

1. `handbook/chat/013_gemini_to_claude_review_rejected.md` — O Gemini rejeitou a Missão 1
2. `handbook/chat/014_claude_to_gemini_mission1_acknowledged.md` — Meu plano de correção
3. Memória: `project_handoff_missions.md` — Estado atualizado das 3 missões

## Estado atual

- **Missões 2 e 3**: APROVADAS pelo Gemini, código pronto, testes GREEN (329 pass)
- **Missão 1**: REJEITADA — criei o `ModalSideMenu` widget mas **não removi** os `_build*` methods dos modais existentes

## O que fazer agora

### 1. Commitar o que está aprovado (Missões 2 e 3)

As mudanças aprovadas incluem:
- `core_contracts` package (desacoplamento dart:ui)
- `BackendError` tipado no BFF Web
- `PeopleContextClient.getPerson` + enrichment no `RegistryHandler`
- `SentryLoggerImpl` + `SentryClientAdapter` + `FakeSentryClient`
- `_readDiagnoses` no `PatientRemote` (initialDiagnoses aliasing)
- `fullName` removido do `SocialCareContract.addFamilyMember`
- Dockerfile.bff AOT + distroless:nonroot
- Remoção do isar_service_test.dart obsoleto

### 2. Executar a Missão 1 (extração dos _build methods)

Extrair 5 métodos privados para StatelessWidgets:

**`family_member_modal.dart`** (registration):
- `_buildLeftColumn()` → `FamilyMemberFormFields` (novo arquivo)
- `_buildRightColumn()` → `FamilyMemberRelationshipPanel` (novo arquivo)

**`add_member_modal.dart`** (family composition):
- `_buildInfoNote()` → `AddMemberInfoNote` (novo arquivo)
- `_buildLeftColumn({required bool isEditing})` → `AddMemberFormFields` (novo arquivo)
- `_buildFooter()` → `AddMemberFooter` (novo arquivo)

Cada widget:
- Extends `StatelessWidget`
- Recebe dados via construtor
- Repassa eventos via callbacks
- 1 widget por arquivo

**Teste de validação:**
```bash
flutter test packages/social_care/test/architecture/architectural_guard_test.dart
```

O teste na linha 88-93 procura `Widget _*\(` — deve passar após a extração.

### 3. Reportar ao Gemini

Após os testes passarem, criar `handbook/chat/015_claude_to_gemini_mission1_fixed.md` com o resultado.

---
