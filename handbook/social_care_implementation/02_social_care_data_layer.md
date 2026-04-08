# Data Layer: Infraestrutura, Contratos e Repositórios

A camada de dados no pacote `social_care` é estritamente responsável pela integração com o BFF (Backend For Frontend), tradução de DTOs para modelos de domínio/UI e mapeamento de erros brutos da API para a hierarquia tipada `SocialCareError`.

## 1. Comandos / Intents (`lib/src/data/commands/`)
Intents são objetos imutáveis (via `Equatable`) que capturam o estado bruto da UI no momento exato de uma submissão. Eles atuam como DTOs de entrada (Input Ports) para a camada de Lógica (UseCases e Mappers).

**Principais Intents:**
- `RegisterPatientIntent`: Contém todos os campos do Wizard de cadastro da Pessoa de Referência (Passo 0 ao 6). Inclui primitivas (`String`, `DateTime`, `bool`) e listas de DTOs aninhados da UI. Note que **não contém entidades do domínio ricas**.
- `AddFamilyMemberIntent`, `UpdatePrimaryCaregiverIntent`: Comandos isolados, projetados especificamente para a mutação de composição familiar no modal de tela "Composição Familiar".
- Intents de Assessment (`UpdateHousingConditionIntent`, `UpdateSocioEconomicIntent`, etc.): Espelham estritamente as propriedades manipuladas em uma seção específica das Fichas do paciente.
- Intents de Intervenção (`RegisterAppointmentIntent`, `ReportViolationIntent`, `CreateReferralIntent`).

**Regra Absoluta:** Toda ação de mutação complexa orquestrada na UI DEVE ser empacotada em um `Intent` específico antes de ser enviada ao UseCase. A UI **nunca** deve construir entidades finais de domínio (`Patient`, `FamilyMember`) de forma artesanal. O `Intent` é o transporte limpo.

## 2. Serviços / HTTP Client (`lib/src/data/services/`)
A classe `HttpSocialCareClient` implementa a interface `SocialCareContract` utilizando a biblioteca `Dio`. É a implementação web do pacote.

### 2.1 Padrões de Autenticação e Requisição
- **Endpoint Web BFF:** As chamadas usam `baseUrl: '/api'` (relativo). A aplicação confia no ingress/proxy server da arquitetura para resolver e redirecionar `'/api'` ao backend correto da infraestrutura de cluster.
- **Cookies Automáticos (Sem Headers MANUAIS):** O Dio é configurado com `extra: {'withCredentials': true}`. Não há a injeção do header `Authorization: Bearer <token>`. A autorização flui naturalmente pelos SameSite cookies configurados pelo sistema de autenticação `Zitadel OIDC`.
- **Identidade Contextual:** O Header `X-Actor-Id` é extraído e injetado do lado do servidor via middleware/sessão. O frontend web ignora tal preenchimento em seus endpoints BFF.

### 2.2 Mapeamento Esgotante de Erros (Obrigatório)
O cliente intercepta toda e qualquer resposta do `Dio` para proteger as camadas superiores. O retorno do método será **SEMPRE** de tipo `Failure<SocialCareError>` ou `Success<Type>`. O `try/catch` encerra sua vida útil aqui.

**Mecânica do Parse (`_failureFromResponse` e `_failureFromException`):**
1. Falhas da camada de rede pura (`DioExceptionType.connectionTimeout`, erro de DNS) geram um `NetworkError(e.message)`.
2. Exceções não esperadas geram `UnexpectedSocialCareError(e)`.
3. A resposta bruta de erro HTTP é tratada avaliando o corpo em JSON: `{"error": "CÓDIGO: Mensagem legível"}`. O código é extraído via expressão regular.
4. **Mapeamento Explícito dos Códigos Base:**
   - `"REGP-001"` ou `"PAT-409"` ou status 409 ➡️ Traduz para domínio como `DuplicatePatientError()`.
   - `"VAL-001"` ou `"PAT-003"` ➡️ Traduz para domínio como `InvalidDataError(message)`.
   - `"PAT-008"` ➡️ Traduz para domínio como `PrMemberRequiredError()`.
   - `"PAT-009"` ➡️ Traduz para domínio como `MultiplePrimaryReferencesError()`.
   - Outros códigos desconhecidos ➡️ Traduzem para o container `ServerError(httpStatus, backendCode, backendMessage)`. O `backendMessage` já vem pronto para ser exibido pela UI.

## 3. Repositórios (`lib/src/data/repositories/`)
Os repositórios definem as interfaces Abstratas do domínio (Portas de Saída). Suas implementações (ex: `BffPatientRepository`) recebem a injeção do Client de Serviços.

### 3.1 Tradutores de Camada Média (Translators / API Models)
Modelos de API (ex: `PatientDetail`) residem em `data/models` apenas com regras de fábrica como `fromJson`. O Repositório é quem os evoca.
A camada Data adota **Translators** que fazem a triagem bidirecional de objetos DTO x Modelos da UI/Domínio.
- **`PatientDetailTranslator.toPatientDetail(Patient patient)`:** A UI da página inicial pede um JSON gigante "achatado" para listar no Painel de Dados, o `PatientDetail`. O Repositório pega o modelo complexo e de grafos aninhados (`Patient`) e o converte estaticamente para essa representação achatada (`PatientDetail` e `FamilyMemberDetail`).
- **`PatientSummaryApiModel` / `PatientSummary`:** Reduz centenas de propriedades de um paciente do banco num objeto levíssimo para povoar os cards listados do componente visual à esquerda da interface.

**Regra Absoluta:** O Repositório é o **ÚNICO** ator do sistema onde a transmutação entre um objeto remoto com chaves como "icdCode" converte-se nos Modelos tipados finais. Os `UseCases` repudiam JSON e o ViewModel recusa contato com as origens de API.