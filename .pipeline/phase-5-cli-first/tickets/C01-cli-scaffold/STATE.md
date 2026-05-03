# Ticket State: C01-cli-scaffold

phase: done
status: closed 2026-05-02

## Outcome
- 4-wave pipeline executada sem rejection (W0 → W0.5 → W1 → W2 → W3)
- 77 RED tests → 77 GREEN no novo `apps/cli/`
- 2249 GREEN +1 skip total (4 packages: 535 contracts + 1137 web + 500 desktop + 77 cli)
- dart analyze zero issues, format clean
- AOT compile produz binário `acdg` funcional
- Cross-package non-regression preserved

## Padrões aplicados
- Facade (CliRunner)
- Strategy (OutputFormatter + 4 impls + auto-resolver)
- Sealed Class (CliError + 4 final variants, P5 enforce)
- Factory Method (Credentials.fromJson, FileCredentialStore.defaultPath)
- Adapter (BffClient)
- Result<T> end-to-end

## Decisões consolidadas (D1-D5)
- D1: package name `cli`
- D2: workspace global
- D3: binário `acdg`
- D4: auto-detect (tty=table, pipe=json)
- D5: XDG path `~/.config/acdg/credentials` chmod 600

## Stubs por command (mapping pra futuros tickets)
- AuthCommand → C02 (OIDC PKCE)
- PatientCommand → C03
- FamilyCommand → C04
- AssessmentCommand → C05
- CareCommand → C06
- ProtectionCommand → C07
- LookupCommand → C08
- TeamCommand → C09
- HealthCommand → no dedicated ticket

## SHOULD_FIX deferidos a C02 (3 itens, mesmo root cause)
- TypeError pode escapar boundaries (CliRunner.run, Credentials.fromJson, BffClient.get<T>)
- Não bloqueante no scaffold; endereçar antes de C02 shipping PKCE persistence

## Next
**C02 — CLI Auth (PKCE Loopback)** — depende de NATIVE_API client_id no Bitwarden (pendência infra)
