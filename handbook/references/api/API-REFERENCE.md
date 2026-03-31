# API Reference — Social Care

Documentacao de referencia para consumo da API Social Care pelo frontend.

Fonte de verdade: codigo Swift em `social-care/Sources/social-care-s/IO/HTTP/`.

---

## Base URLs

| Ambiente | URL |
|----------|-----|
| Producao | `https://social-care.acdgbrasil.com.br` |
| Homologacao | `https://social-care-hml.acdgbrasil.com.br` |
| Local | `http://localhost:3000` |

---

## Autenticacao

Todos os endpoints protegidos exigem:

- **Header:** `Authorization: Bearer <JWT_TOKEN>`
- **JWT** validado contra JWKS: `https://auth.acdgbrasil.com.br/oauth/v2/keys`
- **Issuer:** `https://auth.acdgbrasil.com.br`
- **Token Endpoint:** `https://auth.acdgbrasil.com.br/oauth/v2/token`
- **Audience scope obrigatorio:** `urn:zitadel:iam:org:project:id:363109883022671995:aud` (sem ele o backend retorna 401)
- **Roles** extraidas do claim `urn:zitadel:iam:org:project:roles`

Para operacoes de escrita (POST/PUT/DELETE), o header **`X-Actor-Id`** e obrigatorio (ID do usuario autenticado, usado para auditoria).

### Roles

| Role | Permissao |
|------|-----------|
| `social_worker` | Leitura e escrita completa |
| `owner` | Somente leitura (pacientes e dominios) |
| `admin` | Leitura completa + gestao |

---

## Formato de Resposta Padrao

Todas as respostas (exceto 204 e Health) seguem o envelope `StandardResponse<T>`:

```json
{
  "data": { ... },
  "meta": {
    "timestamp": "2026-03-19T10:30:00Z"
  }
}
```

---

## Formato de Erro Padrao

```json
{
  "error": {
    "code": "PAT-001",
    "message": "Mensagem legivel para o usuario"
  }
}
```

Em ambiente HML (com `VERBOSE_ERRORS=true`), inclui campo extra:

```json
{
  "error": {
    "code": "REGP-024",
    "message": "Falha de infraestrutura...",
    "details": "issues: [\"Erro real do Postgres aqui\"]"
  }
}
```

**Header de versao:** Toda resposta inclui `X-Build-Version` (sha do commit ou `dev`).

### Codigos de Erro (prefixos)

| Prefixo | Modulo |
|---------|--------|
| `PAT-` | Patient (registro) |
| `PAI-` | PatientId |
| `SES-` | SocioEconomicSituation |
| `DIA-` | Diagnosis |
| `RGD-` | RG Document |
| `RI-` | Referral |
| `HTTP-` | Erros HTTP genericos (ex: `HTTP-422`) |
| `SYS-500` | Erro interno nao tratado |

### Status HTTP

| Status | Significado |
|--------|-------------|
| `200` | GET bem-sucedido |
| `201` | POST criou recurso (retorna `IdResponse`) |
| `204` | PUT/DELETE bem-sucedido (sem body) |
| `400` | Request invalido (JSON malformado, path param invalido) |
| `401` | JWT ausente ou invalido |
| `403` | Role insuficiente |
| `404` | Recurso nao encontrado |
| `422` | Violacao de regra de negocio |
| `500` | Erro interno |
| `503` | Banco indisponivel |

---

## Notas de Integracao

### Datas (ISO8601 completo)

Todas as datas devem ser enviadas no formato **ISO8601 completo**: `YYYY-MM-DDTHH:mm:ss.SSSZ`.

Formatos curtos como `YYYY-MM-DD` resultam em **400 Bad Request**.

### Enums em Portugues

- **sex:** `"masculino"` ou `"feminino"` (minusculo)
- **residenceLocation:** `"URBANO"` ou `"RURAL"` (UPPERCASE)

### Arrays JSON (JSONB)

