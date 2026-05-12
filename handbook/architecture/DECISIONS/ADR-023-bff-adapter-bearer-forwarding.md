# ADR-023 — BFF HTTP Adapters: Bearer Forwarding Mandatório

**Status:** Accepted
**Date:** 2026-05-04
**Deciders:** Phase 6 Security Remediation (B5 ticket)
**Supersedes:** None
**Related:** ADR-011 (Auth roles + RBAC), ADR-012 (OIDC PKCE), ADR-022 (kernel/infra/apps layout)

---

## Contexto

A Phase 6 Security Audit (`handbook/archive/audit/2026-05-04-orchestrated/`) identificou que a documentação dos repositórios `acdg/` e `social-care/` afirmava ser obrigatório enviar o header `X-Actor-Id` em mutações HTTP — mas o backend Swift **não lê esse header**. A função canônica de extração de identidade do ator é:

```swift
// acdg/social-care/Sources/social-care-s/IO/HTTP/Extensions/Request+ActorId.swift:5-8
func extractActorId() throws -> String {
    let user = try requireAuthenticatedUser()
    return user.userId
}
```

`requireAuthenticatedUser()` lê o `AuthenticatedUser` injetado pelo `JWTAuthMiddleware`, que por sua vez extrai o `sub` claim do JWT validado:

```swift
// acdg/social-care/Sources/social-care-s/IO/HTTP/Middleware/JWTAuthMiddleware.swift:30-33
request.authenticatedUser = AuthenticatedUser(
    userId: payload.sub.value,
    roles: roles
)
```

A auditoria converge em três achados independentes:

- **A2 (Auth Audit, Phase 2.2)** — *No actor attribution end-to-end.* O BFF web nunca lê `Session.userId` nos handlers protegidos e os contratos não possuem parâmetro `actorId`.
- **Q9 (Threat Model, Phase 1)** — Cadeia de atribuição quebra no passo 3 (handler do BFF não lê `Session.userId`).
- **P0-2 (FINAL-REPORT)** — LGPD Art. 37 violado por ausência de atribuição por mutação.

A interpretação inicial do P0-2 foi "plumbar `actorId` através de cada método de contrato + enviar como `X-Actor-Id`". A revisão Q3 (com evidência do código backend) reformulou: o backend já deriva o `actorId` corretamente do JWT validado — o que falta é (a) o BFF encaminhar o `Authorization: Bearer` em **todos** os adapters HTTP outbound, e (b) corrigir a documentação que sugere o caminho errado.

## Decisão

**Todo adapter HTTP do BFF que faz chamadas outbound para o backend `social-care` (ou para qualquer downstream do ecossistema ACDG que use o mesmo `JWTAuthMiddleware`) DEVE encaminhar o header `Authorization: Bearer <jwt>` derivado do JWT recebido na requisição inbound.**

Regras concretas:

1. O Bearer encaminhado é **o mesmo JWT** recebido do caller (CLI, futura UI). Não é um token de service-account, não é um token reemitido pelo BFF, não é um override.
2. O encaminhamento DEVE acontecer em **toda chamada outbound**, não apenas em mutações — queries também são auditadas pelo backend (LGPD Art. 37 cobre operações de tratamento de dados, incluindo leitura de dados pessoais sensíveis).
3. O encaminhamento DEVE usar um `tokenProvider` (closure ou Dio interceptor) que **re-lê o token vivo a cada request** — tokens podem ter sido rotacionados pelo refresh-token-rotation flow entre dois requests.
4. Headers customizados como `X-Actor-Id` NÃO devem ser enviados. Se um adapter legado os envia, eles serão ignorados pelo backend — a remoção é cosmética, mas recomendada para evitar confusão futura.
5. NUNCA persistir o JWT em estruturas que o exponham além do escopo da requisição (logs, error breadcrumbs, cache) — cross-ref B4 (CLI keychain) + futuro ADR de log redaction.

### Implementação de referência

`apps/social_care_bff/contracts/lib/src/infrastructure/people_context_client.dart` — único adapter HTTP atualmente no monorepo. Trecho relevante:

```dart
// people_context_client.dart:11-44 (síntese)
PeopleContextClient({
  required String baseUrl,
  required String actorId,           // legado — será removido em PR seguinte
  String? accessToken,
  String Function()? tokenProvider,  // PADRÃO: closure re-lendo token vivo
  Dio? dio,
}) : _tokenProvider = tokenProvider,
     _dio = dio ?? Dio(BaseOptions(
       baseUrl: baseUrl,
       headers: {
         'Content-Type': 'application/json',
         if (accessToken != null) 'Authorization': 'Bearer $accessToken',
       },
     )) {
  if (_tokenProvider != null) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _tokenProvider();
        if (token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }
}
```

**Padrão a copiar**:
- Bearer header em `BaseOptions.headers` para fallback estático;
- `tokenProvider` opcional injetando token vivo via interceptor;
- O interceptor sobrescreve o header em **toda** request (lê o token a cada chamada).

**Anti-padrão presente em `PeopleContextClient` que NÃO deve ser perpetuado**: a constante `'X-Actor-Id': actorId` no construtor (linha 27 do arquivo). É legado deste período de drift documental e não tem efeito (o backend ignora). Será removido em ticket de housekeeping; novos adapters NÃO devem replicá-lo.

## Consequências

### Positivas

- **LGPD Art. 37 (registro de operações)** atendido: cada operação no backend tem `actorId` derivado de fonte criptograficamente validada (JWT assinado pelo Zitadel), persistido nos audit logs do social-care.
- **Modelo de confiança claro**: nenhum BFF pode forjar o `actorId` — ele é função do JWT. Mesmo BFF comprometido só consegue agir como o usuário cujo token detém.
- **Refresh rotation transparente**: `tokenProvider` re-lê a cada request; o adapter não precisa de lógica de retry-after-refresh (o interceptor de auth já existente cuida do 401-once-retry).
- **Surface de revisão estreita**: futuro adapter HTTP é trivialmente revisável — basta um `grep` por `'Authorization': 'Bearer'` no construtor + interceptor.

### Negativas / Custos

- **Acoplamento ao OIDC**: o BFF não pode chamar o backend social-care com identidade própria (sem JWT do usuário). Se um cron-job server-side dentro do BFF quiser chamar o backend, precisará de ADR de service-account flow (recordado em §Open questions).
- **Token vivo passa por mais hops**: o JWT é encaminhado em toda chamada outbound. Mitigação: TLS estrito (cross-ref §LGPD Art. 46) + token TTL curto (P1-2: 15min).
- **Adapters de queries também encaminham Bearer**: ligeira sobrecarga de header em GETs. Aceito — o custo é trivial (~600 bytes por request).

### Quebras se a regra for violada

| Violação | Consequência observável | Detecção |
|---|---|---|
| Adapter sem Bearer forwarding | Backend retorna 401 (`JWTAuthMiddleware` rejeita). Cadeia quebra cedo. | E2E test cai imediatamente. |
| Adapter envia Bearer estático (sem `tokenProvider`) | Após refresh-rotation, requests falham com 401 até reinício. | Spike de 401 nos dashboards. |
| Adapter envia `X-Actor-Id` ao invés de Bearer | Backend rejeita com 401 (sem JWT válido). | E2E test cai. |
| Adapter usa service-account token e override `actorId` | Backend usa o `sub` da service-account → audit row erroneamente atribuído à conta de serviço. **LGPD Art. 37 silenciosamente quebrado.** | Apenas via revisão manual ou audit interno. **Risco maior** — daí o presente ADR. |

## Alternativas consideradas

### Alternativa 1 — Plumbar `actorId` como parâmetro em todo método de contrato + enviar como `X-Actor-Id`

**Rejeitada.** Era a interpretação original do P0-2.

