# Fase 4 — Offline Engine

> **Pre-requisitos:** Fase 3 (BFF Social Care) completa.
> **Resultado:** O app funciona 100% sem internet. Quando reconecta, sincroniza automaticamente.

---

## 1. Visao Geral

O Offline Engine e a camada que permite ao usuario trabalhar sem conexao. Toda acao do usuario e gravada localmente primeiro (Isar) e sincronizada com o backend quando houver internet. O usuario nunca percebe a diferenca entre estar online ou offline — a experiencia e identica.

### 1.1 Principio Central: Local-First

```
Acao do usuario
      |
      v
+---------------------+
| Repository          |  <-- SEMPRE grava local primeiro
| (OfflineFirst)      |
+----+----------------+
     |           |
     v           v
  Isar DB    SyncQueue
  (cache)    (fila de acoes)
                 |
                 v  (quando online)
           SyncEngine
                 |
                 v
           Remote BFF
                 |
                 v
           API Backend
```

A camada de Repository e a unica que sabe se esta online ou offline. O UseCase, ViewModel e View nunca lidam com isso.

### 1.2 O que ja existe (inventario)

| Artefato | Pacote | Status |
|----------|--------|--------|
| `IsarService` | `core` | Funcional — init/close do Isar |
| `SyncQueueService` | `core` | Funcional — enqueue, getPending, updateStatus, remove |
| `ConnectivityService` | `network` | Funcional — dual-check real (HEAD request), `ValueNotifier<bool>` |
| `CachedPatient` schema | `persistence` | Definido — patientId, nome, cpf, fullRecordJson, lastSyncAt |
| `CachedLookup` schema | `persistence` | Definido — tableName, code, description, rawId |
| `SyncAction` schema | `persistence` | Definido — actionId, patientId, actionType, payload, status |
| `LocalSocialCareRepository` | `social_care_desktop` | Parcial — registerPatient e getPatient implementados, resto via noSuchMethod |
| `SyncEngine` | `social_care_desktop` | Esqueleto — start/stop/processQueue estruturados, _dispatchAction incompleto |
| `SocialCareBffRemote` | `social_care_desktop` | Completo — 21 metodos HTTP implementados |
| `SocialCareContract` | `shared` | Completo — interface com 21 metodos |
| `PatientMapper` | `shared` | Completo — toJson/fromJson para todo o agregado Patient |

### 1.3 O que falta

```
[Schemas]         Ajustar CachedPatient (adicionar version, personId)
                  Ajustar CachedLookup (mudar de item unico para lista JSON)
                  Adicionar CachedAppointment, CachedReferral, CachedViolationReport (opcionais, fase futura)

[Repository]      Completar LocalSocialCareRepository (21 metodos reais)
                  Criar OfflineFirstRepository (orquestrador local + remote)

[SyncEngine]      Implementar _dispatchAction para todos os 21 action types
                  Adicionar retry com exponential backoff
                  Adicionar conflict detection (version mismatch)

[Orquestracao]    SyncStatus notifier (para UI mostrar icone de sync)
                  Inicializacao no boot do app (DI via Provider)

[Testes]          Unitarios para cada camada
                  Integracao: cenarios offline -> online -> sync
```

---

## 2. Arquitetura Detalhada

### 2.1 Camada de Repository — OfflineFirstRepository

Este e o componente central. Ele implementa `SocialCareContract` e decide como rotear cada chamada:

```
OfflineFirstRepository implements SocialCareContract
    |
    +-- _localRepo: LocalSocialCareRepository  (Isar)
    +-- _remoteRepo: SocialCareBffRemote        (Dio/HTTP)
    +-- _syncQueue: SyncQueueService             (fila)
    +-- _connectivity: ConnectivityService        (status rede)
    +-- _syncEngine: SyncEngine                   (drena fila)
```

**Regras de roteamento:**

| Operacao | Online | Offline |
|----------|--------|---------|
| **Escrita** (register, update, add, remove) | Grava local + enfileira + tenta sync imediato | Grava local + enfileira (sync depois) |
| **Leitura** (get, list) | Tenta remote, atualiza cache, retorna | Retorna do cache local |
| **Lookup tables** | Remote com cache-aside (busca, grava local, retorna) | Retorna cache local |
| **Health/Ready** | Remote direto | Retorna Failure (esperado) |
| **Audit trail** | Remote direto (sem cache — dados sensíveis, sempre frescos) | Retorna lista vazia |