Campos JSONB (ex: `requiredDocuments`) devem ser arrays JSON reais:
- Correto: `"requiredDocuments": ["CPF"]`
- Incorreto: `"requiredDocuments": "[\"CPF\"]"`

### Content-Type

- **Input:** `Content-Type: application/json`
- **Output:** `Content-Type: application/json`

---

## Tabela Resumo — Todos os Endpoints

| # | Metodo | Path | Role | Retorno |
|---|--------|------|------|---------|
| 1 | `GET` | `/health` | Nenhuma | `200 OK` |
| 2 | `GET` | `/ready` | Nenhuma | `ReadinessResponse` |
| 3 | `POST` | `/api/v1/patients` | `social_worker` | `201` + `IdResponse` |
| 4 | `GET` | `/api/v1/patients/{patientId}` | `social_worker` \| `owner` \| `admin` | `PatientResponse` |
| 5 | `GET` | `/api/v1/patients/by-person/{personId}` | `social_worker` \| `owner` \| `admin` | `PatientResponse` |
| 6 | `GET` | `/api/v1/patients/{patientId}/audit-trail` | `social_worker` \| `owner` \| `admin` | `[AuditTrailEntryResponse]` |
| 7 | `POST` | `/api/v1/patients/{patientId}/family-members` | `social_worker` | `204` |
| 8 | `DELETE` | `/api/v1/patients/{patientId}/family-members/{memberId}` | `social_worker` | `204` |
| 9 | `PUT` | `/api/v1/patients/{patientId}/primary-caregiver` | `social_worker` | `204` |
| 10 | `PUT` | `/api/v1/patients/{patientId}/social-identity` | `social_worker` | `204` |
| 11 | `PUT` | `/api/v1/patients/{patientId}/housing-condition` | `social_worker` | `204` |
| 12 | `PUT` | `/api/v1/patients/{patientId}/socioeconomic-situation` | `social_worker` | `204` |
| 13 | `PUT` | `/api/v1/patients/{patientId}/work-and-income` | `social_worker` | `204` |
| 14 | `PUT` | `/api/v1/patients/{patientId}/educational-status` | `social_worker` | `204` |
| 15 | `PUT` | `/api/v1/patients/{patientId}/health-status` | `social_worker` | `204` |
| 16 | `PUT` | `/api/v1/patients/{patientId}/community-support-network` | `social_worker` | `204` |
| 17 | `PUT` | `/api/v1/patients/{patientId}/social-health-summary` | `social_worker` | `204` |
| 18 | `PUT` | `/api/v1/patients/{patientId}/placement-history` | `social_worker` | `204` |
| 19 | `POST` | `/api/v1/patients/{patientId}/violation-reports` | `social_worker` | `201` + `IdResponse` |
| 20 | `POST` | `/api/v1/patients/{patientId}/referrals` | `social_worker` | `201` + `IdResponse` |
| 21 | `POST` | `/api/v1/patients/{patientId}/appointments` | `social_worker` | `201` + `IdResponse` |
| 22 | `PUT` | `/api/v1/patients/{patientId}/intake-info` | `social_worker` | `204` |
| 23 | `GET` | `/api/v1/dominios/{tableName}` | `social_worker` \| `owner` \| `admin` | `[LookupItemResponse]` |

**Total: 23 endpoints** (2 health + 21 protegidos)

---

## Health (publico, sem auth)

### `GET /health`

Liveness probe. Retorna `200 OK`.

### `GET /ready`

Readiness probe. Verifica conectividade com o banco.

---

## Registry — Pacientes

### `POST /api/v1/patients`

Registra novo paciente. Retorna `201 Created` com `StandardResponse<IdResponse>`.

**Headers:** `Authorization`, `X-Actor-Id`
**Role:** `social_worker`

