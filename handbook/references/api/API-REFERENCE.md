# API Reference — ACDG Brasil

Documentação de referência para consumo das APIs da ACDG Brasil.

---

## Domínios e Base URLs

| Domínio | Ambiente | Descrição |
|---------|----------|-----------|
| `https://social-care.acdgbrasil.com.br` | **Produção** | Serviço Social Care |
| `https://social-care-hml.acdgbrasil.com.br` | **Homologação** | Serviço Social Care (staging) |
| `https://auth.acdgbrasil.com.br` | **Produção** | Identity Provider (Zitadel) |
| `https://api.acdgbrasil.com.br` | **Produção** | API Gateway |
| `https://cloud.acdgbrasil.com.br` | **Produção** | Cloud Management |
| `https://dashboard.acdgbrasil.com.br` | **Produção** | Dashboard |
| `https://nats.acdgbrasil.com.br` | **Produção** | NATS Messaging |
| `https://tcc.acdgbrasil.com.br` | **Produção** | Conteúdo Acadêmico |

Todos os domínios passam por reverse proxy (`100.77.46.69:80`) via Caddy.

---

## Autenticação

Todos os endpoints protegidos exigem:

- **Header:** `Authorization: Bearer <JWT_TOKEN>`
- **JWT** validado contra JWKS do Zitadel: `https://auth.acdgbrasil.com.br/oauth/v2/keys`
- **Issuer:** `https://auth.acdgbrasil.com.br`
- **Token Endpoint:** `https://auth.acdgbrasil.com.br/oauth/v2/token`
- **Roles** extraídas do claim `urn:zitadel:iam:org:project:roles`

Para operações de escrita (POST/PUT/DELETE), o header **`X-Actor-Id`** é obrigatório (ID do usuário autenticado, usado para auditoria).

### Roles disponíveis

| Role | Permissão |
|------|-----------|
| `social_worker` | Leitura e escrita em pacientes, avaliações, cuidado e proteção |
| `owner` | Leitura de pacientes |
| `admin` | Acesso completo |

---

## Formato de Resposta Padrão

Todas as respostas (exceto 204 No Content e Health) seguem o envelope `StandardResponse<T>`:

```json
{
  "data": { },
  "meta": {
    "timestamp": "2026-03-12T10:30:00Z"
  }
}
```

### Códigos de Erro

| Status | Significado |
|--------|-------------|
| `400` | Request inválido |
| `401` | JWT ausente ou inválido |
| `403` | Role insuficiente |
| `404` | Recurso não encontrado |
| `500` | Erro interno |
| `503` | Banco indisponível |

---

## Social Care — Endpoints

**Base URL (produção):** `https://social-care.acdgbrasil.com.br`
**Base URL (homologação):** `https://social-care-hml.acdgbrasil.com.br`

---

### Health (público)

| Método | Path | Descrição |
|--------|------|-----------|
| `GET` | `/health` | Liveness probe — retorna 200 OK |
| `GET` | `/ready` | Readiness probe — verifica conectividade com o banco |

---

### Registry — Pacientes

**Base:** `/api/v1/patients`

#### Escrita (role: `social_worker`)

| Método | Path | Descrição | Headers |
|--------|------|-----------|---------|
| `POST` | `/api/v1/patients` | Registrar paciente | `X-Actor-Id` |
| `POST` | `/api/v1/patients/{patientId}/family-members` | Adicionar membro familiar | `X-Actor-Id` |
| `DELETE` | `/api/v1/patients/{patientId}/family-members/{memberId}` | Remover membro familiar | `X-Actor-Id` |
| `PUT` | `/api/v1/patients/{patientId}/primary-caregiver` | Atribuir cuidador principal | `X-Actor-Id` |
| `PUT` | `/api/v1/patients/{patientId}/social-identity` | Atualizar identidade social | `X-Actor-Id` |

#### Leitura (role: `social_worker`, `owner`, `admin`)

| Método | Path | Descrição |
|--------|------|-----------|
| `GET` | `/api/v1/patients/{patientId}` | Buscar paciente por ID |
| `GET` | `/api/v1/patients/by-person/{personId}` | Buscar por Person ID |
| `GET` | `/api/v1/patients/{patientId}/audit-trail` | Trilha de auditoria |

> Query param opcional para audit-trail: `?eventType=<tipo>`

#### POST `/api/v1/patients`