### 2.2 Fluxo de Escrita (Write Path)

```
1. Usuario chama registerPatient(patient) no OfflineFirstRepository

2. Repository:
   a. Grava no Isar (LocalSocialCareRepository)
   b. Enfileira SyncAction(type: 'REGISTER_PATIENT', payload: json, version: patient.version)
   c. Se online:
      - SyncEngine.processQueue() imediato
      - Se sucesso: remove SyncAction, atualiza cache com resposta do server
      - Se falha de rede: mantem na fila (retry depois)
      - Se falha de negocio (4xx): marca como FAILED com erro
   d. Retorna Success(patientId) — independente de ter sincronizado ou nao

3. O usuario NUNCA espera a rede. A UI e instantanea.
```

### 2.3 Fluxo de Leitura (Read Path)

```
1. Usuario chama getPatient(id) no OfflineFirstRepository

2. Repository:
   a. Se online:
      - Busca no remote
      - Se sucesso: atualiza cache local, retorna dados frescos
      - Se falha: fallback para cache local
   b. Se offline:
      - Retorna do cache local
      - Se nao tem cache: retorna Failure('Not available offline')
```

### 2.4 Lookup Tables — Cache-Aside

Lookup tables (parentesco, escolaridade, deficiencia, etc.) mudam raramente. Estrategia:

```
1. No boot do app (se online): pre-carrega todas as 13 tabelas no Isar
2. Em cada chamada getLookupTable(name):
   a. Se online e cache tem mais de 24h: busca remote, atualiza cache
   b. Senao: retorna cache direto
3. Offline: cache local (sempre disponivel apos primeiro boot online)
```

### 2.5 SyncEngine — Detalhamento

```
SyncEngine
    |
    +-- processQueue()
    |     Drena SyncActions PENDING na ordem de timestamp
    |     Para cada action:
    |       1. Marca IN_PROGRESS
    |       2. Reconstitui domain object via PatientMapper.fromJson()
    |       3. Chama metodo correspondente no RemoteBff
    |       4. Sucesso -> remove action, atualiza cache com versao do server
    |       5. Falha de rede -> volta para PENDING, para processamento
    |       6. Falha de negocio -> marca FAILED, continua proxima
    |       7. Conflito de versao (409) -> marca CONFLICT, notifica UI
    |
    +-- start()
    |     Escuta ConnectivityService.onStatusChange
    |     Quando volta online: processQueue()
    |
    +-- scheduleRetry()
    |     Timer periodico (30s quando online) para retentar PENDING
    |
    +-- syncStatus: ValueNotifier<SyncStatus>
          Expoe estado para a UI:
          - idle (nada pendente)
          - syncing (processando fila)
          - pending(count) (X acoes aguardando)
          - error(count) (X acoes falharam)
          - conflict(count) (X conflitos para resolver)
```

### 2.6 Deteccao de Conflitos

**Conflito = o backend recusou a escrita porque a versao do registro mudou desde o ultimo read.**

O backend retorna HTTP 409 (Conflict) quando `patient.version` no request nao bate com a versao atual no banco.

Tratamento:
1. SyncEngine marca SyncAction como `CONFLICT`
2. SyncStatus emite `conflict(count)`
3. UI mostra indicador visual de conflito
4. Para resolver: busca versao fresca do server, apresenta diff ao usuario, usuario escolhe
5. Resolucao automatica (campos diferentes): merge automatico no BFF (fase posterior, comeca com manual)

**Na Fase 4 o conflito sera tratado de forma simples:**
- Marca como CONFLICT
- UI notifica o usuario
- Usuario pode "forcar" (sobrescreve) ou "descartar" (perde local)
- Merge inteligente fica para evolucao futura

---

## 3. Ajustes nos Schemas Isar

### 3.1 CachedPatient — Adicionar campos

```dart
@collection
class CachedPatient {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String patientId;

  @Index()
  late String personId;          // NOVO: busca por personId

  late String firstName;
  late String lastName;

  @Index()
  late String cpf;

  late String fullRecordJson;    // Patient completo serializado
  late int version;              // NOVO: para conflict detection
  late DateTime lastSyncAt;
  late bool isDirty;             // NOVO: true se tem mudancas locais nao sincronizadas
}
```

### 3.2 CachedLookup — Mudar para lista

O schema atual armazena um item por row. Mais eficiente armazenar a tabela inteira como JSON:

```dart
@collection
class CachedLookup {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String tableName;          // ex: 'dominio_parentesco'

  late String itemsJson;          // NOVO: JSON array com todos os items
  late DateTime lastFetchedAt;    // NOVO: para invalidacao de cache (24h)
}
```

### 3.3 SyncAction — Adicionar campos

```dart
@collection
class SyncAction {
  Id id = Isar.autoIncrement;

  @Index()
  late String actionId;

  @Index()
  late String patientId;

  late String actionType;
  late String payloadJson;

  @Index()
  late DateTime timestamp;

  @Index()
  late String status;           // PENDING, IN_PROGRESS, FAILED, CONFLICT

  late int retryCount;          // NOVO: contagem de tentativas
  DateTime? nextRetryAt;        // NOVO: proximo retry (backoff)
  String? lastError;
  String? conflictDetails;      // NOVO: detalhes do conflito para UI
}
```

---

## 4. Action Types — Mapa Completo

Cada metodo do `SocialCareContract` corresponde a um action type no SyncEngine:

| Metodo do Contrato | Action Type | Payload |
|---------------------|-------------|---------|
| `registerPatient` | `REGISTER_PATIENT` | Patient JSON completo |
| `addFamilyMember` | `ADD_FAMILY_MEMBER` | `{ patientId, member, prRelationshipId }` |
| `removeFamilyMember` | `REMOVE_FAMILY_MEMBER` | `{ patientId, memberId }` |
| `assignPrimaryCaregiver` | `ASSIGN_CAREGIVER` | `{ patientId, memberId }` |
| `updateSocialIdentity` | `UPDATE_SOCIAL_IDENTITY` | `{ patientId, typeId, description }` |
| `updateHousingCondition` | `UPDATE_HOUSING` | HousingCondition JSON |
| `updateSocioEconomicSituation` | `UPDATE_SOCIOECONOMIC` | SocioEconomicSituation JSON |
| `updateWorkAndIncome` | `UPDATE_WORK_INCOME` | WorkAndIncome JSON |
| `updateEducationalStatus` | `UPDATE_EDUCATION` | EducationalStatus JSON |
| `updateHealthStatus` | `UPDATE_HEALTH` | HealthStatus JSON |
| `updateCommunitySupportNetwork` | `UPDATE_COMMUNITY_SUPPORT` | CommunitySupportNetwork JSON |
| `updateSocialHealthSummary` | `UPDATE_SOCIAL_HEALTH` | SocialHealthSummary JSON |
| `registerAppointment` | `REGISTER_APPOINTMENT` | `{ patientId, appointment }` |
| `updateIntakeInfo` | `UPDATE_INTAKE` | `{ patientId, intakeInfo }` |
| `updatePlacementHistory` | `UPDATE_PLACEMENT` | `{ patientId, placementHistory }` |
| `reportViolation` | `REPORT_VIOLATION` | `{ patientId, report }` |
| `createReferral` | `CREATE_REFERRAL` | `{ patientId, referral }` |

**Nao enfileirados (somente online):** `checkHealth`, `checkReady`, `getPatient`, `getPatientByPersonId`, `getAuditTrail`, `getLookupTable`

---

## 5. Plano de Execucao — Etapas Ordenadas

### Etapa 1: Ajustar Schemas Isar (persistence)

**Objetivo:** Schemas robustos para suportar cache + sync + conflict detection.

- [ ] 1.1 Atualizar `CachedPatient` — adicionar `version`, `personId`, `isDirty`
- [ ] 1.2 Reescrever `CachedLookup` — mudar para `itemsJson` + `lastFetchedAt`
- [ ] 1.3 Atualizar `SyncAction` — adicionar `retryCount`, `nextRetryAt`, `conflictDetails`
- [ ] 1.4 Regenerar codigo Isar (`dart run build_runner build`)
- [ ] 1.5 Atualizar `IsarSchemas.all` se necessario
- [ ] 1.6 Testes unitarios para cada schema (serialization round-trip)

**Testes:** Criar/ler/atualizar/deletar cada collection, validar indices.

---

### Etapa 2: Completar LocalSocialCareRepository (social_care_desktop)

**Objetivo:** Implementacao completa de `SocialCareContract` usando Isar local.

Cada metodo de escrita segue o padrao:
1. Ler `CachedPatient` do Isar
2. Aplicar a mutacao no JSON local (deserializa -> muta -> serializa)
3. Gravar de volta no Isar com `isDirty = true`
4. Enfileirar `SyncAction`
5. Retornar `Success`

