# Principios — frontend (Conecta Raros)

Diretrizes fundamentais de design, patterns e convencoes de codigo.
Estes principios sao **inegociaveis** — qualquer desvio deve ser registrado como ADR.

---

## 1. Principios de Arquitetura

### 1.1 MVVM Estrito
- **ViewModel** = maxima responsabilidade sobre o estado da tela
- **View** = exibe dados e captura eventos. Nao toma decisoes.
- **UseCase** = logica de aplicacao entre ViewModel e Data layer
- ViewModel NUNCA importa widgets. View NUNCA importa repositories.

### 1.2 Estado Atomico
- Cada pedaco de estado e um `ValueNotifier<T>` individual
- `ChangeNotifier` na ViewModel agrega os ValueNotifiers
- Rebuilds cirurgicos — so o widget que escuta aquele ValueNotifier reconstroi
- ZERO estado global. Estado e sempre local a feature.

### 1.3 Imutabilidade Total
- Todos os models: `final` em todos os campos
- Mudancas via `copyWith()` — nunca mutacao direta
- Dart trabalha bem com OOP imutavel — abusar disso
- Listas: `List.unmodifiable()` ou `const []`

### 1.4 Models como Schemas
- Models no Flutter sao **schemas puros** — sem logica de negocio
- Toda validacao, transformacao e regra de dominio vive no **BFF**
- Models tem: campos, `fromJson()`, `toJson()`, `copyWith()`, `==`, `hashCode`
- NADA MAIS.

### 1.5 Separation of Concerns
- Cada classe tem UMA responsabilidade
- Dependencias fluem SEMPRE para dentro (View -> ViewModel -> UseCase -> Repository -> Service)
- Nenhuma camada conhece a camada acima dela

---

## 2. Design Patterns (GoF)

Patterns obrigatorios no codebase:

| Pattern | Uso |
|---------|-----|
| **Repository** | Abstrai acesso a dados. Interface -> implementacao concreta. |
| **Factory** | Criacao de objetos complexos (models, ViewModels, UseCases). |
| **Strategy** | Algoritmos intercambiaveis (ex: resolucao de plataforma, sync strategies). |
| **Observer** | ValueNotifier/ChangeNotifier = Observer pattern nativo. |
| **Command** | Acoes do usuario encapsuladas como objetos (offline queue). |
| **Adapter** | Converte models da API para models do dominio do front. |
| **Singleton** | Apenas para services stateless (DI via Provider resolve isso). |
| **Builder** | Construcao de objetos complexos passo a passo (forms multi-step). |

### Anti-patterns proibidos
- **God Object** — nenhuma classe com mais de ~200 linhas
- **Spaghetti State** — sem setState() fora de atoms triviais
- **Magic Strings** — constantes sempre tipadas
- **Service Locator** — usar Provider, nunca GetIt.instance diretamente

---

## 3. Convencoes de Codigo

### 3.1 Nomenclatura

| Elemento | Convencao | Exemplo |
|----------|-----------|---------|
| Classes | PascalCase | `PatientRegistrationViewModel` |
| Variaveis/Metodos | camelCase | `patientName`, `loadPatient()` |
| Constantes | camelCase com `k` prefix ou SCREAMING_SNAKE | `kDefaultTimeout`, `MAX_RETRY` |
| Arquivos | snake_case | `patient_registration_vm.dart` |
| Packages | snake_case | `social_care`, `design_system` |
| Sufixos obrigatorios | Tipo da classe | `*ViewModel`, `*UseCase`, `*Repository`, `*Service`, `*Page` |

### 3.2 Organizacao de Imports

Ordem obrigatoria:
```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. Packages externos (pub.dev)
import 'package:provider/provider.dart';

// 4. Packages internos (monorepo)
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';

// 5. Imports relativos (mesmo package)
import '../view_model/patient_registration_vm.dart';
```

### 3.3 Documentacao

- Classes publicas: documentacao obrigatoria (`///`)
- Metodos privados: documentar se a logica nao for auto-evidente
- Parametros nomeados sempre que houver mais de 2 parametros
- UI PT-BR, Code EN — sem excecao

### 3.4 Testes

- Cada ViewModel tem suite de testes correspondente
- Cada UseCase tem suite de testes correspondente
- Naming: `<nome_original>_test.dart`
- Estrutura: `group()` + `test()` com descricao clara em ingles

---

## 4. Atomic Design

### 4.1 Hierarquia

```
Page (orquestrador visual)
  +-- Template (layout/scaffold)
       +-- Cell (composicao de atoms com logica visual minima)
            +-- Atom (widget indivisivel: Button, Input, Icon, Text)
```

### 4.2 Regras

- **Atom**: sem dependencia de negocio. Recebe dados via parametros. Reutilizavel em qualquer contexto.
- **Cell**: compoe atoms. Pode ter logica visual minima (mostrar/esconder). Sem acesso a ViewModel.
- **Template**: define layout (grid, spacing). Sem dados concretos — recebe children.
- **Page**: conecta ViewModel aos Templates/Cells. Unico ponto de acesso ao estado.

### 4.3 Onde cada um vive

- Atoms, Cells, Templates **genericos** -> `packages/design_system/`
- Atoms, Cells **especificos da feature** -> `features/<feature>/view/components/`
- Pages -> `features/<feature>/view/pages/`

---

## 5. Provider e Dependency Injection

### 5.1 Escopo

| Escopo | Onde | Exemplo |
|--------|------|---------|
| **Global** | `Shell` (root) | `AuthService`, `ConnectivityService`, `DioClient` |
| **Module** | `*_module.dart` do package | `SocialCareRepository`, BFF interface |
| **Feature** | Rota da feature | `PatientRegistrationViewModel` |

### 5.2 Regras

- Provider SOMENTE para injecao. Nunca para state management diretamente.
- `ChangeNotifierProvider` para ViewModels
- `Provider` para services/repositories stateless
- `ProxyProvider` para dependencias que dependem de outras
- Dispose automatico via `ChangeNotifierProvider` (ViewModel morre com a rota)