```json
{
  "personId": "uuid-string",
  "prRelationshipId": "uuid-da-lookup-dominio_parentesco",
  "initialDiagnoses": [
    {
      "icdCode": "Q90.0",
      "date": "2026-01-15T00:00:00.000Z",
      "description": "Sindrome de Down"
    }
  ],
  "personalData": {
    "firstName": "Maria",
    "lastName": "Silva",
    "motherName": "Ana Silva",
    "nationality": "brasileira",
    "sex": "feminino",
    "socialName": null,
    "birthDate": "2020-05-10T00:00:00.000Z",
    "phone": null
  },
  "civilDocuments": {
    "cpf": "123.456.789-09",
    "nis": null,
    "rgDocument": {
      "number": "12345678",
      "issuingState": "SP",
      "issuingAgency": "SSP",
      "issueDate": "2021-01-01T00:00:00.000Z"
    }
  },
  "address": {
    "cep": "01001-000",
    "isShelter": false,
    "residenceLocation": "URBANO",
    "street": "Rua Exemplo",
    "neighborhood": "Centro",
    "number": "100",
    "complement": null,
    "state": "SP",
    "city": "Sao Paulo"
  },
  "socialIdentity": {
    "typeId": "uuid-da-lookup-dominio_tipo_identidade",
    "description": null
  }
}
```

**Regras de negocio:**
- `prRelationshipId` e obrigatorio (UUID da tabela `dominio_parentesco`)
- Ao menos um documento civil valido e necessario (`REGP-018`)
- `sex` deve ser `"masculino"` ou `"feminino"` (minusculo, portugues)
- `residenceLocation` deve ser `"URBANO"` ou `"RURAL"` (UPPERCASE)
- Todas as datas em ISO8601 completo

---

### `GET /api/v1/patients/{patientId}`

