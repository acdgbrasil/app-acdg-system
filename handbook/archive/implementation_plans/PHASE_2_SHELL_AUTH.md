# 🔐 Fase 2 — Shell + Auth

Implementação da segurança e navegação baseada em identidade real.

## Status: ✅ CONCLUÍDO (100%)

### 2.1 Auth Domain
- [x] Modelos imutáveis: `AuthUser`, `AuthToken`, `AuthRole`.
- [x] Repositório: `AuthRepository` (Interface + Impl com `package:oidc`).
- [x] UseCases: `Login`, `Logout`, `RestoreSession`.

### 2.2 UI & Navigation
- [x] **Atomic Design**: Implementação dos primeiros átomos, moléculas e organismos.
- [x] **AuthViewModel**: Gerenciamento de estado via comandos reativos.
- [x] **AppRouter (GoRouter)**:
  - [x] Redirecionamentos globais baseados em status.
  - [x] Guards por Role (RBAC).
- [x] **Telas Base**: Splash, Login e Home funcionais.

### 2.3 Integração Real (Staging)
- [x] **HmlAuthHelper**: Utilitário para troca de tokens via Service Account (Zitadel).
- [x] **Staging Integration Tests**:
  - [x] Validação real de token contra Zitadel.
  - [x] Validação de conectividade com `social-care-hml`.
  - [x] Teste de fluxo fim-a-fim no app.
