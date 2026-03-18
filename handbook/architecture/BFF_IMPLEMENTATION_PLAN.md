# BFF Implementation Plan — Social Care

> **Status:** Atualizado (2026-03-13) — Alinhado com Padrões ACDG v2
> **Decisores:** Gabriel Aderaldo + Claude Code
> **Escopo:** `bff/` do monorepo frontend ACDG

---

## 1. Decisões Estratégicas (Alinhadas com Handbook)

Registro de todas as decisões feitas durante o planejamento, integrando as melhores práticas de arquitetura por camadas.

### D-001: Dois tipos de BFF
Mantemos a separação por plataforma para garantir performance nativa no Desktop e segurança na Web.
- **BFF Desktop:** In-process (package Dart).
- **BFF Web:** Darto HTTP (proxy).

### D-002: Kernel Compartilhado e Engine de Igualdade
- Os models de domínio no `bff/shared/` devem utilizar obrigatoriamente a nova engine `Equatable` do core (`with Equatable`).
- **Motivo:** Garantir comparação por valor e consistência de hash em todo o fluxo de dados (BFF -> App).

### D-003: Orquestração via UseCases (Logic Layer)
- O `SocialCareContract` (BFF) é consumido exclusivamente pela **Logic Layer** do App via `UseCases`.
- **Fluxo:** UI (Command) → Logic (UseCase) → Data (BFF Contract).
- **Motivo:** Isolar o App da implementação do BFF, permitindo que a regra de orquestração (ex: sync offline) viva no UseCase.

### D-004: Padronização Result e Erros
- Todos os métodos do contrato BFF **DEVEM** retornar `Future<Result<T>>`.
- Erros de rede ou validação do BFF devem ser mapeados para a classe `Failure` do core.

---

## 2. Arquitetura de Packages

```
bff/
├── shared/                              # Kernel compartilhado (Puro Dart)
│   ├── lib/
│   │   ├── src/
│   │       ├── domain/                  # Models (USAM: with Equatable)
│   │       ├── contract/                # Interface (RETORNA: Result<T>)
│   │       └── validation/              # Regras de negócio (ADR-014)
│
├── social_care_desktop/                 # BFF Nativo (Offline First)
│   ├── lib/
│   │   └── src/
│   │       ├── sync/                    # Gerenciado por UseCases no App
│   │       └── storage/                 # Isar Repositories
│
└── social_care_web/                     # BFF Web (Darto HTTP)
    ├── lib/
    │   └── src/
    │       ├── middleware/              # Auth, CORS, Env (USA: Env utility)
    │       └── api_client/              # Dio wrapper -> API backend
```

---

## 3. Fases de Implementação Atualizadas

### Fase 1: Shared — Kernel de Domínio (Base Imutável)
- [ ] Implementar VOs e Agregados usando `with Equatable` do core.
- [ ] Garantir que todos os campos sejam `final` (ADR-010).
- [ ] Definir o `SocialCareContract` retornando `Result<T>`.

### Fase 2: Integração com Camada de Lógica (App)
- [ ] Criar `UseCases` no `acdg_system` para cada operação do contrato.
- [ ] Vincular `UseCases` a `Commands` nos ViewModels.
- [ ] **Exemplo de Fluxo:**
    ```dart
    // UI
    onPressed: viewModel.registerPatient.execute
    
    // ViewModel
    registerPatient = Command1(registerPatientUseCase.execute)
    
    // UseCase
    Future<Result<String>> execute(Patient p) => bff.registerPatient(p)
    ```

### Fase 3: Infraestrutura e Ambiente
- [ ] Utilizar a classe `Env` do core para carregar URLs de API e segredos no `social_care_web`.
- [ ] Extrair configurações de portas e endpoints para a `Logic Layer` do app.

---

## 4. Guia de Implementação de Modelos (BFF Shared)

Seguindo o "Código de Ouro" da ACDG:

```dart
import 'package:core/core.dart';

final class Patient with Equatable {
  const Patient({required this.id, required this.name});
  
  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
```

---

## 5. Checklist de Auditoria (v2)

- [ ] Todos os modelos herdam/usam `Equatable`?
- [ ] O contrato retorna `Result` em todos os métodos?
- [ ] Existe um UseCase no App para cada ação do BFF?
- [ ] O carregamento de configurações do BFF Web usa `Env`?
- [ ] A injeção do BFF no App é feita via `root.dart` (Provider)?

---

## 6. Glossário Atualizado

| Termo | Definição |
|---|---|
| **Logic Layer** | Camada onde vivem os UseCases que consomem o BFF. |
| **Command** | Padrão usado na UI para disparar ações do BFF. |
| **Equatable** | Engine do core usada para igualdade nos models do BFF. |
| **Env** | Utilitário usado para configurar os endpoints do BFF. |