- [ ] 2.1 Refatorar `registerPatient` para usar novos campos (version, isDirty)
- [ ] 2.2 Implementar `getPatientByPersonId` (query por personId index)
- [ ] 2.3 Implementar `addFamilyMember` — ler cache, append member, gravar, enqueue
- [ ] 2.4 Implementar `removeFamilyMember` — ler cache, filter member, gravar, enqueue
- [ ] 2.5 Implementar `assignPrimaryCaregiver` — ler cache, mutar flags, gravar, enqueue
- [ ] 2.6 Implementar `updateSocialIdentity` — ler cache, mutar, gravar, enqueue
- [ ] 2.7 Implementar 7 metodos de Assessment (mesmo padrao: ler, mutar campo, gravar, enqueue)
- [ ] 2.8 Implementar `registerAppointment` — append na lista de appointments
- [ ] 2.9 Implementar `updateIntakeInfo` — mutar campo intakeInfo
- [ ] 2.10 Implementar 3 metodos de Protection (placement, violation, referral)
- [ ] 2.11 Implementar `getLookupTable` — ler CachedLookup, deserializar itemsJson
- [ ] 2.12 Health/Ready retornam `Failure` (esperado offline)
- [ ] 2.13 Audit trail retorna lista vazia (remote-only)

**Testes:** Um teste por metodo — grava, le de volta, valida estado do Isar e SyncQueue.

---

### Etapa 3: Implementar OfflineFirstRepository (social_care_desktop)

**Objetivo:** Orquestrador que decide local vs remote conforme conectividade.

- [ ] 3.1 Criar classe `OfflineFirstRepository implements SocialCareContract`
- [ ] 3.2 Injetar dependencias: `LocalSocialCareRepository`, `SocialCareBffRemote`, `ConnectivityService`, `SyncEngine`
- [ ] 3.3 Implementar write path: gravar local -> enqueue -> se online, sync imediato
- [ ] 3.4 Implementar read path: se online, remote + atualiza cache; se offline, cache local
- [ ] 3.5 Implementar lookup cache-aside com invalidacao de 24h
- [ ] 3.6 Metodo `prefetchLookupTables()` — pre-carrega todas as 13 tabelas no boot

**Testes:**
- Cenario online: escrita vai para local + remote, leitura vem do remote
- Cenario offline: escrita vai para local + queue, leitura vem do cache
- Cenario transicao: offline -> online dispara sync
- Cenario cache miss: offline + sem cache = Failure

---

### Etapa 4: Completar SyncEngine (social_care_desktop)

**Objetivo:** Motor de sincronizacao completo com retry, backoff e conflict detection.

- [ ] 4.1 Implementar `_dispatchAction` com switch/case para todos os 17 action types
- [ ] 4.2 Reconstituicao: cada case deserializa o payloadJson de volta para domain objects via `PatientMapper.fromJson` e sub-mappers
- [ ] 4.3 Implementar exponential backoff: `nextRetryAt = now + min(2^retryCount * 5s, 5min)`
- [ ] 4.4 Implementar max retries (10) — apos 10 tentativas, marca FAILED permanente
- [ ] 4.5 Implementar deteccao de conflito: se remote retorna 409, marcar CONFLICT + guardar detalhes
- [ ] 4.6 Apos sync bem-sucedido de escrita: buscar versao fresca do patient e atualizar cache local (garante version atualizada)
- [ ] 4.7 Timer periodico (30s) para retentar acoes PENDING quando online
- [ ] 4.8 `SyncStatus` notifier: idle, syncing, pending(n), error(n), conflict(n)
- [ ] 4.9 Garantir idempotencia: se a mesma action for enviada 2x, o backend deve lidar (actionId como idempotency key)

**Testes:**
- Fila com 3 acoes: primeira OK, segunda falha rede (para), terceira nao tenta
- Retry com backoff: validar que nextRetryAt cresce exponencialmente
- Conflito 409: acao marcada CONFLICT, fila continua
- Falha de negocio 4xx: acao marcada FAILED, fila continua
- Status notifier: validar transicoes idle -> syncing -> pending -> idle

---

### Etapa 5: SyncStatus para a UI (core ou social_care_desktop)

**Objetivo:** Expor estado de sincronizacao para que a UI possa mostrar indicadores.

