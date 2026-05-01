# BFF Comprehensive Audit — Executive Summary

**Date:** 2026-05-01
**Scope:** `bff/social_care_desktop/`, `bff/social_care_web/`, `bff/shared/`
**Out of scope:** `apps/acdg_system/`, `packages/*` (user-owned for Phase 4)
**Skills applied:**
- [flutter-expert](../../.claude/skills/flutter-expert/SKILL.md) → 01-flutter-expert-review.md
- [api-security-guardian](../../.claude/skills/api-security-guardian/SKILL.md) → 02-api-security.md
- [auth-session-security](../../.claude/skills/auth-session-security/SKILL.md) → 03-auth-session-security.md
- [red-team-scanner](../../.claude/skills/red-team-scanner/SKILL.md) → 04-red-team-scan.md

---

## Verdict consolidado

| Lente | Posture | Findings (Critical / Major / Minor) | Score |
|---|---|---|---|
| Flutter-Expert (architectural) | **STRONG with focused gaps** | 1 / 7 / 9 | — |
| API Security | **CRITICAL** | 6 / 9 / 7 | — |
| Auth/Session | **CONCERNS** | 5 / 13 / 21 | OWASP ASVS L2 ~50% |
| Red Team (offensive) | **CRITICAL — exploitable** | 9 / 8 / 11 | **18/100** |

**Verdict global: CRÍTICO. NÃO MERGEAR pra produção sem corrigir os 5 ship-blockers.**

A arquitetura é sólida (Onda 4 entregou o que prometeu — 420/420 tests, dart analyze zero, padrões cumpridos). **Mas a wiring de autenticação em produção está ausente.** O BFF Web hoje é, na prática, **não-autenticado** — qualquer request anônimo acessa endpoints "protected".

---

## TL;DR — onde estamos vs onde imaginávamos estar

A Onda 5 (gate final A19-A21) estava planejada como cleanup leve:
- A19 dart analyze zero ✅ (já está)
- A20 atualizar CONTRACT_A_PUBLIC_API.md
- A21 deletar legado

**Auditoria revela que isso é insuficiente.** O BFF Web tem 5 buracos de auth interconectados que se cancelam mutuamente — corrigir 1 sem os outros não resolve. Recomendo intercalar uma **Onda 4.5 (Security Hardening)** antes do Onda 5.

---

## 🚨 5 SHIP-BLOCKERS (interconectados — fix juntos ou nada funciona)

Convergência total dos 3 audits de segurança:

### B1 — Auth guard NÃO wired
- **Files:** `bff/social_care_web/lib/src/server/app_router.dart:173-176`
- **Issue:** `protectedPipeline` é construído sem `authGuardMiddleware()`. Doc-comment falsamente alega que está wired.
- **Impact:** TODOS os 41 "protected endpoints" (`/patients/*`, `/team/*`, `/lookups/*`, `/auth/me`, `/auth/refresh`) aceitam tráfego anônimo.
- **Cross-ref:** Red F01 (CVSS 9.8), API CRITICAL #1, Auth RBAC-2

### B2 — Cookie name mismatch (writer vs reader)
- **Files:** `auth_handler.dart:21,222-223` (escreve `__Host-session=`) ↔ `session_middleware.dart:48-49` (lê `__session=`)
- **Issue:** Sessões nunca são resolvidas pelo middleware — nome do cookie diverge.
- **Impact:** Mesmo SE o auth guard estivesse wired, sessões nunca seriam reconhecidas. Tests pinam o nome errado.
- **Cross-ref:** Red F02 (CVSS 9.1), API CRITICAL #2, Auth SES-1

### B3 — SessionStore.create NUNCA é chamado
- **Files:** `auth_handler.dart:121` (`_dispatchCallback`)
- **Issue:** Callback gera novo cookie via `UuidUtil.generateV4()` mas **nunca chama `SessionStore.create`**. Lifecycle de sessão tem missing write step.
- **Impact:** Mesmo com nome correto, store está vazio. Sessão "existe" no cookie mas não no servidor.
- **Cross-ref:** Red F03 (CVSS 9.0), Auth SES-2