```json
{
  "personId": "string",
  "initialDiagnoses": [
    { "icdCode": "string", "date": "2026-01-15", "description": "string" }
  ],
  "personalData": {
    "firstName": "string",
    "lastName": "string",
    "motherName": "string",
    "nationality": "string",
    "sex": "string",
    "socialName": "string | null",
    "birthDate": "2000-01-01",
    "phone": "string | null"
  },
  "civilDocuments": {
    "cpf": "string | null",
    "nis": "string | null",
    "rgDocument": {
      "number": "string",
      "issuingState": "string",
      "issuingAgency": "string",
      "issueDate": "2020-01-01"
    }
  },
  "address": {
    "cep": "string | null",
    "isShelter": false,
    "residenceLocation": "string",
    "street": "string | null",
    "neighborhood": "string | null",
    "number": "string | null",
    "complement": "string | null",
    "state": "string",
    "city": "string"
  },
  "socialIdentity": {
    "typeId": "string",
    "description": "string | null"
  },
  "prRelationshipId": "string"
}
```

#### POST `.../family-members`

```json
{
  "memberId": "string",
  "relationshipId": "string",
  "name": "string",
  "birthDate": "2000-01-01",
  "sex": "string"
}
```

#### PUT `.../primary-caregiver`

```json
{ "memberId": "string" }
```

#### PUT `.../social-identity`

```json
{ "typeId": "string", "description": "string | null" }
```

---

### Assessment — Avaliações

**Base:** `/api/v1/patients/{patientId}`
**Role:** `social_worker` | **Header obrigatório:** `X-Actor-Id`

| Método | Path | Descrição |
|--------|------|-----------|
| `PUT` | `.../housing-condition` | Condição habitacional |
| `PUT` | `.../socioeconomic-situation` | Situação socioeconômica |
| `PUT` | `.../work-and-income` | Trabalho e renda |
| `PUT` | `.../educational-status` | Situação educacional |
| `PUT` | `.../health-status` | Condição de saúde |
| `PUT` | `.../community-support-network` | Rede de apoio comunitária |
| `PUT` | `.../social-health-summary` | Resumo socio-sanitário |

Todos retornam **204 No Content** em caso de sucesso.

#### PUT `.../housing-condition`

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

#### PUT `.../socioeconomic-situation`

```json
{
  "totalFamilyIncome": 2500.00,
  "incomePerCapita": 625.00,
  "receivesSocialBenefit": true,
  "socialBenefits": [
    {
      "benefitName": "BPC",
      "amount": 1412.00,
      "beneficiaryId": "string",
      "benefitTypeId": "string | null",
      "birthCertificateNumber": "string | null",
      "deceasedCpf": "string | null"
    }
  ],
  "mainSourceOfIncome": "string",
  "hasUnemployed": false
}
```

#### PUT `.../work-and-income`

```json
{
  "individualIncomes": [
    {
      "memberId": "string",
      "occupationId": "string",
      "hasWorkCard": true,
      "monthlyAmount": 1800.00
    }
  ],
  "socialBenefits": [
    {
      "benefitName": "string",
      "amount": 1412.00,
      "beneficiaryId": "string",
      "benefitTypeId": "string | null",
      "birthCertificateNumber": "string | null",
      "deceasedCpf": "string | null"
    }
  ],
  "hasRetiredMembers": false
}
```

#### PUT `.../educational-status`

```json
{
  "memberProfiles": [
    {
      "memberId": "string",
      "canReadWrite": true,
      "attendsSchool": true,
      "educationLevelId": "string"
    }
  ],
  "programOccurrences": [
    {
      "memberId": "string",
      "date": "2026-01-15",
      "effectId": "string",
      "isSuspensionRequested": false
    }
  ]
}
```

#### PUT `.../health-status`

```json
{
  "deficiencies": [
    {
      "memberId": "string",
      "deficiencyTypeId": "string",
      "needsConstantCare": true,
      "responsibleCaregiverName": "string | null"
    }
  ],
  "gestatingMembers": [
    {
      "memberId": "string",
      "monthsGestation": 6,
      "startedPrenatalCare": true
    }
  ],
  "constantCareNeeds": ["string"],
  "foodInsecurity": false
}
```

#### PUT `.../community-support-network`

```json
{
  "hasRelativeSupport": true,
  "hasNeighborSupport": false,
  "familyConflicts": "string",
  "patientParticipatesInGroups": false,
  "familyParticipatesInGroups": false,
  "patientHasAccessToLeisure": true,
  "facesDiscrimination": false
}
```