- O backend não lê `X-Actor-Id` (`Request+ActorId.swift` deriva de `JWT.sub`, sem referência a headers).
- Adicionar o parâmetro em ~17 métodos de contrato + plumbing handler→UseCase→contract = ~100+ LOC de surface change com **zero efeito funcional** no backend.
- Pior: ensina futuros engenheiros que `X-Actor-Id` é o contrato — não é. A drift documental se cristaliza em código.
- Pior ainda: cria uma fonte alternativa de "actor" que diverge do JWT.sub. Se um BFF mal configurado enviasse `X-Actor-Id: alice` mas o JWT fosse de `bob`, qual seria o ator? Hoje a resposta é "bob" (porque o backend ignora o header). Implementar a regra "use o header" introduz a possibilidade de impersonation lateral.

### Alternativa 2 — BFF usa service-account próprio + envia `X-Actor-Id` como override

**Rejeitada.** O `JWTAuthMiddleware:21-28` tem branch para service-accounts (`tokenIntrospector` + `allowedServiceAccounts`), mas mesmo nesse branch o `userId` é derivado do `sub` introspectado (não do header). Para implementar override seria necessário:

- Mudança no backend Swift (`Request+ActorId.swift` + `AuthenticatedUser`).
- Lista de allowlist de quais service-accounts podem fazer override.
- Audit-log que diferencia "agindo como" vs "agindo por si".
- Quebra do modelo: service-account compromisso = capacidade de impersonation total.

LGPD Art. 37 explicitamente requer identificação do **agente do tratamento** — uma service-account que age "em nome de" sem trilha clara é exatamente o padrão de audit-trail-laundering que o artigo combate.

### Alternativa 3 — Remover atribuição de ator do BFF e fazê-la apenas no backend a partir de cookie de sessão

**Rejeitada.** O backend social-care não recebe o cookie `__Host-session` do BFF (o BFF é o consumidor do cookie, não o emissor para o backend). O backend só vê o que o BFF envia outbound — atualmente Bearer JWT. Reescrever isso para enviar cookie de sessão = (a) viola separação de domínios (cookie é da DMZ do BFF), (b) backend teria que validar cookie, o que requer compartilhar `SESSION_SECRET` (uma das credenciais leakadas em P0-8).

### Alternativa 4 — Manter `X-Actor-Id` opcional como hint para logs do BFF

**Rejeitada como item de ADR**, mas registrada como possibilidade futura: o BFF pode escrever seu **próprio** log com `actor_id` derivado da `Session.userId` para correlação BFF↔backend. Isso é audit local do BFF, não substitui o do backend. Não exige header — o BFF lê do próprio session store. Out of scope para B5; pode virar item de observabilidade.

## Future enforcement (TODO — quando 1+ adapter HTTP novo aterrissar)

Adicionar contract test no padrão abaixo. Hoje só existe `PeopleContextClient`; quando o segundo adapter chegar, este teste passa a ser BLOCKING em CI:

```dart
// apps/social_care_bff/contracts/test/architecture/bearer_forwarding_test.dart (FUTURE)
//
// Garante que TODO arquivo em lib/src/infrastructure/*_client.dart contém:
//  1. Um construtor que aceita `String Function() tokenProvider` ou `String accessToken`.
//  2. Um interceptor (ou BaseOptions.headers) que seta `'Authorization': 'Bearer ...'`.
//
// Falhas comuns que este teste pega:
//  - Novo adapter sem auth header.
//  - Adapter usando token estático (sem tokenProvider) em ambiente que rotaciona.
//  - Adapter copiou o anti-padrão `X-Actor-Id` do PeopleContextClient legado.

import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('every HTTP adapter forwards Bearer (ADR-023)', () {
    final dir = Directory('lib/src/infrastructure');
    final adapters = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('_client.dart'));

    for (final f in adapters) {
      final src = f.readAsStringSync();
      expect(
        src.contains("'Authorization'") &&
            (src.contains("'Bearer ") || src.contains('"Bearer ')),
        isTrue,
        reason: 'Adapter ${f.path} does not forward Authorization: Bearer. '
            'See ADR-023 + people_context_client.dart for reference.',
      );
      expect(
        src.contains('tokenProvider') || src.contains('accessToken'),
        isTrue,
        reason: 'Adapter ${f.path} has no token injection point. '
            'See ADR-023 §Implementação de referência.',
      );
    }
  });
}
```

