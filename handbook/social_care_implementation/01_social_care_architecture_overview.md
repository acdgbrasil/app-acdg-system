# Visão Geral da Arquitetura: Pacote Social Care

Este documento fornece a visão geral da arquitetura utilizada no pacote `@packages/social_care`. A arquitetura segue rigorosamente os padrões **MVVM (Model-View-ViewModel)** na camada de apresentação, combinado com **Clean Architecture Funcional** para as regras de negócio e camada de dados.

## 1. Topologia de Diretórios (`lib/src/`)

- `constants/`: Valores fixos, dicionários de estados (UF) e strings de localização (Ln10).
- `data/`: Modelos de API (DTOs), Intents (Comandos/Payloads), Repositórios e Serviços (HTTP Clients).
- `domain/`: Regras de negócio essenciais, Schemas de validação (zard) e definição de Erros (`SocialCareError`).
- `logic/`: Casos de Uso (`use_case/`) e Mappers para agregação de domínio (`mappers/`).
- `ui/`: Telas organizadas por feature (ex: `home/`, `patient_registration/`), separadas em `view/`, `viewModels/`, `models/` (UI Models) e `di/` (Injeção de dependência).

## 2. Fluxo de Dados (Data Flow)

O pacote utiliza o padrão de **Result Pattern** (`Success` e `Failure`) em todas as camadas a partir da `data/` em direção à `ui/`. Exceções não são propagadas (`try/catch` é encapsulado na camada mais baixa).

### 2.1. Upstream (Ação do Usuário -> Backend)
1. **View (UI Component):** O usuário interage com um formulário. O componente UI notifica a mudança para o `FormState`.
2. **FormState (UI):** Avalia regras de validação síncronas simples (ex: campo vazio, regex).
3. **ViewModel (UI):** Monta um objeto `Intent` (ex: `RegisterPatientIntent`) a partir do `FormState` e executa um `Command` do ViewModel.
4. **UseCase (Logic):** O UseCase recebe o `Intent`.
5. **Mapper (Logic):** O UseCase delega ao Mapper (ex: `RegistryMapper`) para validar o `Intent` via Schemas (`zard`) e montar a Entidade de Domínio. Retorna `Result<Entity>`.
6. **Repository (Data):** O UseCase chama o Repositório passando a Entidade de Domínio.
7. **Service (Data):** O Repositório converte a Entidade para JSON (via Translator/Mapper de DTO) e envia para o BFF (via `HttpSocialCareClient`).

### 2.2. Downstream (Backend -> Visualização)
1. **Service (Data):** O BFF retorna um JSON. O `HttpSocialCareClient` traduz erros HTTP e códigos do backend para objetos `SocialCareError`. Se sucesso, mapeia o JSON para um DTO bruto (ex: `PatientRemote`, `PatientSummaryApiModel`).
2. **Repository (Data):** Recebe o DTO do Serviço e o converte para Modelos de Domínio ou Modelos de UI (via `PatientTranslator` ou `PatientDetailTranslator`). Retorna `Result<T>`.
3. **UseCase (Logic):** Retorna o `Result<T>` intacto (ou aplica alguma regra de negócio sobre ele).
4. **ViewModel (UI):** O `Command` recebe o `Result`.
   - Se `Success`: O ViewModel atualiza seu estado local (`ValueNotifier` ou variáveis reativas) e chama `notifyListeners()`.
   - Se `Failure`: Atualiza a mensagem de erro da UI.
5. **View (UI Component):** Escuta o ViewModel (via `ListenableBuilder`) e é reconstruída refletindo os novos dados ou erros.

## 3. Padrões Chave
- **Imutabilidade:** Modelos de domínio, intents e DTOs são estritamente imutáveis (uso de `final` e `const`).
- **Validação Antecipada:** Dados de formulário são validados no momento de instanciar a entidade via `RegistryMapper` usando `zard` (schema validation).
- **Sem Exceções Vazadas:** Tudo o que sai de um `Service` ou `UseCase` deve ser um `Result<T>`.
- **Atomic Design:** Componentes visuais (`view/components/`) são "burros" (Dumb UI), passados via construtor e não acessam Repositórios ou ViewModels diretamente (exceto a Page principal).
