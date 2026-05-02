# C08 — CLI Lookup Commands

## Onda: 4 | Profile: feature | Depende de: C07

## Escopo

8 endpoints lookup + 1 batch:

```bash
# Read
acdg lookup get <table-name>                        # 1 tabela
acdg lookup batch <a,b,c,...>                       # múltiplas (A14 endpoint composto)

# Admin (write)
acdg lookup create <table-name> --code=X --label=Y
acdg lookup update <table-name> <id> [--code=X] [--label=Y] [--active=true]
acdg lookup toggle <table-name> <id>                # active flip

# Approval workflow
acdg lookup requests list
acdg lookup request create <table-name> --code=X --label=Y --justificativa=Z
acdg lookup request approve <id>
acdg lookup request reject <id> [--reason=X]
```

### Sub-contracts BFF consumidos
- `LookupContract` (getLookupTable, getLookupsBatch, createItem, updateItem, toggleItem, getRequests, createRequest, approveRequest, rejectRequest)

### Detalhes

- **batch** valida cap 20 tabelas (A14 spec) client-side antes de enviar.
- **toggle** é PATCH (não PUT) — semantically idempotent flip.
- **request create** captura `justificativa` (PII-safe — BFF sanitizes em error responses).

## Pipeline

W0 → W1 → W2 → W3

## Critérios

- [ ] 9 comandos funcionais
- [ ] Batch CSV parsing (split→trim→filter alinhado com BFF A14)
- [ ] `dart analyze` zero issues

## Status
pending — blocked by C07
