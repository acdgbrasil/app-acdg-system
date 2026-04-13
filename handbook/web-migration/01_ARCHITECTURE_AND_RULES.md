# ACDG Web Migration (React + Deno) - Gold Standard Funcional

Este documento é a **Lei Arquitetural Suprema** para a construção da SPA Web do ecossistema ACDG. Ele adapta a nossa necessidade de Separação Explícita de Camadas e Segurança Máxima para a natureza do React Funcional e TypeScript Moderno.

Qualquer Agente de Inteligência Artificial ou Desenvolvedor que atue neste projeto DEVE seguir estas regras. Desvios resultarão em rejeição imediata no Code Review.

---

## 🏗️ 1. A Stack Tecnológica
- **Runtime & Tooling:** `Deno` (Secure by default, Test runner, Linter, Formatter). 
- **Linguagem:** `TypeScript 6` (Strict mode absoluto, `exactOptionalPropertyTypes`, `noUncheckedIndexedAccess`).
- **Ecossistema UI:** `React` funcional puro + `Vite`.
- **Estilização:** `styled-components` (CSS-in-JS, zero CSS inline).
- **Segurança de Contratos (ACL):** `zod` (Barreira de proteção de I/O).
- **Tratamento de Erros:** NATIVO usando Tipos de União Discriminada (Discriminated Unions) do TypeScript. **Zero dependências externas (Nada de neverthrow).**

---

## 🏛️ 2. A Arquitetura: Clean Architecture Funcional + Command Pattern

O MVVM tradicional (com classes ViewModel de estado mutável) vai contra a natureza funcional e de fluxo unidirecional do React. Para obter **Separação Explícita de Camadas** e **Segurança Máxima**, usaremos uma abordagem orientada a Comandos (CQRS/Actions) com Fronteiras Rígidas.

### 🌐 Camada 1: Domain (Core Business & Tipos)
- **100% Pura:** Apenas tipos, interfaces e regras de negócio. Zero imports de React ou bibliotecas externas.
- **Modelos:** Tipos imutáveis (utilize `readonly` modifier do TS 6 em tudo).
- **Result Pattern Nativo:** Implementação manual de `Result` usando Discriminated Unions para evitar `try/catch` vazando:
  ```typescript
  export type Success<T> = { readonly ok: true; readonly value: T };
  export type Failure<E> = { readonly ok: false; readonly error: E };
  export type Result<T, E> = Success<T> | Failure<E>;
  ```

### ⚙️ Camada 2: Application (Actions & Commands)
- Substitui os "UseCases" clássicos por **Commands Funcionais**.
- São funções puras e assíncronas que orquestram a lógica, chamam os repositórios e retornam o nosso `Result` nativo.
- **Segurança Máxima:** Um Command NUNCA lança exceção (`throw`). Ele SEMPRE retorna uma `Failure<DomainError>`.
  ```typescript
  export type RegisterPatientCommand = (patient: Patient, repo: SocialCareRepository) => Promise<Result<PatientId, DomainError>>;
  ```

### 🛡️ Camada 3: Data & ACL (Infrastructure)
- O único lugar onde a rede (`fetch`) existe.
- **Anti-Corruption Layer:** Toda resposta do BFF é interceptada e validada via `zod.safeParse()`.
- Se o backend mandar HTML no lugar de JSON, a ACL barra na hora, encapsula num `Failure<NetworkError>` e protege o Domínio.

### 💻 Camada 4: Presentation (UI & Control)
A interface de usuário deve ser estruturada seguindo rigorosamente a metodologia **Atomic Design** (Atoms, Molecules, Organisms, Templates, Pages).

Dividida em:
1. **Controllers / Dispatchers (Custom Hooks):** 
   - Atuam como o "Controlador" da tela. Eles têm o estado local (ex: `isLoading`) e "despacham" (dispatch) os Commands Funcionais, passando as dependências injetadas.
2. **Views (React Components):** 
   - 100% "Dumb" (Burras). Recebem dados via Props e invocam callbacks. Não sabem o que é um "Command" ou "Repository".
   - **Estilização (CSS-in-JS):** É **TERMINANTEMENTE PROIBIDO** o uso de CSS inline (`style={{...}}`) ou de arquivos `.css` globais soltos. Utilizaremos **`styled-components`** para garantir o escopo local de CSS e facilitar a componentização de *Atoms*.
   ```tsx
   // Exemplo de Atom (Atomic Design)
   import styled from 'styled-components';

   export const PrimaryButton = styled.button`
     background-color: ${props => props.theme.colors.primary};
     border-radius: 8px;
     padding: 12px 24px;
     border: none;
     cursor: pointer;
     
     &:disabled {
       opacity: 0.5;
     }
   `;
   ```

---

## 💉 3. Inversão de Controle e Segurança (Functional DI)

Sem decorators e sem classes mágicas. A injeção de dependência é feita injetando a infraestrutura nos Commands através de Curry/Closures ou passando via parâmetros no Dispatcher (Hook).

**Exemplo de DI Funcional:**
```tsx
// 1. O React Context fornece as dependências (Infra)
const DependenciesContext = createContext<AppDependencies | null>(null);

// 2. O Controlador (Hook) orquestra a injeção
export function useRegisterPatientController() {
  const { repository } = useDependencies();
  const [state, setState] = useState<PageState>(initialState);

  const dispatchSubmit = async (data: Patient) => {
    setState({ isLoading: true });
    // O Command funcional recebe os dados e a infraestrutura injetada
    const result = await registerPatientCommand(data, repository);
    
    if (result.ok) {
      // Sucesso
    } else {
      // Falha Segura
    }
  };

  return { state, dispatchSubmit };
}
```

---

## 🚫 4. Regras de Segurança da Informação (Max Security)

1. **Deny by Default:** O Deno rodará sem acesso ao sistema de arquivos e rede por padrão. Permissões estritas (`--allow-net=bff.acdg.org`) serão configuradas no start da aplicação.
2. **Zero Duck Typing:** Tudo que entra no sistema é validado no runtime (Zod) e no tempo de compilação (TS 6). NUNCA use o operador `as`.
3. **Erros Mascarados:** A View nunca recebe o "Error" puro do Javascript. Ela só conhece `DomainError` tipado. Isso previne vazamento de stack traces e dados sensíveis do BFF para a interface do usuário.

---

## 🧪 5. Testes (TDD Funcional)
- Como os Commands são funções puras (recebem o repositório como parâmetro), eles são 100% testáveis isoladamente, sem precisar montar a árvore do React.
- Mocks são apenas objetos simples que implementam a interface do Repositório.
- A fase RED do TDD deve sempre começar pelo Command garantindo que todas as ramificações de erro (Falha de Validação, Falha de Rede, Duplicidade) retornem a `Failure` correta sem lançar `throws`.
