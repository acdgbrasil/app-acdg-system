# Auditorias do monorepo ACDG (frontend)

Diretório dedicado a relatórios de auditoria — arquitetural, segurança, performance, compliance. Cada auditoria fica numa pasta datada com seus relatórios + executive summary.

## Estrutura

Cada auditoria é uma pasta `YYYY-MM-DD-<scope>/` contendo:
- `SUMMARY.md` — executive summary + cross-skill consolidation
- Relatórios numerados por skill (`01-<skill>.md`, `02-<skill>.md`, …)
- Optional: PoC files, screenshots, supporting evidence

## Index de auditorias

### 2026-05-01-bff-comprehensive — **CRITICAL findings**
Auditoria nível profundidade do `bff/` completo (3 sub-projects: `social_care_desktop`, `social_care_web`, `shared`) com 4 skills paralelas após fechamento da Onda 4.

**Verdict:** CRÍTICO — 5 ship-blockers interconectados na auth chain do BFF Web. NÃO MERGEAR pra produção sem correção.

**Skills aplicadas:**
- flutter-expert (architectural rigor)
- api-security-guardian (8 dimensões)
- auth-session-security (OWASP ASVS L2 + Zitadel)
- red-team-scanner (OWASP WSTG + ACDG-specific vectors)

**Findings consolidados:** ~50-60 unique (21 critical, 25 major, 30 minor após cross-correlation entre skills).

**Imediato:** rotacionar `OIDC_CLIENT_SECRET` em Zitadel.

→ [SUMMARY](./2026-05-01-bff-comprehensive/SUMMARY.md) · [Flutter-Expert](./2026-05-01-bff-comprehensive/01-flutter-expert-review.md) · [API Security](./2026-05-01-bff-comprehensive/02-api-security.md) · [Auth/Session](./2026-05-01-bff-comprehensive/03-auth-session-security.md) · [Red Team](./2026-05-01-bff-comprehensive/04-red-team-scan.md)

---

### appRefector_03_04_2026_done — auditoria pré-Onda 4 (histórico)
Auditoria do app shell + UI + DI + DS + offline + OIDC realizada antes da Onda 4 (desktop rebuild). Status: histórico. Achados que sobraram foram absorvidos na Onda 4 ou viraram backlog.

→ Ver pasta para 8 relatórios temáticos.

---

## Convenção para novas auditorias

1. Criar pasta `YYYY-MM-DD-<scope-slug>/`
2. Dispatch agentes especializados em paralelo (cada um escreve seu relatório `NN-<skill>.md`)
3. Consolidar em `SUMMARY.md` com cross-correlation
4. Atualizar este index

**Skills disponíveis para auditorias** (em `.claude/skills/`):
- `flutter-expert` (architectural)
- `api-security-guardian` (API security)
- `auth-session-security` (IAM + sessions)
- `red-team-scanner` (offensive)
- `appsec-code-reviewer` (defensive code review)
- `threat-modeler` (STRIDE + OWASP ASVS)
- `devsecops-pipeline` (CI/CD + supply chain)
- `pipeline-maestro` (multi-agent orchestration)
