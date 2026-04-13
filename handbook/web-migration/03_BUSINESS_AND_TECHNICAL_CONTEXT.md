# Contexto de Negócio e Técnico (The ACDG Knowledge Base)

Este documento é a **Bíblia de Contexto** do projeto ACDG. Ele consolida o conhecimento sobre *o que o software faz*, *como se integra*, *variáveis de ambiente*, *regras de domínio* e *autenticação*. Qualquer IA que for escrever um Command, Repository ou Controller DEVE consultar este documento para entender as regras do jogo.

---

## 1. O Produto (O que o software faz?)

O **Sistema ACDG** é uma plataforma de gestão de assistência social e saúde para pacientes com doenças genéticas raras. 
O sistema realiza o cadastro unificado de pacientes (Integrado a um serviço de Identidade chamado *people-context*), mapeia suas famílias, avalia vulnerabilidades (Socioeconômicas, Habitacionais, Educação, Saúde) e registra todo o histórico de cuidados, acolhimentos e violações de direitos.

### Módulos do Sistema:
1. **Registry:** Cadastro do Paciente (Pessoa de Referência - PR), Identidade Social, Membros Familiares e Cuidador Principal.
2. **Assessment (Avaliações):** Habitacional, Socioeconômica, Trabalho/Renda, Escolaridade, Saúde, Rede de Apoio e Resumo Social.
3. **Care (Cuidado):** Atendimentos e Informações de Ingresso.
4. **Protection (Proteção):** Histórico de Acolhimento, Violação de Direitos, Encaminhamentos.
5. **Audit:** Trilha de auditoria das modificações.

---

## 2. Autenticação e Segurança (Zitadel OIDC)

A autenticação utiliza o **Zitadel** no padrão OIDC (OpenID Connect) com PKCE.

- **Fluxo Web (Split-Token Pattern):** 
  - O **Access Token (JWT)** é armazenado **em memória** no React (NUNCA em localStorage).
  - O **Refresh Token** é armazenado em um **Cookie** `HttpOnly + Secure + SameSite=Strict` gerenciado pelo BFF/Servidor para o "Silent Refresh".
- **Headers Obrigatórios:**
  - `Authorization: Bearer <JWT_TOKEN>`
  - `X-Actor-Id: <UUID>` (Obrigatório para mutações POST/PUT/DELETE. É o ID do usuário logado).
- **Roles (RBAC):** Baseadas na claim `urn:zitadel:iam:org:project:roles`.
  - `social_worker`: Leitura e escrita (CRUD).
  - `owner`: Somente leitura.
  - `admin`: Leitura completa + Gestão.

---

## 3. Ambientes e Variáveis de Ambiente (Deno)

Nunca hardcode URLs. No Deno, as variáveis devem ser lidas usando `Deno.env.get('NOME_DA_VAR')`. A ausência de variáveis vitais no boot deve quebrar a aplicação (Fail-Fast).

### Variáveis Obrigatórias:
- `APP_ENV`: `dev` | `staging` | `production`
- `OIDC_ISSUER`: URL do Zitadel (ex: `https://auth.acdgbrasil.com.br`)
- `OIDC_CLIENT_ID`: ID da aplicação no Zitadel.
- `BFF_BASE_URL`: URL do BFF Social Care.
  - *Prod:* `https://social-care.acdgbrasil.com.br`
  - *Hml:* `https://social-care-hml.acdgbrasil.com.br`
  - *Dev:* `http://localhost:3000`
- `PEOPLE_CONTEXT_BASE_URL`: URL do microsserviço de identidades.

---

## 4. Contratos de API e ACL (Zod)

O backend (Swift/Vapor) possui regras estritas de serialização que **devem ser protegidas pela ACL no frontend via Zod**.

### Padrão de Resposta
Todas as requisições de sucesso (`200`, `201`) retornam um `StandardResponse`:
```json
{
  "data": { ... payload aqui ... },
  "meta": { "timestamp": "2026-03-19T10:30:00Z" }
}
```

### Padrão de Erro (Domain Errors)
A IA deve mapear os erros retornados pela API para o tipo `Result` do `neverthrow` funcional (`Failure<DomainError>`).
```json
{
  "error": {
    "code": "PAT-001",
    "message": "CPF Inválido"
  }
}
```

