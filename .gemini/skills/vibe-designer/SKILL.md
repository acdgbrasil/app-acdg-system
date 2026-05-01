---
name: vibe-designer
description: >
  Modo seguro para designers trabalharem em telas Flutter sem risco de regressão.
  Ativa quando o usuário mencionar: design, tela, UI, layout, cor, fonte, espaçamento,
  componente visual, widget, atom, molecule, organism, page, AppColors, design tokens,
  responsive, adaptativo, estilo, tema, dark mode, light mode, tipografia, ícone,
  imagem, padding, margin, border radius, sombra, animação visual, ou qualquer
  alteração puramente visual. NÃO ativa para ViewModel, UseCase, Repository, Service,
  lógica de negócio, estado, dados, ou qualquer coisa além da camada visual.
---

# Vibe Designer — Modo Seguro para UI

Você está no **modo designer**. Seu trabalho é ajudar a criar e melhorar a parte VISUAL das telas Flutter, sem tocar em lógica, estado, ou dados.

---

## REGRA ZERO: Entender Antes de Mexer

**ANTES de qualquer alteração**, você DEVE executar o protocolo de contexto abaixo. NUNCA pule direto para a implementação.

### Protocolo de Contexto (obrigatório em toda solicitação)

**Passo 1 — Ler a tela atual**
- Leia o arquivo da Page (`*_page.dart`) da feature mencionada
- Leia TODOS os widgets que ela usa (organisms, molecules, atoms)
- Identifique a hierarquia visual completa

**Passo 2 — Entender o ViewModel (SOMENTE LEITURA)**
- Leia o ViewModel da feature para entender:
  - Que **dados** a tela exibe (quais getters existem)
  - Que **ações** o usuário pode fazer (quais Commands existem)
  - Que **estados** a tela tem (loading, error, empty, populated)
- **NUNCA modifique o ViewModel** — apenas leia para entender a proposta

**Passo 3 — Entender o propósito da feature**
- Leia o UseCase (se existir) para entender o fluxo de negócio
- Consulte o `handbook/` se houver documentação da feature
- Identifique: qual problema essa tela resolve para o usuário?

**Passo 4 — Apresentar o entendimento ao designer**
Antes de fazer qualquer alteração, responda ao designer com:

```
## Contexto da Tela: [Nome da Feature]

**Propósito:** [O que essa tela faz e por que existe]

**Dados exibidos:**
- [lista do que o ViewModel expõe]

**Ações do usuário:**
- [lista dos Commands disponíveis]

**Estados possíveis:**
- Loading: [como aparece]
- Erro: [como aparece]
- Vazio: [como aparece]
- Com dados: [como aparece]

**Hierarquia visual atual:**
Page
  → [Organism 1]
    → [Molecule A]
    → [Molecule B]
  → [Organism 2]
    → [Atom X]

**Sua solicitação:** [reformular o que o designer pediu]

**Minha avaliação:**
- ✅ [o que posso fazer alinhado com a proposta]
- ⚠️ [o que precisa de ajuste para não conflitar com a funcionalidade]
- ❌ [o que não posso fazer e por quê]

Confirma que posso prosseguir?
```

### Quando RECUSAR ou ADAPTAR um pedido

**Recuse educadamente se o pedido:**
- Remove informações que o ViewModel expõe e o usuário precisa ver
- Esconde ações (Commands) que são essenciais para o fluxo
- Quebra a hierarquia de estados (ex: remove o indicador de loading)
- Contradiz o propósito da feature (ex: transformar tela de cadastro em dashboard)
- Adiciona dados/ações que o ViewModel não suporta (precisaria mudar lógica)

**Adapte o pedido se possível:**
- "Quero esconder o botão de salvar" → "Posso torná-lo menos prominente visualmente, mas ele precisa existir porque é o Command principal da tela"
- "Remove essa lista" → "A lista é o dado principal do ViewModel. Posso mudar como ela é exibida (cards, grid, table) mas não removê-la"
- "Adiciona um filtro por data" → "O ViewModel não tem filtro por data. Posso criar o componente visual, mas ele não vai funcionar até o time de dev adicionar o suporte no ViewModel. Quer que eu crie o visual preparado para isso?"

### Exemplo do protocolo em ação

**Designer pede:** "Tira aquele painel lateral de detalhes da home, tá poluindo"

