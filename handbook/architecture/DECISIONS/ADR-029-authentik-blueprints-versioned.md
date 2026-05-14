# ADR-029 — Property mappings e configuracao Authentik versionadas em Blueprint YAML

**Status:** Proposed
**Date:** 2026-05-13
**Deciders:** Authentik Evaluation Spike (`acdg/auth-spike/REPORT.md`)
**Related:** [ADR-027](ADR-027-authentik-replaces-zitadel.md), [ADR-028](ADR-028-oidc-discovery-source-of-truth.md), [ADR-030](ADR-030-idp-events-via-people-context.md)

---

## Contexto

Authentik permite customizar comportamento do IdP via:

- **Flow Engine** — fluxos de autenticacao, recovery, enrollment, MFA, etc. configurados via UI ou API. Cada flow e uma cadeia de **Stages** (identification, password, prompt, authenticator_validate, user_login, user_write, email, consent, ...) com **Policy Bindings** opcionais.
- **Property Mappings** — funcoes Python que transformam atributos de user em claims OIDC ou em campos SAML. Exemplo:

  ```python
  # Scope mapping "acdg-roles"
  return {
      "roles":      [g.name for g in user.ak_groups.all()],
      "org_id":     user.attributes.get("org_id", "acdg-default"),
      "person_id":  user.attributes.get("person_id"),
      "legacy_sub": user.attributes.get("legacy_zitadel_sub"),
  }
  ```

- **Brands**, **Providers**, **Applications**, **Policies**, **NotificationRules**, **NotificationTransports**.

Todos esses recursos vivem em **tabelas Postgres do Authentik**, populadas por chamadas API ou via UI. Em uma operacao desavisada, isso significa:

- **Mudanca de runtime sem rastro em git** — alguem clica em "Edit" na UI e o comportamento muda. Code review nao pega.
- **Disaster recovery quebrado** — perda do Postgres = perda de toda customizacao. Backup-restore nao basta porque chaves de assinatura JWT mudam junto com o restore.
- **Drift entre ambientes** — staging tem flow X v3, prod tem v2, ninguem sabe.
- **Codigo Python rodando no IdP** — property mappings sao codigo dinamico, nao versionado, sem CI. Risco de regressao silenciosa em upgrade do Authentik.

Authentik resolve isso oferecendo **Blueprints** (YAML) — formato declarativo que descreve o estado desejado de qualquer recurso. Blueprints vivem em `/blueprints/` no container e sao reaplicadas no boot (idempotentes). Validado no spike: export completo da instancia gerou `acdg/auth-spike/authentik/seed/00-baseline.yaml` (88KB, 210 entries).

## Decisao

**Toda configuracao runtime do Authentik DEVE ser versionada como Blueprint YAML em `acdg/edge-cloud-infra/authentik/blueprints/` (durante spike: `acdg/auth-spike/authentik/seed/`). Mudancas em prod sao feitas via PR no repo de infra.**

Regras concretas:

1. **UI do Authentik e read-only em producao.** Permissions de admin podem ser concedidas para inspecao, mas o consenso operacional e: mudancas vao via blueprint + git + PR.
2. **Blueprints sao a fonte de verdade** — se houver divergencia entre Postgres e blueprint, o blueprint vence (proximo boot reaplica).
3. **Toda Property Mapping Python e versionada com a expressao inline no YAML**, jamais editada via UI. PR de mudanca passa por code review do time como qualquer outro codigo.
4. **Secrets nao vao em blueprint** — `CertificateKeyPair.private_key`, tokens, e similares ficam em Bitwarden Secret Manager e sao injetados via env vars ou mount de Kubernetes Secret. O blueprint referencia `managed:` para identificar o recurso sem incluir o material sensivel.
5. **Estrutura de pastas:**

   ```
   acdg/edge-cloud-infra/authentik/blueprints/
   ├── 00-baseline.yaml                  # estado inicial dos defaults
   ├── 10-acdg-roles-mapping.yaml        # property mapping de roles
   ├── 11-acdg-recovery-flow.yaml        # flow de password reset PT-BR
   ├── 20-rbac-people-context-svc.yaml   # role minima para M2M
   ├── 30-branding-acdg.yaml             # brand + custom CSS
   ├── 40-notification-mapping.yaml      # webhook payload estruturado
   └── README.md                          # como aplicar / como atualizar
   ```

   Prefixo numerico controla ordem de aplicacao quando ha dependencias.

6. **Workflow de mudanca:**

   ```
   1. Desenvolvedor edita YAML local + sobe stack local (docker compose)
   2. Validacao manual (UI + API call)
   3. PR no edge-cloud-infra/ com YAML + screenshot/descricao do efeito
   4. Code review por outro dev
   5. Merge dispara Flux CD que sincroniza blueprints/ no cluster
   6. Worker do Authentik aplica no proximo ciclo (~30s)
   ```

7. **Export periodico para reconciliar drift:**

   ```bash
   # Job semanal (CronJob ou manual)
   docker compose exec server ak export_blueprint > /tmp/current.yaml
   diff blueprints/00-baseline.yaml /tmp/current.yaml
   # Alerta se houver divergencia inesperada
   ```

## Consequencias

### Positivas

- **Configuracao como codigo de verdade** — `git log` mostra historico de mudancas no IdP, com autor + razao em commit messages.
- **Disaster recovery instantaneo** — instancia limpa + replay dos blueprints = estado conhecido. Postgres backup vira complemento (para historico de events + sessions), nao dependencia.
- **Drift detection automatico** — diff Postgres × blueprint vira health check.
- **Property mappings revisaveis** — Python que vai rodar no IdP passa pelo mesmo code review do TS/Swift/Dart.
- **Onboarding mais rapido** — novo dev sobe `auth-spike/authentik` + blueprints em <5min, com a config real.

### Negativas

- **Toolchain adicional** — `ak export_blueprint`, `ak apply_blueprint`, comparadores de YAML viram parte do workflow.
- **Curva de aprendizado** — YAML do Authentik tem schemas especificos por modelo (`authentik_core.user`, `authentik_flows.flowstagebinding`, etc.). Documentacao em https://docs.goauthentik.io/customize/blueprints/.
- **Conflitos de merge em PRs grandes** — YAML longo com 200+ entries pode gerar conflitos. Mitigacao: dividir em arquivos menores por dominio (ver estrutura proposta).
- **Sem rollback transacional** — se um blueprint quebrar metade de uma aplicacao, ja foi aplicada. Mitigacao: dry-run em staging antes de merge para main.

## Anti-patterns proibidos

- **Editar configuracao via UI em producao sem versionar depois.** Se for emergencia, criar issue + PR retroativo no prazo de 24h.
- **Property mapping com side effects** (chamadas HTTP, escrita em DB) — Python expressions devem ser puras. Side effects vao no `people-context` ou em Flow Stages dedicados (HTTP Stage, Email Stage).
- **Mistura de secret e config no mesmo blueprint** — separar arquivos. Secrets nunca em git.
- **Importar blueprint de fontes externas** sem revisar a expressao Python — codigo de terceiros rodando no IdP e risco de supply chain.

## Plano de implementacao

Detalhado em `acdg/auth-spike/notes/04-flow-engine.md` (Flow Engine + Property Mappings) e `acdg/auth-spike/authentik/seed/README.md` (workflow de export/import).

Estimativa: ~1 dia de setup inicial + ~0.5 dia por blueprint customizado escrito.

A baseline ja existe em `acdg/auth-spike/authentik/seed/00-baseline.yaml` (gerado no spike). Apos cutover, movido para `acdg/edge-cloud-infra/authentik/blueprints/`.