### Regras de Formatação Obrigatórias:
- **Datas:** Devem ser estritamente **ISO8601 completo** (`YYYY-MM-DDTHH:mm:ss.SSSZ`). Enviar `YYYY-MM-DD` gera erro `400`.
- **Enums:** 
  - `sex`: `"masculino"` ou `"feminino"` (Sempre minúsculo em português).
  - `residenceLocation`: `"URBANO"` ou `"RURAL"` (Sempre UPPERCASE).
- **Arrays Vázios:** Arrays vazios devem ser `[]` reais no JSON.

---

## 5. Regras de Negócio Estritas (Para TDD e Commands)

A camada de Domínio (Commands) deve respeitar (e possuir testes) para as seguintes validações:

### 1. People Context e Registro de Pacientes
Antes de salvar um paciente (`POST /api/v1/patients`), o Frontend precisa **enriquecer** o payload:
1. Deve chamar a API do `people-context` (`registerPerson`) passando Nome, Data de Nascimento e CPF (se houver).
2. A API do `people-context` retornará um `personId` canônico.
3. Esse `personId` é injetado no payload do Paciente e dos Membros Familiares.
4. *Gracedul Degradation:* Se o `people-context` cair, usamos UUIDs gerados localmente e o fluxo continua.

### 2. Unicidade de CPF
- O CPF é validado matematicamente por uma função pura no frontend (não confie em bibliotecas genéricas visuais).
- Ao registrar, o sistema acusa erro `REGP-001` se o CPF já existir. A UI não deve redirecionar a tela, mas mostrar um erro na página para correção.

### 3. Validações Condicionais (MetadataValidator)
Certas opções nos Dropdowns (tabelas `dominio_`) exigem que outros campos sejam preenchidos:
- Tabela `dominio_tipo_beneficio`:
  - Se a flag `exige_registro_nascimento` for `true`, o campo `birthCertificateNumber` é obrigatório.
  - Se a flag `exige_cpf_falecido` for `true`, o campo `deceasedCpf` é obrigatório.
- Tabela `dominio_tipo_violacao`:
  - Se a flag `exige_descricao` for `true`, o campo `descriptionOfFact` não pode ser vazio.

### 4. Validações Cruzadas Complexas (CrossValidator)
- **Gestantes:** Na aba de Saúde (`health-status`), se o `memberId` for o da Pessoa de Referência (Paciente Principal) e ela for declarada gestante, o sistema validará se o `sex` no People Context é `"feminino"`. Se for `"masculino"`, a API rejeita com `422`.
- **Acolhimento:** No histórico de acolhimento (`placement-history`), o `endDate` (se existir) DEVE ser `>= startDate`.
- Se for marcada "Guarda por terceiros" ou "Internação de adolescente", a família DEVE ter membros cadastrados nas faixas etárias correspondentes (< 18 anos ou entre 12-17 anos).

---

## 6. Dicionário de Mapeamento (Flutter para React/Deno Funcional)

Para os desenvolvedores e IAs que estão portando o código Flutter original para a nova SPA Funcional:

| Conceito Antigo (Flutter) | Novo Conceito (React/Deno SPA) | Regra / Implementação |
| :--- | :--- | :--- |
| `ChangeNotifier` / `BaseViewModel` | **Custom Hook (`useXController`)** | O estado vive no `useState` ou `useReducer`. O Hook retorna apenas dados e funções puras (Dispatchers). |
| `ValueNotifier` | **useState** ou **useReducer** | Mutação substituída por cópias imutáveis. |
| `UseCase` (Classes) | **Commands Funcionais** | Função pura `async (data, dependencies) => Promise<Result<T, E>>`. O `Result` é um tipo Custom baseado em Discriminated Unions. |
| `Repository` (Abstract Classes) | **Funcional / Interfaces TS** | O repositório faz a chamada (`fetch`), passa a resposta pelo parser do **Zod** (Anti-Corruption Layer) e retorna o `Result`. |
| Dependências (GetIt / Provider) | **React Context (`useDependencies`)** | A raiz da aplicação provê os Repositories e Services. O Custom Hook extrai via `useContext` e os injeta nos Commands. |
| Formulários & Máscaras (Formz) | **Hooks Form + Controllers** | View é burra. O Hook controla o "dirty state". As validações ocorrem em funções puras na camada de domínio (ex: matemática de CPF). |
| ValueOrNull / Duck Typing | **Zod Schema + Pattern Matching** | Em Typescript NUNCA usamos `as MyType`. A resposta da rede SEMPRE passa por um `zod.safeParse()`. |
| Widget / Tela | **View (Componente React + Styled Components)** | JSX 100% puro visualmente. Sem estilos inline. Responsável apenas pelo Atomic Design. |