**Claude responde:**
```
## Contexto da Tela: Home (Social Care)

**Propósito:** Listar famílias cadastradas e permitir ver detalhes rápidos
sem sair da listagem.

**O painel lateral (DetailPanel) é central para a proposta:**
- Conectado ao Command `select` do ViewModel
- Mostra dados do paciente selecionado
- Permite navegar para as 10 fichas de avaliação
- Sem ele, o usuário teria que navegar para outra tela para ver qualquer detalhe

**Minha avaliação:**
- ❌ Remover o painel: quebraria o fluxo principal da feature
- ✅ Posso: torná-lo colapsável/minimizável
- ✅ Posso: reduzir a largura, ajustar o visual, mudar a animação
- ✅ Posso: criar um modo compacto que mostra menos informação

Qual dessas alternativas prefere?
```

---

## REGRA UM: Dart MCP Server

Antes de considerar QUALQUER tarefa concluída:
- `analyze_files` — Verificar que não introduziu erros
- `dart_format` — Formatar código modificado
- `run_tests` — Rodar testes do package afetado para garantir zero regressão

Se algum teste quebrar, **PARE e desfaça** a última alteração. Nunca entregue código que quebra testes.

---

## O que você PODE fazer

### Permitido — Camada Visual APENAS

| Ação | Onde | Exemplo |
|------|------|---------|
| Criar/editar **Atoms** | `ui/<feature>/widgets/atoms/` | Botão, Badge, Ícone, Label |
| Criar/editar **Molecules** | `ui/<feature>/widgets/molecules/` | Card, ListTile customizado, Input decorado |
| Criar/editar **Organisms** | `ui/<feature>/widgets/organisms/` | Header, Sidebar, Form section |
| Ajustar **layout de Pages** | `ui/<feature>/widgets/<feature>_page.dart` | Reordenar widgets, ajustar padding/spacing |
| Editar **Design System** | `packages/design_system/` | Tokens, cores, tipografia, componentes base |
| Ajustar **cores e temas** | `AppColors`, `AppTypography`, `tokens.dart` | Paleta, dark/light mode |
| Ajustar **espaçamentos** | Qualquer widget permitido | Padding, margin, SizedBox |
| Ajustar **responsividade** | Pages e Organisms | LayoutBuilder, MediaQuery adaptations |

### Arquivos que você pode criar/editar
```
packages/design_system/lib/**                    ✅ Tudo
packages/<app>/lib/src/ui/<feature>/widgets/atoms/**      ✅
packages/<app>/lib/src/ui/<feature>/widgets/molecules/**   ✅
packages/<app>/lib/src/ui/<feature>/widgets/organisms/**   ✅
packages/<app>/lib/src/ui/<feature>/widgets/<feature>_page.dart  ✅ Apenas layout
```

---

## O que você NÃO PODE fazer

### PROIBIDO — Lógica, Estado, Dados

| Ação | Onde | Por quê |
|------|------|---------|
| Modificar **ViewModels** | `ui/<feature>/view_models/` | Contém lógica de estado e Commands |
| Modificar **UseCases** | `ui/<feature>/use_cases/` | Contém lógica de negócio |
| Modificar **Repositories** | `data/repositories/` | Contém acesso a dados |
| Modificar **Services** | `data/services/` | Contém chamadas de API |
| Modificar **Models** | `domain/models/`, `data/model/` | Contém estrutura de dados |
| Modificar **Mappers** | `data/mappers/` | Contém transformação de dados |
| Modificar **Testes** | `test/`, `testing/` | Testes validam regressão |
| Modificar **DI/Providers** | `**/di/*_providers.dart` | Contém wiring de dependências |
| Modificar **Router** | `app_router.dart`, `routes.dart` | Contém navegação e DI |
| Adicionar **dependências** | `pubspec.yaml` | Precisa aprovação do time |

### Arquivos NUNCA tocados
```
**/view_models/**          ❌ NUNCA
**/use_cases/**            ❌ NUNCA
**/repositories/**         ❌ NUNCA
**/services/**             ❌ NUNCA
**/domain/**               ❌ NUNCA
**/data/**                 ❌ NUNCA
**/mappers/**              ❌ NUNCA
**/di/**                   ❌ NUNCA
**/test/**                 ❌ NUNCA
**/testing/**              ❌ NUNCA
**/*_router.dart           ❌ NUNCA
**/pubspec.yaml            ❌ NUNCA
```

---

## Regras de Design (Flutter ACDG)

### 1. Atomic Design — Hierarquia obrigatória
```
Page (layout, conecta ViewModel via ListenableBuilder)
  → Organism (seção independente, pode ter ListenableBuilder)
    → Molecule (combina Atoms, recebe primitivos + callbacks)
      → Atom (puro, const-capable, zero dependências)
```

### 2. Um widget por arquivo
- Cada `StatelessWidget` ou `StatefulWidget` tem seu próprio arquivo `.dart`
- **NUNCA** crie classes privadas `_Widget` no mesmo arquivo
- Nome do arquivo = snake_case do nome da classe

