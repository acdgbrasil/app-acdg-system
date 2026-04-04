# Selectors & Connectors Pattern (2026 Flutter Standard)

> **Propósito:** Este guia detalha o padrão de "Reatividade Cirúrgica" adotado no ecossistema ACDG para resolver problemas de performance em telas complexas, eliminando rebuilds globais e o acoplamento excessivo com ViewModels.

---

## 1. O Problema: O Anti-Pattern "Fat ViewModel Injection"

Em arquiteturas MVVM tradicionais, é comum passar o `ViewModel` inteiro para todos os widgets filhos. 

**Por que isso é ruim?**
1. **Rebuilds em Cascata:** Se o widget pai ouve o ViewModel inteiro, qualquer mudança em qualquer campo (mesmo um que o widget não use) dispara uma reconstrução de toda a subárvore.
2. **Acoplamento Forte:** Componentes pequenos (Atoms/Molecules) tornam-se dependentes de ViewModels gigantes, dificultando o reuso e os testes de widget.
3. **Impossibilidade de `const`:** Widgets que recebem objetos mutáveis (como ViewModels) raramente podem ser marcados como `const`, perdendo a otimização de cache do Flutter.

---

## 2. O Padrão: Selectors & Connectors

Em 2026, a tendência consolidada é a **decomposição da escuta**. Em vez do widget "conhecer" o provedor de dados, ele recebe apenas o dado exato (**Selector**) ou a ação exata (**Connector/Command**).

### A. O Papel dos Selectors (Data)
O widget pai extrai a informação necessária e a passa como um tipo primitivo ou um objeto de domínio imutável.

### B. O Papel dos Connectors (Actions)
O widget pai passa apenas o `Command` ou o callback necessário para a interação.

---

## 3. Exemplo Prático (Antes vs. Depois)

### ❌ Anti-Padrão (Passando o VM inteiro)
```dart
// Molecule
class SaveButton extends StatelessWidget {
  final MyViewModel viewModel; // ❌ Erro: Acoplamento excessivo
  const SaveButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    // Ouve o VM inteiro. Se o nome do usuário mudar, o botão de salvar reconstrói!
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => FilledButton(
        onPressed: viewModel.canSave ? viewModel.save.execute : null,
        child: Text('Salvar'),
      ),
    );
  }
}
```

### ✅ Padrão Ouro (Surgical Connector)
```dart
// Molecule pura e otimizada
class SaveButton extends StatelessWidget {
  final bool canSave;           // ✅ Selector: Apenas o booleano necessário
  final VoidCallback? onSave;   // ✅ Connector: Apenas a ação

  const SaveButton({
    super.key,
    required this.canSave,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: canSave ? onSave : null,
      child: const Text('Salvar'), // ✅ Uso de const liberado
    );
  }
}

// Na Page ou Organism (Onde a reatividade é isolada)
ListenableBuilder(
  listenable: viewModel,
  builder: (context, _) => SaveButton(
    canSave: viewModel.canSave,
    onSave: viewModel.save.execute,
  ),
)
```

---

## 4. Reatividade Interna (Ouvinte Cirúrgico)

Quando um widget é inerentemente reativo (como uma lista de checkboxes), o `ListenableBuilder` deve ser movido para o **nível mais baixo possível**.

**Regra:** Se apenas o ícone de um item da lista muda, apenas esse item deve ter um builder. A lista em si deve ser estática.

```dart
class SpecificityTile extends StatelessWidget {
  final FamilyCompositionViewModel viewModel;
  final String id;

  const SpecificityTile({super.key, required this.viewModel, required this.id});

  @override
  Widget build(BuildContext context) {
    // O ouvinte está aqui, no átomo, protegendo o resto da tela
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final isSelected = viewModel.selectedSpecificityId == id;
        return Checkbox(
          value: isSelected,
          onChanged: (_) => viewModel.updateSpecificity(id),
        );
      },
    );
  }
}
```

---

## 5. Resumo de Diretrizes para o Executor

1. **Proibição de `_buildHeader()`:** Funções privadas não criam um novo contexto de elemento. Use classes `StatelessWidget`.
2. **Encapsulamento de Escuta:** O `ListenableBuilder` (ou `ref.watch` no Riverpod) deve envolver apenas os widgets que realmente mudam visualmente.
3. **Interfaces Limpas:** Atoms e Molecules devem preferir receber `ValueListenable`, `Command` ou tipos primitivos em vez de ViewModels inteiros.
4. **Memoização:** Cálculos pesados (como filtragem de listas ou contagem de perfis) devem ser cacheados no ViewModel e não recalculados no `getter` durante o build.

---
**Referência:** [handbook/principles/ARCHITECTURAL_GOLD_STANDARD.md]
**Data:** Abril 2026
