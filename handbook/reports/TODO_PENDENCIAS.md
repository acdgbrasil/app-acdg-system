# Na ficha incluir: Cartão do SUS

# Incluir caso se não possuir Diagnostico
**Resolução:** Usar CID `Z03` — "Observação e avaliação médica por suspeita de doenças" com descrição "Diagnóstico em investigação". O backend exige `initialDiagnoses` não-vazio, então o frontend deve oferecer essa opção quando o paciente não tem diagnóstico fechado. Alternativas: `R69` (doença não especificada, caso geral), `Z03.9` (suspeita não especificada).

---

## Bug: Requests duplicadas (baixo risco)

**Severidade:** Baixa — não causa corrupção, apenas tráfego de rede desnecessário.

**Sintoma:** `GET /patients` e `processQueue()` são disparados múltiplas vezes em sequência no startup e em certas transições de estado.

**Causa raiz:** 3 fontes independentes disparam as mesmas chamadas quase simultaneamente:

1. **SyncEngine.start()** (`sync_engine.dart:41-46`) — faz `pullPatients()` no init + timer periódico a cada 1 minuto
2. **HomeViewModel construtor** (`home_view_model.dart:16`) — `load.execute()` no construtor, que via `OfflineFirstRepository.listPatients()` faz `GET /patients` remoto se cache vazio
3. **Connectivity listener** (`sync_engine.dart:58`) — cada transição offline→online dispara `processQueue()`
4. **_handleWrite** (`offline_first_repository.dart:42`) — cada write local com sucesso dispara `processQueue()`

**Mitigação atual:** A flag `_isProcessing` no `SyncEngine` (`sync_engine.dart:134`) impede execução concorrente — chamadas simultâneas retornam imediatamente.

**Correções sugeridas (quando priorizado):**

1. Adicionar debounce no `processQueue()` — coalescer chamadas dentro de ~500ms
2. `OfflineFirstRepository.listPatients()` não bater no remote quando SyncEngine já fez pull — cache já deveria estar populado
3. Mover `load.execute()` para fora do construtor do HomeViewModel — deixar o widget decidir quando carregar via lifecycle (initState)