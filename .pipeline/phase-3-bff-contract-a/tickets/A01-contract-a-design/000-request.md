# A01 — Contract A Design (ponto de vista do APP)

## Onda: 1 | Profile: design-only (pesquisa + documento)
## Depende de: — (ticket-raiz)

## Objetivo
Produzir o **documento definitivo do Contract A** — a lista completa de operações que o APP (Flutter Web + Desktop) precisa que o BFF entregue.

## Perspectiva
A pergunta é **"o que o APP precisa?"**, NÃO "o que o backend tem". Tudo que o usuário faz no app deve ser **1 ação = 1 endpoint = 1 payload**.

Se algo hoje exige múltiplas chamadas do cliente, passa a ser 1 chamada no Contract A. O BFF orquestra internamente.

## Método
1. **Varrer `packages/social_care/lib/src/ui/`** — todas as páginas, wizards, modais, ações.
2. **Para cada ação do usuário**, extrair:
   - Nome da ação (verb + entity)
   - Dados que o usuário fornece (payload)
   - Dados que o app espera de volta (response)
   - Efeitos internos (o que precisa acontecer nos microserviços)
3. **Varrer `packages/people_admin/lib/src/ui/`** — se houver ações distintas.
4. **Varrer handlers existentes em `bff/social_care_web/lib/src/handlers/`** para cruzar inventário.
5. **Identificar vazamentos**: endpoints que hoje expõem topologia (`/people/*`, etc.)
6. **Identificar gaps**: ações que o APP faz hoje em múltiplas chamadas e deveriam ser 1.
7. **Identificar backend gaps**: ações que o backend Swift não suporta — listar como "backend requests" que a fase pode incluir.

## Entregáveis

### 1. Documento canonical
Criar `handbook/architecture/CONTRACT_A_SPEC.md` com:

#### Seção A — Tabela de ações
Para cada ação do APP:
| # | Ação | Endpoint Contract A | Payload | Response | Orquestração interna | Status backend |
|---|------|---------------------|---------|----------|---------------------|----------------|
| 1 | Registrar paciente | POST /api/patients | PatientRegisterPayload | {patientId} | PeopleContext×N + SocialCare×3 | ok |
| 2 | Listar pacientes | GET /api/patients?... | — | List<PatientSummary> | SocialCare + PeopleContext (enrichment) | ok |
| ... | | | | | | |

#### Seção B — Endpoints compostos
Endpoints que consolidam operações hoje separadas:
- `GET /api/lookups?tables=...` — 1 request, várias tabelas
- `POST /api/patients` — registro com família, intake, social identity em 1 payload
- `GET /api/patients/:id` — aggregate completo (enriched com People Context)
- etc.

#### Seção C — Endpoints removidos
Rotas atuais que **não existirão** no Contract A:
- `/api/people/by-cpf/*` — vaza topologia (deletar)
- `/api/team/people/*` — idem (consolidar em `/api/team/*`)
- outros descobertos na análise

#### Seção D — Backend requests
Features que o backend Swift precisa criar/ajustar para o BFF atender Contract A:
| # | Feature | Por quê | Prioridade |
|---|---------|---------|-----------|
| 1 | `GET /patients/search?cpf=...` | Para validação de duplicidade em registro | alta |
| ... | | | |

(Se vazio, ótimo — BFF resolve tudo.)

#### Seção E — Agrupamento por sub-contract
Cada ação é mapeada para um sub-contract interno (Contract B):
- RegistryContract — patient, family, social-identity, lifecycle
- AssessmentContract — 7 fichas
- CareContract — appointment, intake
- ProtectionContract — violation, referral, placement
- LookupContract — lookups + requests
- TeamContract — professionals + roles
- AuthContract — OIDC session

### 2. REPORT.md no ticket
Em `.pipeline/phase-3-bff-contract-a/tickets/A01-contract-a-design/REPORT.md`:
- Status: COMPLETED
- Summary (o que foi feito)
- Métricas: total de ações mapeadas, endpoints compostos identificados, rotas deletadas, backend requests
- Arquivos produzidos (link para `handbook/architecture/CONTRACT_A_SPEC.md`)
- Notes for next agents (A02–A15)
- Blockers

## Critérios de aceitação
- [ ] `CONTRACT_A_SPEC.md` criado com pelo menos 25 ações mapeadas (todos os wizards, fichas, CRUDs).
- [ ] Seção "Endpoints removidos" lista `/people/by-cpf/*` e `/team/people/*` entre outros.
- [ ] Seção "Backend requests" preenchida (ou confirmada vazia com justificativa).
- [ ] Cada ação tem sub-contract definido (RegistryContract, AssessmentContract, etc.).
- [ ] REPORT.md linka para o doc.

## Não faça
- **Nada de código.** A01 é puro desenho.
- Não mexa em `bff/` ainda — A02+ fazem.
- Não altere `CONTRACT_A_PUBLIC_API.md` anterior — ele é o racional. O SPEC é a tabela.

## Tempo estimado
1 sessão (2-3 h). Pode ser mais se o Flutter tiver muitas features escondidas.