Retorna paciente completo. Ver secao [PatientResponse](#patientresponse-get-completo).

**Role:** `social_worker` | `owner` | `admin`

---

### `GET /api/v1/patients/by-person/{personId}`

Busca paciente pelo Person ID (identidade unica da pessoa no people-context).

**Role:** `social_worker` | `owner` | `admin`

---

### `GET /api/v1/patients/{patientId}/audit-trail`

Retorna trilha de auditoria do paciente.

**Role:** `social_worker` | `owner` | `admin`
**Query param opcional:** `?eventType=PatientRegistered`

```json
{
  "data": [
    {
      "id": "uuid",
      "aggregateId": "uuid-do-paciente",
      "eventType": "PatientRegistered",
      "actorId": "uuid-do-ator",
      "payload": { ... },
      "occurredAt": "2026-03-19T10:00:00Z",
      "recordedAt": "2026-03-19T10:00:01Z"
    }
  ],
  "meta": { "timestamp": "..." }
}
```

---

### `POST /api/v1/patients/{patientId}/family-members`

Adiciona membro familiar. Retorna `204 No Content`.

**Headers:** `Authorization`, `X-Actor-Id`
**Role:** `social_worker`

```json
{
  "memberPersonId": "uuid-string",
  "relationship": "uuid-da-lookup-dominio_parentesco",
  "isResiding": true,
  "isCaregiver": false,
  "hasDisability": false,
  "requiredDocuments": ["CPF", "RG"],
  "birthDate": "1985-03-15T00:00:00.000Z",
  "prRelationshipId": "uuid-da-relacao-PR-existente"
}
```

**Regras de negocio:**
- `prRelationshipId` deve ser o UUID da relacao da Pessoa de Referencia ja existente
- Se usar o mesmo `relationshipId` da PR, retorna `multiplePrimaryReferencesNotAllowed`
- `requiredDocuments` deve ser array JSON real (nao string serializada)

---

### `DELETE /api/v1/patients/{patientId}/family-members/{memberId}`

Remove membro familiar. Retorna `204 No Content`.

**Headers:** `Authorization`, `X-Actor-Id`
**Role:** `social_worker`

**Atencao:** Use o `personId` do membro na URL, nao o patientId nem IDs de relacionamento.

---

### `PUT /api/v1/patients/{patientId}/primary-caregiver`

Atribui cuidador principal. Retorna `204 No Content`.

**Headers:** `Authorization`, `X-Actor-Id`
**Role:** `social_worker`

```json
{
  "memberPersonId": "uuid-do-membro"
}
```

**Regra:** O membro deve existir na familia (adicionado via POST) antes de ser promovido.

---

### `PUT /api/v1/patients/{patientId}/social-identity`

Atualiza identidade social. Retorna `204 No Content`.

**Headers:** `Authorization`, `X-Actor-Id`
**Role:** `social_worker`

```json
{
  "typeId": "uuid-da-lookup-dominio_tipo_identidade",
  "description": "Descricao opcional"
}
```

**Atencao:** O sufixo da rota e `/social-identity` (completo), nao `/social-id`.

---

## Assessment — Avaliacoes

Todos os endpoints de assessment:
- **Base:** `/api/v1/patients/{patientId}`
- **Role:** `social_worker`
- **Headers obrigatorios:** `Authorization`, `X-Actor-Id`
- **Retorno:** `204 No Content`

---

### `PUT .../housing-condition`

```json
{
  "type": "string",
  "wallMaterial": "string",
  "numberOfRooms": 3,
  "numberOfBedrooms": 2,
  "numberOfBathrooms": 1,
  "waterSupply": "string",
  "hasPipedWater": true,
  "electricityAccess": "string",
  "sewageDisposal": "string",
  "wasteCollection": "string",
  "accessibilityLevel": "string",
  "isInGeographicRiskArea": false,
  "hasDifficultAccess": false,
  "isInSocialConflictArea": false,
  "hasDiagnosticObservations": false
}
```

Todos os campos sao obrigatorios.

---

### `PUT .../socioeconomic-situation`

```json
{
  "totalFamilyIncome": 2500.00,
  "incomePerCapita": 625.00,
  "receivesSocialBenefit": true,
  "socialBenefits": [
    {
      "benefitName": "BPC",
      "amount": 1412.00,
      "beneficiaryId": "uuid-do-beneficiario",
      "benefitTypeId": "uuid-da-lookup | null",
      "birthCertificateNumber": "string | null",
      "deceasedCpf": "string | null"
    }
  ],
  "mainSourceOfIncome": "string",
  "hasUnemployed": false
}
```

**Validacao condicional (MetadataValidator):**
- Se `benefitTypeId` informado, consulta `dominio_tipo_beneficio`:
  - Flag `exige_registro_nascimento = true` -> `birthCertificateNumber` obrigatorio
  - Flag `exige_cpf_falecido = true` -> `deceasedCpf` obrigatorio
- Se `benefitTypeId` nao existe na tabela -> `422 Unprocessable Entity`

---

### `PUT .../work-and-income`

```json
{
  "individualIncomes": [
    {
      "memberId": "uuid-do-membro",
      "occupationId": "uuid-da-lookup-dominio_condicao_ocupacao",
      "hasWorkCard": true,
      "monthlyAmount": 1800.00
    }
  ],
  "socialBenefits": [
    {
      "benefitName": "string",
      "amount": 1412.00,
      "beneficiaryId": "uuid-do-beneficiario",
      "benefitTypeId": "uuid | null",
      "birthCertificateNumber": "string | null",
      "deceasedCpf": "string | null"
    }
  ],
  "hasRetiredMembers": false
}
```

**Validacao condicional:** Mesma logica de `socioeconomic-situation` para `socialBenefits`.

---

### `PUT .../educational-status`

```json
{
  "memberProfiles": [
    {
      "memberId": "uuid-do-membro",
      "canReadWrite": true,
      "attendsSchool": true,
      "educationLevelId": "uuid-da-lookup-dominio_escolaridade"
    }
  ],
  "programOccurrences": [
    {
      "memberId": "uuid-do-membro",
      "date": "2026-01-15T00:00:00.000Z",
      "effectId": "uuid-da-lookup-dominio_efeito_condicionalidade",
      "isSuspensionRequested": false
    }
  ]
}
```

---

### `PUT .../health-status`

```json
{
  "deficiencies": [
    {
      "memberId": "uuid-do-membro",
      "deficiencyTypeId": "uuid-da-lookup-dominio_tipo_deficiencia",
      "needsConstantCare": true,
      "responsibleCaregiverName": "Nome do cuidador | null"
    }
  ],
  "gestatingMembers": [
    {
      "memberId": "uuid-do-membro",
      "monthsGestation": 6,
      "startedPrenatalCare": true
    }
  ],
  "constantCareNeeds": ["descricao-da-necessidade"],
  "foodInsecurity": false
}
```

**Validacao cruzada (CrossValidator):**
- `gestatingMembers`: se o `memberId` for o proprio paciente (Pessoa de Referencia), o `sex` do paciente deve ser `"feminino"`. Caso contrario retorna `422`.
- Membros que nao sao a PR nao sao validados aqui (dados de sexo residem no people-context).

---

### `PUT .../community-support-network`

```json
{
  "hasRelativeSupport": true,
  "hasNeighborSupport": false,
  "familyConflicts": "Descricao dos conflitos",
  "patientParticipatesInGroups": false,
  "familyParticipatesInGroups": false,
  "patientHasAccessToLeisure": true,
  "facesDiscrimination": false
}
```

Todos os campos sao obrigatorios.

---

### `PUT .../social-health-summary`

```json
{
  "requiresConstantCare": true,
  "hasMobilityImpairment": false,
  "functionalDependencies": ["alimentacao", "higiene"],
  "hasRelevantDrugTherapy": true
}
```

Todos os campos sao obrigatorios.

---

## Care — Cuidado

### `POST /api/v1/patients/{patientId}/appointments`

Registra atendimento. Retorna `201 Created` com `StandardResponse<IdResponse>`.

**Headers:** `Authorization`, `X-Actor-Id`
**Role:** `social_worker`

```json
{
  "professionalId": "uuid-do-profissional",
  "summary": "Resumo do atendimento | null",
  "actionPlan": "Plano de acao | null",
  "type": "tipo-do-atendimento | null",
  "date": "2026-03-19T14:00:00.000Z | null"
}
```

---

### `PUT /api/v1/patients/{patientId}/intake-info`

Registra info de acolhimento/ingresso. Retorna `204 No Content`.

**Headers:** `Authorization`, `X-Actor-Id`
**Role:** `social_worker`

```json
{
  "ingressTypeId": "uuid-da-lookup-dominio_tipo_ingresso",
  "originName": "Nome da origem | null",
  "originContact": "Contato da origem | null",
  "serviceReason": "Motivo do atendimento",
  "linkedSocialPrograms": [
    {
      "programId": "uuid-da-lookup-dominio_programa_social",
      "observation": "Observacao | null"
    }
  ]
}
```

---

## Protection — Protecao

### `PUT /api/v1/patients/{patientId}/placement-history`

Historico de acolhimento institucional. Retorna `204 No Content`.

**Headers:** `Authorization`, `X-Actor-Id`
**Role:** `social_worker`

```json
{
  "registries": [
    {
      "memberId": "uuid-do-membro",
      "startDate": "2025-01-01T00:00:00.000Z",
      "endDate": "2025-06-01T00:00:00.000Z | null",
      "reason": "Motivo do acolhimento"
    }
  ],
  "collectiveSituations": {
    "homeLossReport": "Relato de perda de moradia | null",
    "thirdPartyGuardReport": "Relato de guarda por terceiros | null"
  },
  "separationChecklist": {
    "adultInPrison": false,
    "adolescentInInternment": false
  }
}
```

**Validacao cruzada (CrossValidator):**
1. `endDate` deve ser >= `startDate` em cada registro
2. `thirdPartyGuardReport` (se preenchido) exige pelo menos um membro da familia < 18 anos
3. `adolescentInInternment = true` exige pelo menos um membro com idade entre 12 e 17 anos

---

### `POST /api/v1/patients/{patientId}/violation-reports`

Reporta violacao de direitos. Retorna `201 Created` com `StandardResponse<IdResponse>`.

**Headers:** `Authorization`, `X-Actor-Id`
**Role:** `social_worker`

```json
{
  "victimId": "uuid-da-vitima",
  "violationType": "tipo-da-violacao",
  "violationTypeId": "uuid-da-lookup-dominio_tipo_violacao | null",
  "reportDate": "2026-03-19T00:00:00.000Z | null",
  "incidentDate": "2026-03-01T00:00:00.000Z | null",
  "descriptionOfFact": "Descricao detalhada do fato",
  "actionsTaken": "Acoes tomadas | null"
}
```

**Validacao condicional (MetadataValidator):**
- Se `violationTypeId` informado, consulta `dominio_tipo_violacao`:
  - Flag `exige_descricao = true` -> `descriptionOfFact` nao pode ser vazio/whitespace

---

### `POST /api/v1/patients/{patientId}/referrals`

Cria encaminhamento. Retorna `201 Created` com `StandardResponse<IdResponse>`.

**Headers:** `Authorization`, `X-Actor-Id`
**Role:** `social_worker`

```json
{
  "referredPersonId": "uuid-da-pessoa-encaminhada",
  "professionalId": "uuid-do-profissional | null",
  "destinationService": "nome-do-servico-destino",
  "reason": "Motivo do encaminhamento",
  "date": "2026-03-19T00:00:00.000Z | null"
}
```

---

## Lookup — Tabelas de Dominio

### `GET /api/v1/dominios/{tableName}`

Busca itens ativos de uma tabela de dominio.

**Role:** `social_worker` | `owner` | `admin`

#### Tabelas disponiveis

| `tableName` | Descricao | Usado em |
|-------------|-----------|----------|
| `dominio_tipo_identidade` | Tipos de identidade social | `social-identity` |
| `dominio_parentesco` | Graus de parentesco | `patients` (prRelationshipId), `family-members` |
| `dominio_condicao_ocupacao` | Condicoes de ocupacao | `work-and-income` (occupationId) |
| `dominio_escolaridade` | Niveis de escolaridade | `educational-status` (educationLevelId) |
| `dominio_efeito_condicionalidade` | Efeitos de condicionalidade | `educational-status` (effectId) |
| `dominio_tipo_deficiencia` | Tipos de deficiencia | `health-status` (deficiencyTypeId) |
| `dominio_programa_social` | Programas sociais | `intake-info` (programId) |
| `dominio_tipo_ingresso` | Tipos de ingresso | `intake-info` (ingressTypeId) |
| `dominio_tipo_beneficio` | Tipos de beneficio | `socioeconomic-situation`, `work-and-income` |
| `dominio_tipo_violacao` | Tipos de violacao | `violation-reports` (violationTypeId) |
| `dominio_servico_vinculo` | Tipos de vinculo de servico | - |
| `dominio_tipo_medida` | Tipos de medida | - |
| `dominio_unidade_realizacao` | Unidades de realizacao | - |

**Flags de metadados** (colunas extras em algumas tabelas):
- `dominio_tipo_beneficio`: `exige_registro_nascimento`, `exige_cpf_falecido`
- `dominio_tipo_violacao`: `exige_descricao`

#### Resposta

```json
{
  "data": [
    {
      "id": "uuid",
      "codigo": "001",
      "descricao": "Descricao do item"
    }
  ],
  "meta": { "timestamp": "2026-03-19T00:00:00Z" }
}
```

Somente retorna registros com `ativo = true`.

---

## PatientResponse (GET completo)

Resposta do `GET /api/v1/patients/{patientId}` e `GET /api/v1/patients/by-person/{personId}`:

```json
{
  "data": {
    "patientId": "uuid",
    "personId": "uuid",
    "version": 1,

    "personalData": {
      "firstName": "string",
      "lastName": "string",
      "motherName": "string",
      "nationality": "string",
      "sex": "feminino",
      "socialName": "string | null",
      "birthDate": "2020-05-10T00:00:00Z",
      "phone": "string | null"
    },

    "civilDocuments": {
      "cpf": "123.456.789-09 | null",
      "nis": "string | null",
      "rgDocument": {
        "number": "12.345.678",
        "issuingState": "SP",
        "issuingAgency": "SSP",
        "issueDate": "2021-01-01T00:00:00Z"
      }
    },

    "address": {
      "cep": "01001-000 | null",
      "isShelter": false,
      "residenceLocation": "URBANO",
      "street": "string | null",
      "neighborhood": "string | null",
      "number": "string | null",
      "complement": "string | null",
      "state": "SP",
      "city": "Sao Paulo"
    },

    "socialIdentity": {
      "typeId": "uuid",
      "otherDescription": "string | null"
    },

    "familyMembers": [
      {
        "personId": "uuid",
        "relationshipId": "uuid",
        "isPrimaryCaregiver": false,
        "residesWithPatient": true,
        "hasDisability": false,
        "requiredDocuments": ["CPF", "RG"],
        "birthDate": "1985-03-15T00:00:00Z"
      }
    ],

    "diagnoses": [
      {
        "icdCode": "Q90.0",
        "description": "Sindrome de Down",
        "date": "2026-01-15T00:00:00Z"
      }
    ],

    "housingCondition": {
      "type": "string",
      "wallMaterial": "string",
      "numberOfRooms": 3,
      "numberOfBedrooms": 2,
      "numberOfBathrooms": 1,
      "waterSupply": "string",
      "hasPipedWater": true,
      "electricityAccess": "string",
      "sewageDisposal": "string",
      "wasteCollection": "string",
      "accessibilityLevel": "string",
      "isInGeographicRiskArea": false,
      "hasDifficultAccess": false,
      "isInSocialConflictArea": false,
      "hasDiagnosticObservations": false
    },

    "socioeconomicSituation": {
      "totalFamilyIncome": 2500.00,
      "incomePerCapita": 625.00,
      "receivesSocialBenefit": true,
      "hasUnemployed": false,
      "mainSourceOfIncome": "string",
      "socialBenefits": [
        {
          "benefitName": "BPC",
          "amount": 1412.00,
          "beneficiaryId": "uuid"
        }
      ]
    },

    "workAndIncome": {
      "hasRetiredMembers": false,
      "individualIncomes": [
        {
          "memberId": "uuid",
          "occupationId": "uuid",
          "hasWorkCard": true,
          "monthlyAmount": 1800.00
        }
      ],
      "socialBenefits": [
        {
          "benefitName": "string",
          "amount": 1412.00,
          "beneficiaryId": "uuid"
        }
      ]
    },

    "educationalStatus": {
      "memberProfiles": [
        {
          "memberId": "uuid",
          "canReadWrite": true,
          "attendsSchool": true,
          "educationLevelId": "uuid"
        }
      ],
      "programOccurrences": [
        {
          "memberId": "uuid",
          "date": "2026-01-15T00:00:00Z",
          "effectId": "uuid",
          "isSuspensionRequested": false
        }
      ]
    },

    "healthStatus": {
      "foodInsecurity": false,
      "deficiencies": [
        {
          "memberId": "uuid",
          "deficiencyTypeId": "uuid",
          "needsConstantCare": true,
          "responsibleCaregiverName": "string | null"
        }
      ],
      "gestatingMembers": [
        {
          "memberId": "uuid",
          "monthsGestation": 6,
          "startedPrenatalCare": true
        }
      ],
      "constantCareNeeds": ["string"]
    },

    "communitySupportNetwork": {
      "hasRelativeSupport": true,
      "hasNeighborSupport": false,
      "familyConflicts": "string",
      "patientParticipatesInGroups": false,
      "familyParticipatesInGroups": false,
      "patientHasAccessToLeisure": true,
      "facesDiscrimination": false
    },

    "socialHealthSummary": {
      "requiresConstantCare": true,
      "hasMobilityImpairment": false,
      "functionalDependencies": ["alimentacao"],
      "hasRelevantDrugTherapy": true
    },

    "placementHistory": {
      "individualPlacements": [
        {
          "id": "uuid",
          "memberId": "uuid",
          "startDate": "2025-01-01T00:00:00Z",
          "endDate": "2025-06-01T00:00:00Z | null",
          "reason": "string"
        }
      ],
      "homeLossReport": "string | null",
      "thirdPartyGuardReport": "string | null",
      "adultInPrison": false,
      "adolescentInInternment": false
    },

    "intakeInfo": {
      "ingressTypeId": "uuid",
      "originName": "string | null",
      "originContact": "string | null",
      "serviceReason": "string",
      "linkedSocialPrograms": [
        {
          "programId": "uuid",
          "observation": "string | null"
        }
      ]
    },

    "appointments": [
      {
        "id": "uuid",
        "date": "2026-03-19T14:00:00Z",
        "professionalId": "uuid",
        "type": "string",
        "summary": "string",
        "actionPlan": "string"
      }
    ],

    "referrals": [
      {
        "id": "uuid",
        "date": "2026-03-19T00:00:00Z",
        "professionalId": "uuid",
        "referredPersonId": "uuid",
        "destinationService": "string",
        "reason": "string",
        "status": "string"
      }
    ],

    "violationReports": [
      {
        "id": "uuid",
        "reportDate": "2026-03-19T00:00:00Z",
        "incidentDate": "2026-03-01T00:00:00Z | null",
        "victimId": "uuid",
        "violationType": "string",
        "descriptionOfFact": "string",
        "actionsTaken": "string"
      }
    ],

    "computedAnalytics": {
      "housing": {
        "density": 1.5,
        "isOvercrowded": false
      },
      "financial": {
        "totalWorkIncome": 3600.00,
        "perCapitaWorkIncome": 900.00,
        "totalGlobalIncome": 5012.00,
        "perCapitaGlobalIncome": 1253.00
      },
      "ageProfile": {
        "range0to6": 1,
        "range7to14": 0,
        "range15to17": 0,
        "range18to29": 1,
        "range30to59": 2,
        "range60to64": 0,
        "range65to69": 0,
        "range70Plus": 0,
        "totalMembers": 4
      },
      "educationalVulnerabilities": {
        "notInSchool0to5": 0,
        "notInSchool6to14": 0,
        "notInSchool15to17": 0,
        "illiteracy10to17": 0,
        "illiteracy18to59": 0,
        "illiteracy60Plus": 0
      }
    }
  },
  "meta": {
    "timestamp": "2026-03-19T10:30:00Z"
  }
}
```

**Notas sobre `computedAnalytics`:**
- Calculados no servidor no momento do GET (nao persistidos)
- `housing` e `null` se `housingCondition` nao foi preenchido
- `financial` e `null` se `workAndIncome` nao foi preenchido
- `educationalVulnerabilities` e `null` se `educationalStatus` nao foi preenchido
- `ageProfile` sempre presente (calculado a partir dos membros familiares)
- `isOvercrowded` e `true` quando `density > 3.0` (membros / quartos)
- `totalMembers` inclui o paciente (membros + 1)

---

## Regras de Validacao — Resumo

### Validacao por Metadata (MetadataValidator)

Consulta flags em tabelas de dominio para exigir campos condicionalmente:

| Tabela | Flag | Campo exigido |
|--------|------|---------------|
| `dominio_tipo_beneficio` | `exige_registro_nascimento` | `birthCertificateNumber` |
| `dominio_tipo_beneficio` | `exige_cpf_falecido` | `deceasedCpf` |
| `dominio_tipo_violacao` | `exige_descricao` | `descriptionOfFact` (nao-vazio) |

### Validacao Cruzada (CrossValidator)

Valida dados que dependem de contexto do agregado Patient:

| Regra | Endpoint | Condicao |
|-------|----------|----------|
| Gestante deve ser feminino | `health-status` | `gestatingMembers[].memberId` == PR e `sex != feminino` -> 422 |
| endDate >= startDate | `placement-history` | Cada registro individualmente |
| Guarda por terceiros requer menor | `placement-history` | `thirdPartyGuardReport` preenchido sem membro < 18 -> 422 |
| Internacao de adolescente | `placement-history` | `adolescentInInternment = true` sem membro 12-17 -> 422 |
