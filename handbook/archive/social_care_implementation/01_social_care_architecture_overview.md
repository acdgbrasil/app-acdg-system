# Visão Geral da Arquitetura: Pacote Social Care

Este documento fornece a visão geral da arquitetura de alta resolução utilizada no pacote `@packages/social_care`. A arquitetura segue rigorosamente os padrões **MVVM (Model-View-ViewModel)** na camada de apresentação, combinado com **Clean Architecture Funcional** para as regras de negócio e camada de dados. Este guia foi projetado para orientar agentes de IA em implementações com precisão absoluta ao *Gold Standard* do projeto.

## 1. Topologia de Diretórios (`lib/src/`)

- `constants/`: Valores fixos, dicionários de estados (UF) e obrigatoriamente 100% das strings de localização visual (arquivos Ln10).
- `data/`: 
  - `commands/`: Intents (DTOs de entrada para UseCases).
  - `models/`: DTOs brutos de resposta de API (ex: `PatientDetail`).
  - `repositories/`: Contratos abstratos e implementações de acesso ao BFF.
  - `services/`: Clientes HTTP (Dio) de baixo nível (`HttpSocialCareClient`).
- `domain/`: 
  - `errors/`: Exceções mapeadas com mensagens prontas para a UI (`SocialCareError`).
  - `schemas/`: Regras de validação estritas usando `zard`.
- `logic/`: 
  - `mappers/`: Classes especializadas em montar Entidades de Domínio puras a partir de Intents, aplicando validações.
  - `use_case/`: Orquestradores assíncronos de lógica e infraestrutura.
- `ui/`: Telas organizadas por feature (`home/`, `patient_registration/`, `family_composition/`). Divididas atomicamente em `view/`, `viewModels/`, `models/` e `di/`.

## 2. Fluxos de Dados e Controle de Fluxo Funcional

O pacote repudia o uso de `try/catch` soltos nas camadas altas. Exceções nativas são convertidas no ponto de falha mais baixo e trafegam envelopadas no padrão **Result Pattern** (`Success` e `Failure`).

### 2.1. Upstream (Ação do Usuário -> Backend)
1. **View (Dumb UI Component):** O usuário interage com um formulário. O widget de input notifica a mudança diretamente para um `ValueNotifier` de um objeto `FormState`. Micro-renderizações são feitas usando `ListenableBuilder`.
2. **FormState (UI):** Centraliza o estado dos inputs. Avalia e resolve validações em tempo real (retornando mensagens do Ln10 via getters customizados, ex: `String? get cpfError`).
3. **ViewModel (UI):** Ao clicar em "Salvar", consolida os diversos `FormState`s montando um objeto `Intent` imutável (ex: `RegisterPatientIntent`). Aciona o método `execute(intent)` de um `Command1` do pacote `core`.
4. **UseCase (Logic):** O UseCase recebe o `Intent`.
5. **Mapper (Logic):** O UseCase invoca um Mapper (ex: `RegistryMapper.toPatient`) que:
   - Valida os dados primitivos do Intent via `zard` (Schema validation).
   - Instancia `ValueObjects` estritos (`Cpf`, `TimeStamp`).
   - Monta o Agregado de Domínio (`Patient`).
   - Retorna um `Result<Patient>`.
6. **Repository (Data):** Em caso de sucesso do Mapper, o UseCase entrega a entidade para o Repositório, invocando o seu contrato abstrato.
7. **Service (Data):** O Repositório converte a entidade para um Payload JSON tipado (ex: via `PatientTranslator`) e faz o POST via `HttpSocialCareClient`.

### 2.2. Downstream (Backend -> Visualização)
1. **Service (Data):** O BFF retorna um JSON. 
   - Se houver falha de rede ou timeout do `Dio`, gera-se um `Failure(NetworkError(msg))`.
   - Se for erro HTTP, o corpo `{"error": "CODIGO: mensagem"}` é parseado. O `CODIGO` é traduzido forçadamente para a taxonomia do domínio (ex: `"REGP-001"` vira `DuplicatePatientError()`).
2. **Repository (Data):** Recebe o DTO remoto validado do Serviço (ex: `PatientRemote`) e o converte para Modelos de Domínio ou UI Models otimizados (ex: `PatientDetailTranslator.toPatientDetail`).
3. **UseCase (Logic):** Retorna o `Result<T>` intacto (ou aplica as últimas regras de negócio contextuais).
4. **ViewModel (UI):** O `Command` recebe o `Result`.
   - Se `Success`: O ViewModel atualiza seu estado, listas ou chaves internas, emitindo `notifyListeners()`.
   - Se `Failure`: O erro mapeado (já contendo a mensagem em português legível dentro do seu método `.toString()`) preenche uma variável ou gatilho de erro.
5. **View (Dumb UI Component):** O Consumer Widget observa as mudanças, oculta os Loaders e exibe os Toasts ou Modais de Erro através de helpers dedicados (`RegistrationToast`, `RegistrationErrorModal`).

## 3. Filosofias Indispensáveis
- **Atomic Design (Dumb UI):** Páginas são apenas carcaças montadoras. Qualquer componente funcional e de input é extraído para `components/` recebendo exclusivamente callbacks, notifiers e controllers.
- **Validação Esgotante em Tempo de Instanciação:** Dados inválidos jamais viram um Model de Domínio. A fronteira dos `Mappers` blinda a Lógica e os Repositórios de lixo da UI.
- **Micro-Renderizações:** Não usar `setState` na classe da página para repintar 30 campos quando um único campo altera seu erro. Utilizar `ValueListenableBuilder` focados em cada campo.