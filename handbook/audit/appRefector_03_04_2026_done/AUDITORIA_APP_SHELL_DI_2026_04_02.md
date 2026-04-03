# Auditoria Arquitetural Detalhada — Injeção de Dependências e Arquitetura do App Shell (`apps/acdg_system/**`)
**Data:** 02 de Abril de 2026
**Especialista:** flutter-arch-review (Gemini CLI)
**Decisão de Arquitetura:** Opção B (Riverpod + riverpod_generator) mantendo MVVM

Esta auditoria concentrou-se na raiz do projeto (`apps/acdg_system`), focando no contêiner de Injeção de Dependências (DI), na legibilidade do código e no inchaço (bloating) da camada superior gerado pelo uso do `provider`.

---

## 1. O Diagnóstico: O "Inchaço" (Bloating)

O seu app não está inchado porque a sua gerência de estado é ruim, mas porque você tentou **centralizar toda a injeção lógica** no App Shell (o módulo pai) usando o pacote `provider`.

**🚫 Anti-padrões identificados:**

### 1.1 Injeção "God Object" (`AppProviders` e `DependencyManager`)
Você colocou literalmente TODOS os UseCases e Repositórios da funcionalidade inteira de Saúde Social (`social_care`) dentro do `main` do aplicativo (ex: `RegisterPatientUseCase`, `ListPatientsUseCase`). Em um Monorepo, o App Shell deve ser "burro" e apenas injetar o núcleo (Auth, Banco, Rede), enquanto cada funcionalidade gerencia seus próprios fluxos internos.

### 1.2 "Callback Hell" no `GoRouter` e ProxyProviders
O arquivo `app_router.dart` se tornou um pesadelo visual. Você está extraindo manualmente 5 dependências diferentes do contexto (`context.read`) e criando `ChangeNotifierProvider` em-linha em cada rota. Além disso, o uso extensivo de `ProxyProvider` para passar dependências encadeadas gera um código de fábrica manual muito difícil de escalar.

---

## 2. A Escolha: Riverpod como Contêiner de Injeção (DI)

Como decidido, adotaremos o **Riverpod** (`flutter_riverpod` + `riverpod_generator`). 

O Riverpod foi criado pelo mesmo criador do `provider` exatamente para corrigir esses problemas:
- Ele não depende do `BuildContext` para injetar dependências (fim do God Object no `main`).
- Permite injeção declarativa em tempo de compilação (fim dos `ProxyProviders`).
- Funciona em perfeita harmonia com sua gerência de estado atual.

### 🔴 O que MUDA:
Toda a parte de "Injeção" sai da Árvore de Widgets (`AppProviders` deixa de existir) e passa para variáveis globais ou geradas (`@riverpod`).

### 🟢 O que NÃO MUDA (A grande vantagem):
**Você NÃO precisa mudar o seu padrão de estado!** Suas classes `BaseViewModel` (que são `ChangeNotifier`) e seus `Command` continuam exatamente iguais. O Riverpod possui um provider específico chamado `ChangeNotifierProvider` (ou seu equivalente no generator) criado exatamente para reaproveitar sua base legada sem precisar reescrever tudo para `Notifier`.

---

## 3. O Plano de Refatoração: Como usar sua Gerência de Estado com Riverpod

Abaixo está o exemplo prático de como o código inchado será destruído e substituído por uma arquitetura limpa.

### Passo 1: Injeção de Repositórios e UseCases (Sem UI)
No seu pacote `social_care`, crie um arquivo `di.dart`. O gerador do Riverpod vai cuidar de amarrar as coisas:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'di.g.dart';

// 1. Injetamos o Repositório
@riverpod
PatientRepository patientRepository(PatientRepositoryRef ref) {
  // O "ref.watch" substitui o "ProxyProvider"
  final bffContract = ref.watch(socialCareContractProvider);
  final patientService = ref.watch(patientServiceProvider);
  return BffPatientRepository(bff: bffContract, patientService: patientService);
}

