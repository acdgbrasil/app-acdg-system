# ADR-031 — Migracao de identidade preserva ADR-023 via `legacy_sub` attribute

**Status:** Proposed
**Date:** 2026-05-13
**Deciders:** Authentik Evaluation Spike (`acdg/auth-spike/REPORT.md`)
**Related:** [ADR-023](ADR-023-bff-adapter-bearer-forwarding.md), [ADR-027](ADR-027-authentik-replaces-zitadel.md), [ADR-028](ADR-028-oidc-discovery-source-of-truth.md)

---

## Contexto

[ADR-023](ADR-023-bff-adapter-bearer-forwarding.md) estabelece que o `actorId` do audit trail e derivado do `sub` claim do JWT validado:

```swift
// acdg/social-care/Sources/social-care-s/IO/HTTP/Middleware/JWTAuthMiddleware.swift:30-33
request.authenticatedUser = AuthenticatedUser(
    userId: payload.sub.value,
    roles: roles
)

// acdg/social-care/Sources/social-care-s/IO/HTTP/Extensions/Request+ActorId.swift:5-8
func extractActorId() throws -> String {
    let user = try requireAuthenticatedUser()
    return user.userId
}
```

A migracao Zitadel → Authentik ([ADR-027](ADR-027-authentik-replaces-zitadel.md)) introduz uma quebra de formato:

| IdP        | Formato do `sub`                                                       |
|------------|------------------------------------------------------------------------|
| Zitadel    | Snowflake numerico — `"270366461930766336"`                            |
| Authentik  | Hash hex64 (`hashed_user_id`) — `"fe025d9c8429d445f0d18e2380c17ec51a1921e9197c623a7c5b14b015fcac77"` |

Se nao tratada, essa quebra significa:

- **Descontinuidade de audit trail.** Eventos antigos referenciam `actorId="270366461930766336"`. Eventos novos referenciam `actorId="fe025d9c..."`. Nao ha forma trivial de saber que ambos sao o mesmo Joao Silva.
- **Falha de queries por usuario** em dashboards, relatorios LGPD, etc.
- **Quebra de FKs em tabelas de dominio** que armazenam `created_by` / `updated_by` apontando para o `sub` antigo.

Tres alternativas foram avaliadas no spike:

1. **Mapear `sub` antigo no `social-care` via tabela de correlacao** — exige tabela nova + middleware adicional + risco de race conditions.
2. **Forcar Authentik a emitir o `sub` antigo via Property Mapping `sub_mode=hashed_user_id` substituido** — possivel mas Authentik nao garante imutabilidade do `sub` se a configuracao mudar.
3. **Authentik emite seu `sub` proprio + claim adicional `legacy_sub`** — preserva o `sub` autoritativo do IdP novo, e o consumer (`social-care`) cuida da correlacao quando necessario.

A alternativa 3 e a recomendada — `sub` continua sendo o identificador autoritativo do IdP corrente; `legacy_sub` e uma claim adicional **temporaria** (presente apenas durante a janela de migracao) que carrega o `sub` Zitadel original.

## Decisao

**Durante a janela de migracao (Sprint 3-6 do plano em [ADR-027](ADR-027-authentik-replaces-zitadel.md)), o Authentik emite no JWT um claim adicional `legacy_sub` contendo o `sub` Zitadel original. ADR-023 e mantido sem alteracao.**

Regras concretas:

1. **Authentik user.attributes recebe `legacy_zitadel_sub`** durante o script de import (`acdg/people-context/scripts/migrate-users.ts`):

   ```typescript
   await authentik.createUser({
     username: zUser.preferredUsername,
     email:    zUser.email.email,
     attributes: {
       cpf:                  zUser.metadata.find(m => m.key === 'cpf')?.value,
       person_id:            zUser.metadata.find(m => m.key === 'person_id')?.value,
       org_id:               'acdg-default',
       legacy_zitadel_sub:   zUser.userId,             // ← CRITICO
       settings:             { locale: 'pt-BR' },
     },
   });
   ```

2. **Property Mapping `acdg-roles`** (criada via blueprint conforme [ADR-029](ADR-029-authentik-blueprints-versioned.md)) inclui o claim no JWT:

   ```python
   return {
       "roles":      [g.name for g in user.ak_groups.all()],
       "org_id":     user.attributes.get("org_id", "acdg-default"),
       "person_id":  user.attributes.get("person_id"),
       "legacy_sub": user.attributes.get("legacy_zitadel_sub"),
   }
   ```

3. **`social-care` aceita multi-issuer JWKS** durante Sprint 3-4 (parallel run):

   ```swift
   // configure.swift (proposta)
   let issuers = config.oidcIssuers   // ["https://auth.acdgbrasil.com.br/", "http://authentik:9000/application/o/social-care/"]
   for issuer in issuers {
       let jwks = try await fetchJWKS(from: issuer)
       app.jwt.signers.use(jwks: jwks)
   }
   ```

