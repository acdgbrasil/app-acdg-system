# Ticket State: C00-bearer-middleware

phase: done
status: closed 2026-05-02

## Outcome
- 5-wave pipeline executada (W0 → W0.5 → W0-bis → W0.5b → W1 R1 → W2 R1 → W1 R2 → W2 R2 → W3)
- 9 dispatches de agente; 2 rounds de rejection produtivos (W0.5 e W2 R1)
- 62 tests GREEN no BFF Web (54 originais + 7 fechando gaps W0.5 + 1 regression case-insensitive cookie)
- 2098 GREEN total no BFF (preservou 535 contracts + 426 desktop +1 skip; 1075 prior web + 62 C00 = 1137 web)
- dart analyze zero issues em src/+bin/; format clean

## Security findings caught durante o pipeline
- **W0.5 — 3 MUST_FIX**: HMAC session id não testado, jti path untested, pointycastle dev_dep
- **W2 R1 — 1 MUST_FIX**: case-sensitive cookie strip permitia bypass (atacante enviando `COOKIE: __session=stolen` sob casing não-canônico). Fix: `headersAll` enumeration com `key.toLowerCase()`.

## Pré-requisitos de infra ainda pendentes
- 🟡 Provisionar `OIDC_CLI_CLIENT_ID` no Bitwarden Secret Manager (DEV/STG/PROD)
- 🟡 Quando UI Flutter (Phase 6+) ressuscitar, decidir audience comum vs separadas

## Next
C01 — CLI Scaffold (`apps/cli/`)