// 2. Injetamos os UseCases
@riverpod
GetPatientUseCase getPatientUseCase(GetPatientUseCaseRef ref) {
  return GetPatientUseCase(patientRepository: ref.watch(patientRepositoryProvider));
}
```

### Passo 2: O ViewModel com ChangeNotifier no Riverpod
Você vai criar um Provider do Riverpod para instanciar o seu ViewModel. Como você usa `ChangeNotifier`, você tem duas opções. Se estiver usando o gerador (`@riverpod`), a recomendação oficial é expor a classe via `Raw<T>` ou, de forma mais simples e sem o generator, usar o clássico `ChangeNotifierProvider` do Riverpod:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Este é o provider que o Riverpod disponibiliza EXATAMENTE para o seu padrão atual.
// Ele gerencia o dispose() do BaseViewModel automaticamente quando a tela fecha!
final familyCompositionViewModelProvider = ChangeNotifierProvider.family<FamilyCompositionViewModel, String>((ref, patientId) {
  return FamilyCompositionViewModel(
    patientId: patientId,
    getPatientUseCase: ref.watch(getPatientUseCaseProvider), // Auto-injetado!
    addFamilyMemberUseCase: ref.watch(addFamilyMemberUseCaseProvider),
    // ...
  );
});
```

### Passo 3: Limpando o AppRouter (A verdadeira mágica)
Agora observe como o seu `app_router.dart` encolhe absurdamente. Você não usa mais `context.read` ou `ChangeNotifierProvider` gigante na rota:

```dart
// Antes (O que causava inchaço):
GoRoute(
  path: '${AppRoutes.familyComposition}/:patientId',
  builder: (context, state) {
     final patientId = state.pathParameters['patientId']!;
     return ChangeNotifierProvider(
        create: (_) => FamilyCompositionViewModel(
           patientId: patientId,
           getPatientUseCase: context.read<GetPatientUseCase>(),
           // ... mais 5 leituras verbosas
        ),
        child: const FamilyCompositionPage(),
     );
  }
)

// DEPOIS (Padrão Riverpod):
GoRoute(
  path: '${AppRoutes.familyComposition}/:patientId',
  builder: (context, state) {
    final patientId = state.pathParameters['patientId']!;
    return FamilyCompositionPage(patientId: patientId);
  }
)
```

### Passo 4: A View consumindo o ViewModel
Na sua `FamilyCompositionPage`, você apenas converte o `StatefulWidget` (ou `StatelessWidget`) para um `ConsumerWidget`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Troque StatelessWidget por ConsumerWidget
class FamilyCompositionPage extends ConsumerWidget {
  final String patientId;
  const FamilyCompositionPage({super.key, required this.patientId});

  @override
  // 2. Receba o "WidgetRef ref" no build
  Widget build(BuildContext context, WidgetRef ref) {
    
    // 3. Peça o ViewModel para o Riverpod. 
    // Como você usou ChangeNotifierProvider, toda vez que o ViewModel der "notifyListeners()", 
    // essa tela será reconstruída (igual ao provider clássico, mas mais seguro).
    final viewModel = ref.watch(familyCompositionViewModelProvider(patientId));

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
           // Use seu ViewModel e seus Commands normalmente!
           ElevatedButton(
              onPressed: viewModel.assignCaregiverCommand.execute,
              child: Text('Definir Cuidador'),
           ),
        ],
      )
    );
  }
}
```

---

## 4. O Ganho Imediato

Ao aplicar esse padrão com o Riverpod:
1. **Morte do MultiProvider:** O `AppProviders` inteiro (dezenas de blocos) desaparece. Você apenas embrulha o `runApp` com um único `ProviderScope()`.
2. **Escopo Perfeito:** Repositórios e UseCases não precisam mais vazar para a camada global de apresentação. Eles podem ficar isolados no pacote `social_care` e o Flutter constrói as árvores de dependência (o Grafo) em tempo de compilação (`build_runner`).
3. **Morte do Boilerplate de UI:** Acaba a necessidade de usar `ListenableBuilder` aninhados ou `ChangeNotifierProvider` em todo lugar. O `ref.watch` faz a ponte automática da injeção E da reatividade. O seu MVVM brilha de forma muito mais pura.