- [ ] 5.1 Criar `SyncStatus` sealed class:
  ```
  SyncStatus
    - idle                    // Nada pendente, tudo sincronizado
    - syncing(int total)      // Processando fila
    - pending(int count)      // Online mas aguardando (retry timer)
    - offline(int count)      // Sem conexao, N acoes aguardando
    - error(int count)        // N acoes falharam permanentemente
    - conflict(int count)     // N conflitos para resolver
  ```
- [ ] 5.2 `SyncEngine` expoe `ValueNotifier<SyncStatus> syncStatus`
- [ ] 5.3 Criar widget `SyncIndicator` (atom) — icone + badge com contagem
  - Verde: idle
  - Azul animado: syncing
  - Amarelo: pending/offline
  - Vermelho: error/conflict
- [ ] 5.4 Integrar SyncIndicator no Shell (AppBar ou StatusBar)

**Testes:** Widget test para cada estado do SyncIndicator.

---

### Etapa 6: Integracao e DI (social_care_desktop + shell)

**Objetivo:** Tudo conectado e inicializado no boot do app.

- [ ] 6.1 No `root.dart` do Shell, inicializar:
  1. `IsarService.init()`
  2. `ConnectivityService.initialize()`
  3. `SyncQueueService(isarService)`
  4. `LocalSocialCareRepository(isarService, queueService)`
  5. `SocialCareBffRemote(baseUrl, authToken, actorId)`
  6. `SyncEngine(queueService, connectivityService, remoteBff)`
  7. `OfflineFirstRepository(localRepo, remoteRepo, connectivity, syncEngine)`
  8. `SyncEngine.start()`
- [ ] 6.2 Expor `OfflineFirstRepository` como `SocialCareContract` via Provider
- [ ] 6.3 Expor `SyncEngine.syncStatus` via Provider para o SyncIndicator
- [ ] 6.4 Chamar `offlineFirstRepo.prefetchLookupTables()` apos auth bem-sucedida
- [ ] 6.5 No logout: `SyncEngine.stop()`, limpar Isar se necessario

**Testes:** Integration test: boot completo -> login -> prefetch -> escrita offline -> reconexao -> sync.

---

### Etapa 7: Testes de Integracao End-to-End

**Objetivo:** Validar cenarios reais de uso offline.

- [ ] 7.1 **Cenario: Happy path online** — registrar paciente, ler de volta, validar cache atualizado
- [ ] 7.2 **Cenario: Escrita offline** — desconectar, registrar paciente, reconectar, validar sync automatico
- [ ] 7.3 **Cenario: Multiplas escritas offline** — 5 acoes offline, reconectar, validar ordem de sync
- [ ] 7.4 **Cenario: Leitura offline** — cache quente, desconectar, ler paciente do cache
- [ ] 7.5 **Cenario: Cache frio** — sem cache, offline, leitura retorna Failure
- [ ] 7.6 **Cenario: Lookup pre-fetch** — boot online, prefetch, desconectar, lookups disponiveis
- [ ] 7.7 **Cenario: Conflito** — editar offline, simular 409 no sync, validar status CONFLICT
- [ ] 7.8 **Cenario: Retry** — falha de rede durante sync, validar backoff e retry automatico

---

## 6. Dependencias entre Pacotes (apos Fase 4)

```
persistence (Isar schemas)
     ^
     |
core (IsarService, SyncQueueService)
     ^
     |
network (ConnectivityService)
     ^
     |
shared (SocialCareContract, domain models, PatientMapper)
     ^
     |
social_care_desktop
  +-- LocalSocialCareRepository   (persistence + core + shared)
  +-- SocialCareBffRemote         (shared + network)
  +-- SyncEngine                  (core + network + shared)
  +-- OfflineFirstRepository      (tudo acima)
```

---

## 7. Criterios de Conclusao

A Fase 4 esta concluida quando:

- [ ] Todas as 7 etapas completas
- [ ] 21 metodos do contrato funcionam offline (escrita local + enqueue)
- [ ] 21 metodos do contrato funcionam online (write-through + cache update)
- [ ] SyncEngine drena fila automaticamente ao reconectar
- [ ] Retry com backoff funcional (testado)
- [ ] Conflict detection funcional para version mismatch (testado)
- [ ] Lookup tables pre-carregadas no boot e disponiveis offline
- [ ] SyncStatus exposto e visivel na UI (SyncIndicator)
- [ ] Testes de integracao end-to-end passando
- [ ] Zero regressao nos testes existentes (Fases 1-3)
