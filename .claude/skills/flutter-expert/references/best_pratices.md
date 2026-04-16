# Best Practices — Lições de Arquitetura e Code Reviews

Regras consolidadas aplicáveis a todo o monorepo frontend, extraídas dos guias de arquitetura e revisões de código.

---

## 1. Dart Moderno (Dart 3+)

### FAZER
- Usar `.firstOrNull` em vez de loops `for` manuais para buscar o primeiro match em listas/enums.
- Usar `.nonNulls` para filtrar nulos de iteráveis — já faz o cast para tipo não-nulo.
- Usar cadeias funcionais (`.map().nonNulls.toSet()`) em vez de loops imperativos com acumuladores mutáveis.
- Retornar `const {}` / `const []` para coleções vazias em caminhos de erro/nulo — evita alocação.

### NÃO FAZER
- Loops `for` imperativos para transformar/filtrar coleções quando existe um operador funcional equivalente.
- `values.byName()` quando o valor buscado difere do nome da variável no enum (ex: `socialWorker` vs `social_worker`).

---

## 2. Igualdade com `Equatable` (mixin do `core`)

Todos os modelos de dados devem usar `with Equatable` de `package:core/core.dart`. **Nunca** implementar `==`/`hashCode` na mão.

---

## 3. Camada de Dados (Repositories & Services)

### FAZER
- **Repository como Fonte de Verdade:** Cada tipo de dado deve ter um repository único responsável por sua gestão e mutação.
- **Separação clara:** Usar **Services** para APIs externas (sem estado) e **Repositories** para lógica de dados (cache, retry, sincronização).
- **Abstração de Ambiente:** Usar a utilidade `Env` do core para acessar configurações (`--dart-define`), evitando magic strings.

### NÃO FAZER
- Chamar um `Service` diretamente da View ou do ViewModel — o fluxo deve sempre passar pelo `Repository`.
- Ter estado mutável global espalhado — centralize no repository.

> **Referência Detalhada:** Veja o guia completo sobre a [Camada de Dados](./data_layer.md).

---

## 4. Camada de Lógica (UseCases & Orchestrators)

### FAZER
- **UseCases para Orquestração:** Extrair lógicas que envolvam múltiplos repositories ou regras de negócio complexas para classes `UseCase` (que estendem `BaseUseCase`).
- **Isolamento do ViewModel:** O ViewModel deve depender de `UseCases` para executar ações, e não diretamente dos Repositories.
- **Result Type:** UseCases devem sempre retornar um `Result<T>` para garantir tratamento de erro uniforme.

### NÃO FAZER
- Colocar lógica de orquestração de dados complexa diretamente no ViewModel.
- Ignorar o estado de erro retornado por um UseCase.

---

## 5. Camada de UI (MVVM & Atomic Design)

### FAZER
- **Atomic Design:** Organizar a UI em pastas hierárquicas:
    - `atoms/`: Componentes básicos e puros (AppLogo, Badge).
    - `molecules/`: Combinação de atoms com lógica visual (UserMenu, ModuleCard).
    - `organisms/`: Seções completas e independentes (HomeContent, NavBar).
    - `pages/`: Telas que compõem organismos e se conectam ao ViewModel.
- **Padrão Command:** Usar objetos `Command` (do core) nos ViewModels para gerenciar o estado das ações (loading, error, completed).
- **ListenableBuilder:** Reagir aos comandos na UI usando `ListenableBuilder` para rebuilds cirúrgicos.

### NÃO FAZER
- Criar widgets gigantes com centenas de linhas — se tem mais de uma responsabilidade visual, divida em átomos ou moléculas.
- Gerenciar estados de "busy/loading" manualmente com variáveis booleanas no ViewModel.

> **Referência Detalhada:** Veja o guia completo sobre a [Camada de UI](./ui_layer.md).

---

## 6. Inicialização e Orquestração (Root vs Main)

### FAZER
- **Main Limpo:** O arquivo `main.dart` deve conter apenas o `runApp(Root())` e inicializações críticas do Flutter.
- **Root Orquestrador:** Criar um widget `Root` (em `lib/root.dart`) responsável por montar a árvore de injeção de dependências (Providers) na ordem correta: `Data -> Logic -> UI`.
- **Injeção por Camadas:** Expor Repositories e UseCases via `Provider` para que possam ser consumidos em qualquer lugar da árvore.

### NÃO FAZER
- Instanciar Repositories ou Services dentro de cada tela — centralize no Root ou via DI.
- Poluir o `main.dart` com lógicas de decisão de plataforma ou credenciais.

---

## 7. Testabilidade e Fakes

### FAZER
- **Fakes em vez de Mocks:** Criar `FakeRepositories` e `FakeUseCases` para testes de UI e ViewModel. Eles são mais estáveis e fáceis de manter.
- **Injetar Tempo:** Passar `DateTime? now` opcional em métodos que dependem da hora atual.

### NÃO FAZER
- Chamar `DateTime.now()` diretamente em lógica testável.
- Depender de injeção global real em testes unitários.

> **Referência Detalhada:** Veja o guia completo sobre [Testes](./tests.md).

---

## Referências e Leituras Adicionais

- **[Referência de Implementação](../../architecture/IMPLEMENTATION_REFERENCE.md):** Exemplos reais de código seguindo estes padrões.
- **[Padrões de Projeto](./patterns.md):** Catálogo completo de padrões utilizados no frontend.
- **[Comunicação entre Camadas](./layer_communication.md):** Detalhes técnicos sobre como os componentes se conectam.