4. **`OIDCJWTPayload.swift`** (substitui `ZitadelJWTPayload.swift`) le `legacy_sub` como opcional:

   ```swift
   struct OIDCJWTPayload: JWTPayload {
       let sub:       String
       let email:     String?
       let roles:     [String]
       let orgId:     String?
       let personId:  String?
       let legacySub: String?      // None em produdor exclusivo Authentik pos-cleanup
   }
   ```

5. **`Request+ActorId.swift` mantem a contratacao do ADR-023:**

   ```swift
   func extractActorId() throws -> String {
       let user = try requireAuthenticatedUser()
       return user.userId                  // <- continua sendo payload.sub
   }
   ```

   **Nao usar `legacy_sub` como `actorId`.** O `sub` autoritativo e sempre o `sub` do IdP corrente. `legacy_sub` e metadado de correlacao para queries historicas.

6. **Audit trail novo** (eventos gerados pos-cutover) registra **ambos**:

   ```typescript
   // people-context outbox event
   {
     event:        "person.role.assigned",
     actor_sub:    "fe025d9c..."             // sub Authentik = actorId
     actor_legacy: "270366461930766336"      // sub Zitadel, se presente
     // ...
   }
   ```

7. **Limpeza pos-cutover (Sprint 6):**

   - Remover `legacy_zitadel_sub` de `user.attributes` (script idempotente).
   - Remover claim `legacy_sub` da Property Mapping `acdg-roles`.
   - Remover `legacySub` de `OIDCJWTPayload.swift`.
   - Manter colunas `actor_legacy` em audit tables como metadado historico (read-only, nunca apagado por LGPD Art. 16 — direito a rastreabilidade).

## Consequencias

### Positivas

- **ADR-023 preservado sem mudanca.** `extractActorId()` continua igual; `JWTAuthMiddleware` continua igual.
- **Audit trail correlacionavel.** Queries por `actor_legacy` recuperam historico Zitadel; queries por `actor_sub` recuperam eventos Authentik. Joins explicitos quando necessario.
- **Cutover reversivel.** Se algo der errado no Sprint 5, voltar para Zitadel exige apenas desativar feature flag — `legacy_zitadel_sub` ainda esta no Authentik para identificar o usuario.
- **Sem schema nova de DB.** A coluna `actor_legacy` reusa o mesmo tipo (`text`) do `actor_sub`.

### Negativas

- **Janela temporaria** com 2 claims duplicados — codigo no `social-care` que le `legacySub` precisa de comentario `// TODO: remover apos ADR-031 cleanup (Sprint 6)`.
- **Property mapping carrega valor que pode ser `null`** — handlers downstream precisam tolerar.
- **Audit tables tem coluna `actor_legacy` que so faz sentido para users migrados** — users criados ja no Authentik tem `actor_legacy = NULL`. Aceitavel.

## Casos especiais

| Cenario                                              | Comportamento                                                          |
|------------------------------------------------------|-------------------------------------------------------------------------|
| User criado **ANTES** da migracao                    | `legacy_sub` presente. Audit trail correlacionavel.                    |
| User criado **APOS** o cutover                       | `legacy_sub` ausente / null. Audit trail so usa `sub` Authentik.       |
| User existia no Zitadel e foi deletado pre-migracao  | Nao migrado. Audit antigo referencia `sub` Zitadel orfao. Aceitavel.   |
| Service account                                      | `legacy_sub` ausente — service accounts sao criados de novo no Authentik (Task #7 do spike). |
| Migracao de pacientes (entidades de dominio)         | Nao afetado — pacientes nao tem `sub` JWT. Apenas usuarios do sistema. |

## Plano de implementacao

Detalhado em `acdg/auth-spike/notes/11-user-migration.md` (4 fases) e `acdg/auth-spike/notes/03-management-api.md` (shape do `createUser`).

Componentes:

| Componente                                                                          | Esforco |
|-------------------------------------------------------------------------------------|---------|
| Script `migrate-users.ts` com dry-run + reconciliation                              | 2d      |
| Multi-issuer JWKS no `social-care` (parallel run window)                            | 1d      |
| Property mapping `acdg-roles` versionada em blueprint                               | 0.5d    |
| `OIDCJWTPayload.swift` com `legacySub` opcional                                     | 0.5d    |
| Audit tables: coluna `actor_legacy` (migration idempotente)                         | 0.5d    |
| Recovery automatico no primeiro login pos-migracao                                  | 1d      |
| Cleanup Sprint 6 (drop coluna `legacy_zitadel_sub`, claim, codigo)                  | 1d      |
| **Total**                                                                            | **~6d** |

(Sprint 3 do plano em [ADR-027](ADR-027-authentik-replaces-zitadel.md)).
