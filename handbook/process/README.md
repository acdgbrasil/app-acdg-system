# Processo — frontend (Conecta Raros)

Acordos operacionais, fluxo de trabalho e convencoes de desenvolvimento.

---

## 1. Fluxo de Trabalho

### 1.1 Branch Convention

Seguindo o padrao ACDG:

```
feat/<issue-id>-<slug>    # Nova funcionalidade
fix/<issue-id>-<slug>     # Correcao de bug
chore/<issue-id>-<slug>   # Manutencao, refactor
docs/<issue-id>-<slug>    # Documentacao
```

### 1.2 Commit Convention

Conventional Commits:

```
feat: add patient registration desktop page
fix: correct ValueNotifier disposal in housing VM
chore: update Dio to 5.x
docs: add offline sync documentation
refactor: extract form validation to use case
test: add patient registration VM tests
```

### 1.3 PR Flow

1. Abrir issue antes de codar
2. Criar branch a partir de `main`
3. Desenvolver com testes
4. Abrir PR com contexto, riscos e evidencias de teste
5. Review obrigatorio
6. CI deve passar (analyze + test + build)
7. Merge via squash

### 1.4 Definition of Done

- [ ] Testes passando
- [ ] `flutter analyze` sem warnings
- [ ] Sem segredos hardcoded
- [ ] Documentacao atualizada se mudou comportamento
- [ ] Compatibilidade retroativa avaliada
- [ ] Funciona offline (se aplicavel)
- [ ] Testado nas 3 plataformas (Desktop/Web/Mobile)

---

## 2. Versionamento

### 2.1 Packages

Cada package tem versao independente seguindo SemVer:
- `MAJOR` — breaking changes na API publica
- `MINOR` — funcionalidade nova, retrocompativel
- `PATCH` — bug fix

### 2.2 Shell

O Shell segue o versionamento do produto (release do Conecta Raros):
- `v1.0.0` — MVP com Social Care
- `v1.1.0` — Melhorias de UX
- `v2.0.0` — Adicao do People Context

---

## 3. Fluxo de Desenvolvimento por Feature

```
1. Definir feature no issue tracker
2. Criar models (schemas imutaveis)
3. Criar Service (wrapper Dio)
4. Criar Repository (cache, retry, error handling)
5. Criar UseCase (logica de aplicacao)
6. Criar ViewModel (estado atomico)
7. Criar Pages (Desktop/Web/Mobile)
8. Criar/reutilizar Components (Atomic Design)
9. Testes (ViewModel + UseCase)
10. PR + Review + Merge
```

Ordem: **Model -> Service -> Repository -> UseCase -> ViewModel -> View**
(De dentro para fora, nunca o contrario)

---

## 4. Code Review Checklist

- [ ] Segue MVVM estrito (View nao decide, ViewModel nao importa widgets)
- [ ] Estado atomico (ValueNotifier por campo)
- [ ] Models imutaveis (final em tudo, copyWith)
- [ ] Sem logica de negocio no Flutter (so no BFF)
- [ ] Provider para DI (nao service locator)
- [ ] Imports organizados (SDK -> external -> internal -> relative)
- [ ] Nomenclatura correta (sufixos: *ViewModel, *UseCase, *Repository, *Service, *Page)
- [ ] Testes para ViewModel e UseCase
- [ ] Funciona offline (queue de acoes)