### B4 — FakeAuthBff wired no entrypoint de produção
- **Files:** `bff/social_care_web/bin/server.dart:21-29`
- **Issue:** Production entrypoint usa `FakeAuthBff()` que aprova qualquer code/state e retorna `social_worker` hardcoded. `OidcServerClient` é construído mas **ignored**.
- **Impact:** Não há OIDC real acontecendo. Login forjável trivialmente.
- **Cross-ref:** Red F04 (CVSS 9.8), API CRITICAL #4, Auth TOK-1

### B5 — PKCE store NÃO existe + state nunca validado
- **Files:** `oidc_server_client.dart:72-117`, `auth_callback_intent.dart:26-44`
- **Issues:**
  - `state` parameter é shape-checked mas nunca matched contra store server-side (CSRF gate aberta)
  - PKCE verifier nunca persistido entre login → callback (sem PKCE real)
- **Impact:** OIDC flow vulnerável a CSRF + downgrade.
- **Cross-ref:** Red F06+F07 (CVSS 8.6-8.8), Auth PKCE-1+PKCE-2

**Os 5 são UM problema único:** "wire production auth chain end-to-end". Resolvê-los sequencialmente em UM ticket de auth hardening.

---

## ⚠️ AÇÕES IMEDIATAS DE OPERAÇÕES (independentes do código)

### Op1 — ROTACIONAR Zitadel `OIDC_CLIENT_SECRET` AGORA
- **File:** `bff/social_care_web/.env` (706 bytes, em disco)
- **Status:** ✅ está em `.gitignore` — não no git history
- **Risco:** Apesar de não-trackado, secret production-looking pode ter vazado via:
  - CI logs / build artifacts
  - Screenshots / shared screen
  - Backup de filesystem
  - Tools que leem .env (dotenv parsers)
- **Ação:**
  1. Rotacionar o secret no painel Zitadel imediatamente
  2. Atualizar `.env` local + secrets manager (Bitwarden conforme CLAUDE.md)
  3. Auditar logs de CI dos últimos 30 dias por menções ao valor antigo
- **Cross-ref:** Red F08 (CVSS 9.1)

### Op2 — Auditar Drift databases existentes em desktop
- **Files:** `bff/social_care_desktop/lib/src/cache/_shared/cache_database.dart:283-284`, `sync_database.dart` similar
- **Status:** Bancos `.sqlite` em disco em `getApplicationDocumentsDirectory()` — **plaintext**, sem encryption
- **Conteúdo sensível:** `firstName`, `lastName`, `primaryDiagnosis`, CPF, CNS, `outbox.payload` (request DTOs com PII)
- **Risco específico (red team scenario 3):** Atacante com filesystem access pode `INSERT INTO outbox` mutations falsas (e.g., `report_violation`) que `_PumpingSyncEngine.triggerDrain` dispatcha sob o token legítimo → **fabricação de relatórios de violação contra crianças, assinados pelo profissional inocente**
- **Ação:**
  - Curto prazo: documentar threat model (desktop assume filesystem trusted) OU
  - Médio prazo: encrypt SQLite via SQLCipher (drift-sqlcipher pkg) — Phase 6+ ticket
- **Cross-ref:** Red F09 (CVSS 9.0)

---

## Findings agrupados por categoria (cross-skill convergence)

### 🔴 Auth chain (5 ship-blockers acima + complementos)

Convergência: 4/4 audits.

Adicionais não-blocker mas urgentes:
- **id_token claims** parseados sem signature/iss/aud/exp validation (`oidc_server_client.dart:148-163`, Red F05 CVSS 9.1)
- **Logout não chama** `SessionStore.destroy` nem `oidcClient.revokeToken` — sessões replayable até 1h pós-logout (Red F10)
- **Open-redirect** via `LoginIntent.returnTo` sem allow-list (Red F14)
- **No role-based middleware** — endpoints admin (`/team/*`) reachable por qualquer sessão; `social_worker`/`owner`/`admin` distinção ausente no BFF (Auth)
- **`actorId` é static config**, não derivado da sessão → audit-trail laundromat (Red F12 + scenario 2)
- **OIDC `code=...`** registrado em plaintext via `shelf.logRequests()` rodando OUTSIDE scrub middleware (Red F17)

### 🟠 Defense-in-depth ausentes

Convergência: 2-3/4 audits.

