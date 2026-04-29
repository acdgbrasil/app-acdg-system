# A05 — Delete SocialCareContract god-interface

## Onda: 2 | Profile: bff/shared | Depende de: A04

## Escopo
**Deletar** `bff/shared/lib/src/contract/social_care_contract.dart` (god-interface de 30+ métodos).

Todos os consumidores passam a depender apenas dos sub-contracts (Contract B) criados em A04.

## Critérios
- [ ] Arquivo `social_care_contract.dart` deletado
- [ ] Zero referências a `SocialCareContract` em todo o `bff/`
- [ ] Consumidores (Web + Desktop) compilam (mesmo que seja com adaptação em A07+ e A16+)
- [ ] `dart analyze bff/shared` verde

## Não faça
- Não delete `FakeSocialCareBff` ainda (A06 o substitui por fakes por contrato)

## Status
pending — blocked by A04