**Quando aplicar.** No PR que adiciona o segundo adapter HTTP. Recordado em TRACEABILITY.md como item futuro.

**Por que não criar agora.** Com apenas um adapter (que JÁ implementa o padrão), o teste nasceria sempre verde — false sense of security. Esperar até haver dois adapters garante que o teste seja escrito com base em diff real, não em hipóteses.

## Open questions

1. **Service-account flows.** Se um adapter HTTP do BFF precisar agir sem identidade de usuário (cron, sync de catálogo, health probe outbound), qual o padrão? **Não decidido em ADR-023**; quando o caso surgir, abrir ADR-024 com base no branch `tokenIntrospector + allowedServiceAccounts` já existente em `JWTAuthMiddleware.swift:21-28`.
2. **Cookie-to-Bearer bridge.** Se uma futura UI Flutter web usar cookies de sessão BFF (não Bearer direto), o BFF web já tem o pattern correto: ler `Session.accessToken` e usá-lo como Bearer outbound. Não há decisão pendente — apenas garantir que adapters não desviem desse pattern.
3. **Token introspection no BFF.** Hoje o BFF não introspecciona o JWT (só o backend faz). Se algum dia for necessário (e.g. enforcement de scope no BFF), abrir ADR separado — não é parte de B5.

## LGPD mapping

| Artigo | Controle | Aderência via ADR-023 |
|---|---|---|
| Art. 37 (registro de operações) | `actorId` derivado de fonte tamper-evident em toda mutação | **Atendido**: Bearer forwarding → JWT.sub → `actorId` persistido pelo backend. |
| Art. 46 (medidas técnicas) | TLS em trânsito + token at-rest hardened | **Pré-requisito**: ADR-023 ASSUME TLS no canal BFF↔backend e at-rest hardening do JWT (cross-ref B4 — CLI keychain migration). NÃO substitui esses controles. |
| Art. 50 (boas práticas e governança) | ADR público + reference impl + future test scaffold | **Atendido**: este ADR + `PeopleContextClient` + TODO contract test. |

## Riscos não cobertos por este ADR

- **Backend Swift compromise.** Se o backend social-care for comprometido, o atacante reconfigura `Request+ActorId.swift` e pode forjar `actorId` arbitrário. Mitigação: hardening de infra, não de código (Phase 6 fora de escopo).
- **Zitadel compromise.** Se o IdP emitir JWTs com `sub` falso, todo o modelo cai. Mitigação: chaveamento Zitadel + monitoração — fora de escopo.
- **Service-account impersonation lateral.** Se uma service-account for adicionada ao `allowedServiceAccounts` sem audit, ela pode chamar o backend e produzir audit rows com `sub` da service-account. Mitigação: governança de allowlist (operacional, fora de escopo de código).
- **Admin impersonation paths.** Casos de uso "agir como X" (e.g. suporte logado emulando paciente) NÃO são modelados. Quando surgirem, abrir ADR específico com fluxo de "actor + on-behalf-of-actor" auditável.
- **Plumbing do `X-Actor-Id` legado em `PeopleContextClient`**. Não é risco de segurança (header é ignorado), mas é tech debt. Housekeeping ticket separado.

## Referências

- **Audit findings**: `handbook/archive/audit/2026-05-04-orchestrated/03-auth-audit/REPORT.md` §A2 + §Q9
- **Final report**: `handbook/archive/audit/2026-05-04-orchestrated/FINAL-REPORT.md` §P0-2 (redefinido por este ADR)
- **Reference impl**: `apps/social_care_bff/contracts/lib/src/infrastructure/people_context_client.dart`
- **Backend impl**: `acdg/social-care/Sources/social-care-s/IO/HTTP/Extensions/Request+ActorId.swift`
- **Backend impl**: `acdg/social-care/Sources/social-care-s/IO/HTTP/Middleware/JWTAuthMiddleware.swift`
- **OAuth 2.0 RFC 6750** (Bearer token usage)
- **LGPD Art. 37, 46, 50** (Lei 13.709/2018)
- **OWASP ASVS L2** §4.2.1 (logical access controls), §3.6 (OIDC)