- **Zero security headers** — sem HSTS, CSP, X-Content-Type-Options, X-Frame-Options, Referrer-Policy (API + Red)
- **Sem CSRF protection** — `X-Requested-With: XMLHttpRequest` não enforced; `Sec-Fetch-Site` validation ausente (API)
- **CORS frouxo** — `cors_middleware.dart` ecoa `allowedOrigin` sem validar request `Origin`, sem `Vary: Origin`, aplica em error responses (Red F16)
- **Sem rate limiting** — backend Zitadel handles login mas BFF endpoints sem limites (Auth)
- **Body size sem limite** — POSTs ilimitados (API)
- **`tableName` path injection** em lookup routes — sem allowlist antes de forwarding ao backend Vapor (API + Red F15)

### 🟡 PII leakage paths (LGPD risk)

- **`Cpf.create`/`Nis.create`** interpolam raw CPF/NIS em `AppError.message` (`bff/shared/lib/src/domain/kernel/cpf.dart:64,78,87,96`, `nis.dart` similar) — DORMANT (só invocado de translators não-wired) mas loaded gun pra Phase 4 (API CRITICAL)
- **Dead `backendError` helper** em `handler_utils.dart:48-66` JSON-encoda stack traces (API)
- **PII discipline confirmada** em handlers ativos via `pii_mask` helper — strength validado (Auth + Flutter)

### 🟢 Strengths confirmadas (não regressar)

- Iron Frontier: browser nunca vê tokens — verificado nos handlers ativos (Auth)
- 256-bit secure-random session IDs (Auth)
- `__Host-` prefix + cookie attrs corretos no writer (Auth)
- Server-side TTL com auto-eviction (Auth)
- Cross-layer Clock injection (H5) faithfully aplicado (Flutter)
- 28-variant sealed `SyncMutation` compiler-enforced exhaustive (Flutter)
- Drift cache impls compartilham `_ready` warmup defensivo (Flutter)
- REGRA #2 retro fix em `team_handler_test.dart` documentado in-place (Flutter)
- Zero sealed-class downcasts em production lib (Flutter)

### 🔵 Architectural debt (Flutter-expert)

- **CRITICAL:** 3 production files referenciam `SocialCareContract` deletada (905 LoC) — `handler_utils.dart`, `health_handler.dart`, `social_care_api_client.dart`. Dead code mascarando broken `dart analyze` OR truly broken. A19 (delete legacy) não pode shipar sem isso (Flutter)
- **MAJOR (H6 gap):** `SyncEngine` é plain `class`; `_PumpingSyncEngine` (production) e `FakeSyncEngine` (tests) extendem. H6 doc foi escrito 2026-04-30 explicitamente pra prevenir isso. SyncEngine deveria ser `abstract interface class` (Flutter)
- **MAJOR (lint drift):** `bff/social_care_desktop/analysis_options.yaml` é default unmodified; `social_care_web` e `shared` têm strict P2b/P1. É por isso que `} catch (_) {}` swallows podem shipar no desktop facade close (Flutter)
- **Misc:** `register_patient_intent` único intent sem P2b try/catch (API); pubspec version drift entre BFFs (Flutter)

---

## Mapeamento para tickets

### Onda 4.5 — Security Hardening (NOVO, recomendo intercalar antes da Onda 5)

| Ticket | Escopo | Bloqueio |
|---|---|---|
| **A22** | **Wire production auth chain (B1-B5 juntos)** — authGuard middleware + cookie naming + SessionStore.create + replace FakeAuthBff + PKCE store + state validation + id_token claims validation. UM ticket atômico. | **CRITICAL — bloqueia produção** |
| **A23-bis** (já existe outro A23) → **A24** | **Security headers middleware** — HSTS, CSP, X-Content-Type-Options, X-Frame-Options, Referrer-Policy + CSP nonce per request | HIGH |
| **A25** | **CSRF protection** — `X-Requested-With` enforced + `Sec-Fetch-Site` validation em `/api/*` | HIGH |
| **A26** | **RBAC middleware** — `social_worker`/`owner`/`admin` guards em endpoints específicos (especialmente `/team/*` admin) | HIGH |
| **A27** | **`actorId` from session** — derivar de sessão validada, não de static config | HIGH (audit-trail integrity) |
| **A28** | **PII leak fix** em `Cpf`/`Nis` smart constructors (preventivo antes de Phase 4 wirear) | MEDIUM |
| **A29** | **Logout completeness** — `SessionStore.destroy` + `oidcClient.revokeToken` | MEDIUM |
| **A30** | **CORS hardening** + `tableName` allowlist em lookup routes + open-redirect fix em `returnTo` | MEDIUM |
| **A31** | **Rate limiting + body size limits** | MEDIUM |
| **A32** | **OIDC code log scrub** (move logRequests INSIDE scrub middleware) | MEDIUM |

