# Bugs — Phase 5 (Fluxo de Cadastro)

> Identificados durante sessão de análise e teste em 2026-03-19.
> Marque com `[x]` conforme forem resolvidos.

---

## UI / Máscaras

- [ ] **Todas as máscaras de input estão quebradas** — CPF, CEP, RG, telefone, data. O `AppMasks` não está funcionando corretamente em runtime.

## Overflow

- [ ] **RenderFlex overflow** em `AcdgFormField` (linha 348) — Row overflow de 1.5px no eixo horizontal. Widget: `acdg_form_field.dart:348` (variante `checkboxSimple` ou `selection`).

## Funcionalidade

- [ ] **Family composition mock data** — `_mapToUIModels` em `family_composition_page.dart` retorna dados mock hardcoded em vez de mapear os membros reais do domínio.
- [ ] **onSave do modal não persiste** — `MemberEditModal.onSave` callback em `family_composition_page.dart` está vazio (não adiciona/edita membros no ViewModel).
- [ ] **Campos sem binding** — Alguns campos em `reference_person_page.dart` não persistem no ViewModel: `rgUf`, `rgDate`, `birthDate`, `diagnosis`, `uf`.
- [ ] **Título errado** — `specificities_page.dart` usa `RegistrationStrings.familyCompositionTitle` mas deveria ter título próprio de Especificidades.

## Validação

- [ ] **Validação step2 ausente** — Não há `validateStep2()` para a composição familiar antes de avançar para especificidades.
- [ ] **Cálculo de idade ausente** — `MemberEditModal` captura `_birthDate` mas nunca calcula `_age` a partir dela.

---

## Como reportar novos bugs

Adicione abaixo seguindo o formato:

```markdown
- [ ] **Título curto** — Descrição do bug. Arquivo/widget afetado se conhecido.
```