#### PUT `.../social-health-summary`

```json
{
  "requiresConstantCare": true,
  "hasMobilityImpairment": false,
  "functionalDependencies": ["string"],
  "hasRelevantDrugTherapy": true
}
```

---

### Care — Cuidado

**Base:** `/api/v1/patients/{patientId}`
**Role:** `social_worker` | **Header obrigatório:** `X-Actor-Id`

| Método | Path | Descrição | Resposta |
|--------|------|-----------|----------|
| `POST` | `.../appointments` | Registrar atendimento | `StandardResponse<IdResponse>` |
| `PUT` | `.../intake-info` | Registrar info de acolhimento | 204 No Content |

#### POST `.../appointments`

```json
{
  "professionalId": "string",
  "summary": "string | null",
  "actionPlan": "string | null",
  "type": "string | null",
  "date": "2026-03-12 | null"
}
```

#### PUT `.../intake-info`

```json
{
  "ingressTypeId": "string",
  "originName": "string | null",
  "originContact": "string | null",
  "serviceReason": "string",
  "linkedSocialPrograms": [
    { "programId": "string", "observation": "string | null" }
  ]
}
```

---

### Protection — Proteção

**Base:** `/api/v1/patients/{patientId}`
**Role:** `social_worker` | **Header obrigatório:** `X-Actor-Id`

| Método | Path | Descrição | Resposta |
|--------|------|-----------|----------|
| `PUT` | `.../placement-history` | Histórico de acolhimento institucional | 204 No Content |
| `POST` | `.../violation-reports` | Reportar violação de direitos | `StandardResponse<IdResponse>` |
| `POST` | `.../referrals` | Criar encaminhamento | `StandardResponse<IdResponse>` |

#### PUT `.../placement-history`

```json
{
  "registries": [
    {
      "memberId": "string",
      "startDate": "2025-01-01",
      "endDate": "2025-06-01 | null",
      "reason": "string"
    }
  ],
  "collectiveSituations": {
    "homeLossReport": "string | null",
    "thirdPartyGuardReport": "string | null"
  },
  "separationChecklist": {
    "adultInPrison": false,
    "adolescentInInternment": false
  }
}
```

#### POST `.../violation-reports`

```json
{
  "victimId": "string",
  "violationType": "string",
  "violationTypeId": "string | null",
  "reportDate": "2026-03-12 | null",
  "incidentDate": "2026-03-01 | null",
  "descriptionOfFact": "string",
  "actionsTaken": "string | null"
}
```

#### POST `.../referrals`

```json
{
  "referredPersonId": "string",
  "professionalId": "string | null",
  "destinationService": "string",
  "reason": "string",
  "date": "2026-03-12 | null"
}
```

---

### Lookup — Tabelas de Domínio

**Base:** `/api/v1/dominios`
**Role:** `social_worker`, `owner`, `admin`

| Método | Path | Descrição |
|--------|------|-----------|
| `GET` | `/api/v1/dominios/{tableName}` | Buscar itens de uma tabela de domínio |

#### Tabelas disponíveis

| `tableName` | Descrição |
|-------------|-----------|
| `dominio_tipo_identidade` | Tipos de identidade social |
| `dominio_parentesco` | Graus de parentesco |
| `dominio_condicao_ocupacao` | Condições de ocupação |
| `dominio_escolaridade` | Níveis de escolaridade |
| `dominio_efeito_condicionalidade` | Efeitos de condicionalidade |
| `dominio_tipo_deficiencia` | Tipos de deficiência |
| `dominio_programa_social` | Programas sociais |
| `dominio_tipo_ingresso` | Tipos de ingresso |
| `dominio_tipo_beneficio` | Tipos de benefício |
| `dominio_tipo_violacao` | Tipos de violação |
| `dominio_servico_vinculo` | Tipos de vínculo de serviço |
| `dominio_tipo_medida` | Tipos de medida |
| `dominio_unidade_realizacao` | Unidades de realização |

#### Resposta

```json
{
  "data": [
    { "id": "uuid", "codigo": "001", "descricao": "Descrição do item" }
  ],
  "meta": { "timestamp": "2026-03-12T00:00:00Z" }
}
```

---

## Resumo — Total de Endpoints

| Grupo | Endpoints |
|-------|-----------|
| Health | 2 |
| Registry | 8 |
| Assessment | 7 |
| Care | 2 |
| Protection | 3 |
| Lookup | 1 (13 tabelas) |
| **Total** | **24** |