### Onda 5 — Gate Final (revisado)

Original A19-A21 + adicionados:

| Ticket | Escopo |
|---|---|
| **A19** | `dart analyze bff/ zero errors` — desktop já está; web tem 3 legacy files referenciando `SocialCareContract` deletada (905 LoC) — DELETE primeiro |
| **A20** | Atualizar `handbook/architecture/CONTRACT_A_PUBLIC_API.md` |
| **A21** | Deletar resto de código legado em `bff/` (3 files acima + dead `backendError` helper + `SESSION_SECRET` env var unused) |
| **A21b (NOVO)** | Promote `SyncEngine` para `abstract interface class` (H6 gap fix) |
| **A21c (NOVO)** | Unificar `analysis_options.yaml` em todos os 3 BFFs (lint floor consistente) |

### Phase 4 (user-driven, não auditado mas relevante)

Quando usuário atacar `packages/`:
- **packages/social_care/`HttpSocialCareClient`** referencia `SocialCareBffRemote` deletada — fix integrado com 51 issues residuais
- Verificar se `Cpf`/`Nis` usage em packages/ usa o smart constructor correctly (após A28 fix)
- Considerar SQLCipher para Drift encryption no desktop (Op2 médio prazo)

---

## Métricas finais

| Métrica | Valor |
|---|---|
| Files audited | ~150+ across `bff/` |
| Total findings (dedup'd) | ~50-60 unique (21 critical, 25 major, 30 minor após cross-correlation) |
| Convergent findings (multi-skill) | 12 (the strongest signals) |
| Lines of audit reports | 1866 (4 files) |
| Time to audit | ~2h pipeline ativo, 4 agents paralelos |
| Pre-existing strengths confirmed | 9 |

## Recomendação executiva

**NÃO PROCEDER com merge to main / deploy production sem corrigir B1-B5 (auth chain).**

**Sequência recomendada:**

1. **Hoje (operacional):** Op1 — rotacionar Zitadel client secret
2. **Onda 4.5:** A22 (auth chain end-to-end) — uma sprint de ~2-3 dias com pipeline 3-agent. Critical blocker.
3. **Onda 4.5 cont:** A24-A32 — defense-in-depth (~1 sprint)
4. **Onda 5:** A19-A21 + A21b/c (cleanup gate)
5. **Phase 4:** user-driven packages/ work
6. **Phase 6+:** SQLCipher encryption (Op2), MFA, advanced rate limiting

**Total tempo estimado para production-ready:** 2-3 semanas pipeline ativo (a Onda 4 levou 3 dias; security hardening é mais denso).

---

## Apêndice — referência aos relatórios detalhados

| Relatório | Arquivo | Foco |
|---|---|---|
| Flutter-Expert | [01-flutter-expert-review.md](./01-flutter-expert-review.md) | Architectural rigor, ADR adherence, H1-H6 |
| API Security | [02-api-security.md](./02-api-security.md) | OWASP API Top 10 + ACDG context |
| Auth/Session | [03-auth-session-security.md](./03-auth-session-security.md) | OWASP ASVS L2 + IAM + Zitadel |
| Red Team | [04-red-team-scan.md](./04-red-team-scan.md) | Offensive scan, OWASP WSTG, ACDG-specific vectors, attack chains, PoCs |
| **Isolates Opportunities** (addendum) | [05-isolates-opportunities.md](./05-isolates-opportunities.md) | C1 `Isolate.run` analysis — performance, fluidez, segurança via memory isolation, algoritmo |

**Total:** 4 audits gerais + 1 addendum focado em isolates.

### Achado adicional do isolates audit (Tier 1 — high impact)

**T1.1 — Drift `NativeDatabase` opera na main isolate (`social_care_desktop.dart:697`).** ADR-021 escolheu Drift sobre Isar citando suporte a multi-isolate como vantagem; **a implementação não usa**. Migração para `NativeDatabase.createInBackground` é 1-line × 2 sites com ganho desproporcional (eliminação de toda categoria "DB op freezes UI"). Recomendado adicionar como **A22b** na Onda 4.5.
