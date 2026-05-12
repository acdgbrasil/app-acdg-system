# Auditoria Arquitetural Detalhada — Motor Offline e Sincronização
**Data:** 02 de Abril de 2026
**Especialista:** flutter-arch-review (Gemini CLI)

Esta auditoria concentrou-se na verificação do motor de sincronização (*Offline-First*) e do fluxo de mutações de dados no projeto `social_care`, com foco no `SyncQueueService` e nas implementações de Repositórios.

A principal suspeita era de que os comandos de mutação estivessem "furando" a fila offline e chamando o BFF diretamente devido à existência do `BffPatientRepository`.

---

## 1. Veredito de Segurança dos Dados (Offline-First)

**Status:** 🟢 **SEGURO (Com ressalvas estruturais)**

A investigação confirmou que **não há perda de dados** em ambientes sem conexão. Todas as mutações (Create/Update/Delete) estão, de fato, passando pela `SyncQueueService` e sendo persistidas localmente no Drift antes do envio.

**Como o fluxo realmente funciona:**
1. A UI chama o `PatientRegistrationViewModel` (ou UseCases).
2. O UseCase chama o `BffPatientRepository`.
3. O `BffPatientRepository` (apesar do nome infeliz) **não chama a rede diretamente**. Ele delega a chamada para a interface `SocialCareContract` (`_bff`).
4. No contêiner de injeção de dependências (`dependency_builders.dart`), o `SocialCareContract` instanciado é o **`OfflineFirstRepository`**.
5. O `OfflineFirstRepository` envia a mutação para o **`LocalSocialCareRepository`**.
6. O `LocalSocialCareRepository` executa o método genérico `_mutatePatient`, que **atualiza o banco local (`Drift`)** e imediatamente chama `_queueService.enqueue(...)`.

Portanto, a integridade *Offline-First* está garantida. No entanto, o código possui falhas graves de Clean Architecture e Nomenclatura que causam extrema confusão.

---

## 2. Anti-padrões e Problemas Arquiteturais Encontrados

### 2.1. Nomenclatura Enganosa (`BffPatientRepository`)
**Problema:** O repositório central do módulo Flutter chama-se `BffPatientRepository`, sugerindo que ele acopla o app diretamente ao backend (BFF).
- **Por que é errado:** Esse repositório na verdade atua como um *Facade* ou *Adapter* genérico que recebe um `SocialCareContract` genérico (que offline é o banco local). O prefixo `Bff` quebra a abstração e confunde qualquer desenvolvedor lendo o código.
- **Padrão Correto:** Renomear para `PatientRepositoryImpl` ou `AppPatientRepository`.

### 2.2. Acoplamento de Contrato com Tipos Dinâmicos (`Map<String, dynamic>`)
**Problema:** O método `listPatients()` do `SocialCareContract` (e repassado pelo `PatientService`) obriga o retorno de um `List<Map<String, dynamic>>`.
- **Por que é errado:** Em uma Clean Architecture, os contratos de Repositório/Serviço devem retornar Entidades de Domínio ou DTOs estritos. Para contornar isso, o `LocalSocialCareRepository` (banco de dados local) foi forçado a implementar um *parser* macabro (`_extractSummary`) que "finge" ser a resposta JSON da API do Backend, apenas para que o `BffPatientRepository` possa rodar um `PatientSummaryApiModel.fromJson()` nele. Isso é um acoplamento reverso inaceitável.
- **Padrão Correto:** O `SocialCareContract` deve retornar `List<PatientSummary>` (DTO estrito) ou `List<Patient>`. O Repositório Local deve ler do banco e mapear para esse DTO usando um Mapper, sem fingir ser um JSON de rede.

### 2.3. Lógica de UI (Fichas) Vazando para o Repositório de Dados
**Problema:** A conversão de `Patient` para o modelo de tela `PatientDetailResult` e a derivação de `FichaStatus` estão ocorrendo dentro de `BffPatientRepository` (`_toDetailResult`).
- **Por que é errado:** Determinar se a "Ficha de Saúde" está preenchida (`FichaStatus`) é uma regra puramente de Apresentação (View/ViewModel). O Repositório deve simplesmente retornar a Entidade `Patient`.
- **Padrão Correto:** O Repositório retorna `Patient`. O UseCase retorna `Patient`. O ViewModel (`HomeViewModel` ou `FamilyCompositionViewModel`) pega o `Patient` e o mapeia para o modelo de estado da View (`PatientDetail` e `FichaStatus`).

### 2.4. A Fila de Sincronização (`SyncQueueService`)
**Status:** 🟢 Excelente.
O serviço `SyncQueueService` foi migrado para um modelo reativo (`watchPendingActions`) baseado em Streams do Drift. Ele lida corretamente com a lógica de exclusão temporal e *Exponential Backoff* para tentativas falhas (`nextRetryAt`). Não há intervenções necessárias no coração da fila.

---

## 3. Plano de Ação Recomendado (Saneamento do Fluxo)

1. **Renomeação Imediata:** 
   - Renomear `BffPatientRepository` para `PatientRepositoryImpl`.
   - Renomear `BffLookupRepository` para `LookupRepositoryImpl`.

2. **Limpeza de Contrato (Fim do `Map<String, dynamic>`):**
   - Alterar a assinatura de `listPatients` no `SocialCareContract` e `PatientService` para retornar `Result<List<PatientSummary>>`.
   - Remover a gambiarra de geração de JSON no método `_extractSummary` do banco local (`LocalSocialCareRepository`) e fazê-lo retornar objetos `PatientSummary` tipados diretamente.

3. **Remoção de UI do Repositório:**
   - Transferir a lógica de `_toPatientDetail` e o mapeamento de `FichaStatus` do Repositório para Mappers na camada `logic` ou diretamente dentro do `GetPatientUseCase`.

---
**Conclusão:** 
O medo de perda de dados é infundado; o sistema salva localmente de maneira robusta. Porém, a forma tortuosa como os Repositórios simulam respostas de API e vazam a orquestração de UI gera uma barreira imensa para a manutenibilidade do projeto e deve ser refatorada imediatamente.