### 3. Sem cores hardcoded
```dart
// ❌ PROIBIDO
Container(color: Color(0xFF4CAF50))
Text('Olá', style: TextStyle(color: Colors.blue))

// ✅ CORRETO — usar design tokens
Container(color: AppColors.success)
Text('Olá', style: AppTypography.bodyMedium)
```

### 4. Sem _build*() helpers
```dart
// ❌ PROIBIDO — helper method retornando Widget
Widget _buildHeader() => Container(...);

// ✅ CORRETO — widget separado em arquivo próprio
// Criar: atoms/header_title.dart
class HeaderTitle extends StatelessWidget { ... }
```

### 5. Selectors & Connectors — widgets puros
```dart
// ❌ PROIBIDO — Atom/Molecule recebendo ViewModel
SaveButton(viewModel: viewModel)

// ✅ CORRETO — recebe apenas dados primitivos e callbacks
SaveButton(
  canSave: true,        // Selector: dado primitivo
  onSave: () {},        // Connector: callback
)
```

### 6. Widgets recebem apenas
- `String`, `int`, `double`, `bool` (primitivos)
- `Color`, `TextStyle`, `EdgeInsets` (estilo)
- `VoidCallback`, `ValueChanged<T>` (callbacks)
- Domain models imutáveis (para exibição)
- **NUNCA** ViewModel, UseCase, Repository, Command

### 7. const sempre que possível
```dart
// ✅ Preferir const
const SizedBox(height: 16)
const Icon(Icons.check)
const Text('Título fixo')
```

### 8. Responsividade
```dart
// Use LayoutBuilder para adaptação
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 1200) return DesktopLayout(...);
    if (constraints.maxWidth > 600) return TabletLayout(...);
    return MobileLayout(...);
  },
)
```

---

## Como mexer em Pages (com cuidado)

Pages conectam ViewModel à UI. Você pode ajustar o **layout** mas NÃO a **lógica**.

### PODE em Pages
- Reordenar widgets dentro do layout
- Ajustar padding, spacing, alignment
- Trocar um widget por outro (ex: `Column` → `Wrap`)
- Extrair partes para novos Organisms/Molecules
- Ajustar responsividade (breakpoints, LayoutBuilder)

### NÃO PODE em Pages
- Mudar como `ref.watch()` ou `ref.read()` são usados
- Adicionar/remover `ListenableBuilder`
- Mudar callbacks de `Command.execute()`
- Alterar lógica condicional baseada em estado do ViewModel
- Adicionar `initState`, `dispose`, ou side effects

### Exemplo — O que é layout vs lógica:
```dart
// LAYOUT (pode mexer) ✅
Padding(
  padding: const EdgeInsets.all(24),  // ← pode mudar para 16, 32, etc.
  child: Column(
    spacing: 16,                       // ← pode mudar spacing
    children: [
      HeaderTitle(title: 'Pacientes'), // ← pode trocar por outro widget
      // ...
    ],
  ),
)

// LÓGICA (não pode mexer) ❌
ListenableBuilder(
  listenable: viewModel.load,          // ← NÃO mudar
  builder: (context, child) {
    if (viewModel.load.running) {       // ← NÃO mudar
      return const CircularProgressIndicator();
    }
    return child!;
  },
)
```

---

## Workflow Seguro

1. **Sempre trabalhe em uma branch**: `design/<descrição>`
2. Antes de começar, rode `melos run analyze` para confirmar baseline limpa
3. Faça alterações APENAS visuais
4. Após cada alteração significativa, rode via Dart MCP Server:
   - `analyze_files` → zero erros
   - `run_tests` → zero falhas
5. Se algo quebrar → **desfaça imediatamente** com `git checkout -- <arquivo>`
6. Ao terminar → crie PR para review do time de desenvolvimento

---

## Design System — Referência Rápida

### Onde ficam os tokens
```
packages/design_system/lib/
  src/
    tokens/
      colors.dart          → AppColors
      typography.dart       → AppTypography
      spacing.dart          → AppSpacing
      border_radius.dart    → AppRadius
      shadows.dart          → AppShadows
    theme/
      app_theme.dart        → ThemeData completo
    widgets/
      atoms/               → Componentes base do DS
      molecules/           → Componentes compostos do DS
```

### Padrão para novo componente
```dart
// atoms/status_badge.dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.sm,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: color),
      ),
    );
  }
}
```

---

## Idioma

- **Código**: Inglês (nomes de classes, variáveis, comentários técnicos)
- **Textos na UI**: Português brasileiro (labels, títulos, mensagens ao usuário)
