# ADRs — Architecture Decision Records

> Registro formal de todas as decisoes arquiteturais do frontend.
> Cada decisao e imutavel apos aceita. Novas decisoes podem substituir anteriores referenciando o ADR original.

---

## ADR-001 ate ADR-014
*(Consulte o histórico para detalhes dos ADRs anteriores)*

---

## ADR-015: Uso Mandatório do Padrão Command para Ações de UI

**Data:** 2026-03-13
**Status:** Aceito

### Contexto
O gerenciamento manual de estados de "carregamento" (busy) e "erro" nos ViewModels gerava muito boilerplate e inconsistência visual entre telas.

### Decisão
Implementar e usar obrigatoriamente a classe `Command` (do package `core`) para qualquer operação assíncrona iniciada pela UI.

### Consequências
- ViewModels ficam mais limpos (menos flags booleanas).
- UI reage de forma consistente via `ListenableBuilder` aos estados do comando.
- Redução drástica de bugs de concorrência (Commands bloqueiam re-execução automática enquanto rodam).

---

## ADR-016: UseCases como Camada de Orquestração Mandatória

**Data:** 2026-03-13
**Status:** Aceito

### Contexto
ViewModels estavam começando a acumular lógica de orquestração de dados e dependência direta de múltiplos Repositories.

### Decisão
Toda ação de negócio deve ser encapsulada em um `UseCase` que estende `BaseUseCase`. O ViewModel deve depender de `UseCases` e nunca de `Repositories`.

### Consequências
- Separação clara entre Lógica de UI (ViewModel) e Lógica de Negócio (UseCase).
- UseCases tornam-se testáveis em isolamento total de widgets.
- Facilidade de reutilização de orquestração entre diferentes ViewModels.

---

## ADR-017: Organização de UI via Atomic Design

**Data:** 2026-03-13
**Status:** Aceito

### Contexto
Pastas de widgets estavam se tornando "sacos de arquivos" sem hierarquia clara de reuso.

### Decisão
Adotar rigorosamente o **Atomic Design**:
- `atoms/`: Componentes básicos, puros e agnósticos.
- `molecules/`: Composição de átomos com lógica visual local.
- `organisms/`: Seções complexas e independentes de página.
- `pages/`: Telas finais que conectam organismos ao ViewModel.

---

## ADR-018: Separação Root / Main e Injeção por Camadas

**Data:** 2026-03-13
**Status:** Aceito

### Contexto
O arquivo `main.dart` estava poluído com inicialização de infraestrutura, dificultando testes de integração e modularização.

### Decisão
1. `main.dart` apenas chama o `Root()`.
2. `root.dart` orquestra a injeção via `Provider` seguindo a ordem: `Data -> Logic -> UI`.
3. Repositories e UseCases são expostos na árvore de widgets para consumo via `context.read()`.

### Consequências
- Bootstrap do app limpo e profissional.
- Facilidade para trocar toda a camada de dados por `Fakes` nos testes.
