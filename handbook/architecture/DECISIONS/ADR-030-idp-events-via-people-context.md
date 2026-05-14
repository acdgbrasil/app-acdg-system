# ADR-030 — Eventos de identidade publicados pelo `people-context`, nao por webhook do IdP

**Status:** Proposed
**Date:** 2026-05-13
**Deciders:** Authentik Evaluation Spike (`acdg/auth-spike/REPORT.md`)
**Related:** [ADR-027](ADR-027-authentik-replaces-zitadel.md), [ADR-029](ADR-029-authentik-blueprints-versioned.md)

---

## Contexto

Hoje o `acdg/people-context/` chama a Management API do Zitadel via `src/zitadel/client.ts` e publica eventos de dominio (`person.created`, `role.assigned`, `password.reset.requested`) no NATS JetStream via Transactional Outbox em `src/events/publisher.ts`. Outros consumidores (`social-care` para denormalization, futuro `queue-manager` para email, `analysis-bi` para dashboards) leem do NATS.

Authentik oferece **Notification Rules + Webhook Transports** como mecanismo nativo de eventos para sistemas externos. Validado no spike (`acdg/auth-spike/notes/08-webhooks.md`):

- **Webhook funciona** — Authentik dispara HTTP POST quando policy + rule + transport casam.
- Mas o **payload default e POBRE**:

  ```json
  {
    "body": "model_created: {'model': {'pk': '...', 'app': 'authentik_core', 'name': 'joao.silva', 'model_name': 'user'}, 'http_request': {...}}",
    "severity": "notice",
    "user_email": "admin@acdg.local",
    "user_username": "akadmin",
    ...
  }
  ```

  O `body` e uma **string Python `repr()` do context** — nao JSON estruturado. Aspas simples, sem escape consistente, datas em formato Python. Parse fragil.

- **NotificationWebhookMapping (property mapping)** permite customizar o payload via Python expression, mas isso significa **mais codigo Python no IdP** — anti-pattern proibido por [ADR-029](ADR-029-authentik-blueprints-versioned.md) sem PR review.

- **Sem retry / ack** — se o consumer estiver down quando o evento dispara, e perdido. Authentik nao tem dead-letter queue para webhooks.

- **Action granularity baixa** — `model_created`, `model_updated`, `model_deleted` cobrem QUALQUER entidade (user, group, application, policy, etc.). Consumer teria que rotear por `model.app + model.model_name`.

Em contraste, o `people-context` ja tem:

- **Transactional Outbox** em `src/events/publisher.ts` que **garante consistencia** entre Postgres state e NATS publish (mesma transacao DB).
- **Retry com backoff** via `OutboxRelay` em background.
- **Eventos de dominio bem nomeados** (`person.created`, nao `model_created`).
- **JSON estruturado** com schema controlado pelo proprio `people-context`.

## Decisao

**Eventos de identidade no ecossistema ACDG sao publicados pelo `people-context` via Outbox + NATS, e nao consumidos diretamente do webhook do Authentik.**

Regras concretas:

1. **Toda chamada do `people-context` a Management API do Authentik que muda estado** (createUser, addToGroup, recovery, etc.) e seguida de um `insert` na tabela `outbox` na mesma transacao DB. O `OutboxRelay` publica no NATS apos commit.
2. **Webhook do Authentik nao e fonte primaria.** Consumidores de identidade (`social-care`, `queue-manager`, `analysis-bi`) ouvem APENAS os subjects NATS publicados pelo `people-context`.
3. **Excecao: eventos iniciados FORA do BFF** — quando o user passa por um Authentik Flow sem mediacao do `people-context` (ex: self-service password reset, backchannel logout), o webhook e necessario. Para esses casos:
   - Configurar `NotificationTransport` (mode=webhook) apontando para `POST /api/v1/internal/authentik-webhook` no `people-context`.
   - Endpoint protegido por **shared-secret header** (`X-Webhook-Secret`, comparacao constant-time).
   - Endpoint apenas **traduz** o payload Authentik para evento de dominio e insere no Outbox — nao executa logica de negocio.
4. **NotificationWebhookMapping para o payload estruturado** — quando webhook for usado, configurar mapping em blueprint (ADR-029) que devolve JSON com schema controlado:

   ```python
   return {
       "action":         notification.event.action,
       "event_id":       str(notification.event.pk),
       "created":        notification.event.created.isoformat(),
       "actor_username": (notification.event.user or {}).get("username"),
       "client_ip":      notification.event.client_ip,
       "model":          notification.event.context.get("model"),
   }
   ```

5. **Backchannel logout (`backchannel_logout_supported: true` no discovery do Authentik) E uma excecao valida** — o BFF Dart implementa o endpoint conforme spec OIDC. Nao depende do `people-context`.

### Arquitetura

```
   Cliente (BFF Dart, CLI)
        │
        ▼
   people-context (Elysia/TS)
        │
        ├── 1. Authentik Management API (createUser, addToGroup, ...)
        ├── 2. PERSISTE em Postgres local
        ├── 3. INSERE no Outbox (mesma transacao)
        │
        └── OutboxRelay → NATS JetStream
                              │
                              ├── social-care (denormalization)
                              ├── queue-manager (email PT-BR)
                              └── analysis-bi (dashboards)

   Excecao (self-service Authentik flow):
   Authentik Flow → webhook → people-context /api/v1/internal/authentik-webhook
                                   ↓
                              Outbox → NATS (mesmo path)
```

## Consequencias

### Positivas

- **Reuso da infraestrutura existente** — Outbox, NATS, consumers ja funcionam para Zitadel hoje. Migracao para Authentik nao quebra o pipeline.
- **Eventos de dominio com schema controlado** — `person.created` em vez de `model_created`. Versionamento controlado pelo ACDG.
- **Garantia de entrega** — Outbox + NATS JetStream sao mais robustos que webhook one-shot.
- **Authentik fica desacoplado** dos consumers — substituir Authentik por outro IdP no futuro nao quebra `social-care`/`queue-manager`/`analysis-bi`.
- **Audit trail consistente** — `legacy_sub` (de [ADR-031](ADR-031-identity-migration-legacy-sub.md)) entra nos eventos do Outbox preservando correlacao.

### Negativas

- **Webhook do Authentik subutilizado** — usado so para o endpoint `/api/v1/internal/authentik-webhook`. Aceitavel, dado que e fallback.
- **Risco de skew** entre estado Authentik e Postgres local do `people-context` se ocorrer falha entre a Management API call e o `OutboxRelay` publish. Mitigacao: transacao DB envolve ambos os inserts (Postgres state + outbox). Falha de NATS publish nao bloqueia commit — outbox tem retry.
- **Endpoint interno do `people-context`** vira surface de ataque adicional. Mitigacao: shared-secret + IP allowlist no Kubernetes NetworkPolicy.

## Plano de implementacao

Detalhado em `acdg/auth-spike/notes/08-webhooks.md`.

Componentes a criar:

| Componente                                                                                  | Esforco |
|---------------------------------------------------------------------------------------------|---------|
| Endpoint `POST /api/v1/internal/authentik-webhook` em `people-context`                      | 0.5d    |
| Shared-secret + verificacao HMAC constant-time                                              | 0.25d   |
| `NotificationWebhookMapping` blueprint para payload estruturado                             | 0.5d    |
| Backchannel logout endpoint no BFF Dart (spec OIDC)                                         | 0.5d    |
| **Total**                                                                                    | **~1.75d** |

(Incluso no plano de [ADR-027](ADR-027-authentik-replaces-zitadel.md)).
