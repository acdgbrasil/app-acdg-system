# Tooling — frontend (Conecta Raros)

Stack tecnologico, bibliotecas core e automacoes.

---




## 1. Stack Tecnologico

| Camada | Tecnologia | Versao | Motivo |
|--------|-----------|--------|--------|
| **Framework** | Flutter | 3.x (stable) | Web WASM + Desktop nativo, engine propria |
| **Linguagem** | Dart | 3.x | OOP forte, AOT, compartilha types com BFF |
| **State Management** | ChangeNotifier + ValueNotifier | Built-in | Atomico, zero dependencia, testavel |
| **DI** | Provider | ^6.0 | Integrado com widget tree, escopo por rota |
| **Routing** | GoRouter | ^14.0 | Declarativo, deferred loading, deep links |
| **HTTP Client** | Dio | ^5.0 | Interceptors, retry, cancel tokens |
| **HTTP Server (BFF)** | Darto | latest | Open source, contribuidor proximo |
| **Offline DB** | Isar | ^4.0 | NoSQL embarcado, web (IndexedDB) + desktop (file) |
| **Auth** | Zitadel OIDC | — | PKCE flow, self-hosted |
| **Design System** | Figma ACDG | — | Atomic Design: atoms, cells, templates, tokens |

---

## 2. Dependencias Chave (pubspec)

### Shell
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  go_router: ^14.0.0
  dio: ^5.0.0
  isar: ^4.0.0
  isar_flutter_libs: ^4.0.0

  # Packages internos
  core:
    path: ../packages/core
  design_system:
    path: ../packages/design_system
  social_care:
    path: ../packages/social_care
```

### Core
```yaml
dependencies:
  dio: ^5.0.0
  isar: ^4.0.0
  connectivity_plus: ^6.0.0
  flutter_secure_storage: ^9.0.0
```

### BFF (social_care_bff)
```yaml
dependencies:
  darto: latest
  dio: ^5.0.0
  isar: ^4.0.0

dev_dependencies:
  test: any
```

---

## 3. Dev Tools

| Ferramenta | Uso |
|------------|-----|
| `flutter analyze` | Analise estatica (lint) |
| `dart format` | Formatacao automatica |
| `flutter test` | Testes unitarios e de widget |
| `flutter build web --wasm` | Build web com WebAssembly |
| `flutter build macos` | Build desktop macOS |
| `flutter build windows` | Build desktop Windows |
| `flutter build linux` | Build desktop Linux |
| `dart compile exe` | Build BFF server (AOT) |
| Melos | Monorepo management (scripts, versioning, CI) |

---

## 4. Lint Rules

Usar `analysis_options.yaml` padrao com regras adicionais:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - avoid_print
    - avoid_relative_lib_imports
    - prefer_single_quotes
    - sort_constructors_first
    - unnecessary_this
    - prefer_is_empty
    - prefer_is_not_empty
```

---

## 5. Automacoes

| Automacao | Ferramenta | Descricao |
|-----------|-----------|-----------|
| Monorepo scripts | Melos | `melos bootstrap`, `melos run test`, `melos run analyze` |
| Code generation | build_runner | Isar schemas, JSON serialization |
| CI lint | GitHub Actions | `flutter analyze` em todo PR |
| CI test | GitHub Actions | `flutter test` em todo PR |
| CI build | GitHub Actions | Build web WASM + desktop artifacts |

## 6. Design System (Made by: Davi Costa e Breno Colaço)

### Tokens:
  # Colors (Frames)
 - Implement these 5 designs from Figma.
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-10807&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-10808&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-10809&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-10810&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-10811&m=dev

### Components:

 - Radiobox with Label variations Group:
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4175&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4213&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4206&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4201&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4197&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4193&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4181&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4211&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4185&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4177&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4189&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4215&m=dev
 - Radiobox without variations Group:
- @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4154&m=dev
- @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4172&m=dev
- @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4168&m=dev
- @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4170&m=dev
- @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4156&m=dev
- @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4159&m=dev
- @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4165&m=dev
- @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4162&m=dev

 - Checkbox without Label variations Group: 
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4175&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4213&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4206&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4201&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4197&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4193&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4181&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4211&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4185&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4177&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4189&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4215&m=dev
 
 - Checkbox with label variations Group:
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4129&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4135&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4141&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4147&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4150&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4144&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4138&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4132&m=dev
 
 - Dropdown variations group:
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4218&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4228&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4229&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4222&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4220&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4219&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4230&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4221&m=dev
 
 - TextField Component variable:
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=2052-5863&m=dev

  ### Templates:
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-9528&m=dev (PopUp Template)


  # PAGES (SOCIAL CARE):
    #### HOME:
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-3854&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4077&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-3879&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-3956&m=dev
  - @https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing?node-id=4-4033&m=dev
    #### CADASTRO DE PESSOA DE REFERENCIA:

  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-9630&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-9116&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-9307&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-9586&m=dev

    #### OBSERVAÇÕES
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-10875&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-10892&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-10910&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-10949&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-10989&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-11035&m=dev


  #### Forma do primeiro atendimento e engresso:
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-2809&m=dev

  #### Composição familiar:
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-9829&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-10083&m=dev

  #### Condições Habitacionais da familia:
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-10425&m=dev

  ##### Condições Educacionais da familia:
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-8026&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-8206&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-8407&m=dev

  ##### Condições de Trabalho e Rendimento da Familia:
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-2350&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-2644&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-2492&m=dev

  ##### Condições de Saúde da Familía:
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-8602&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-8975&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-8717&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-8847&m=dev

  #### Acesso a Beneficios Eventuais:
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-2889&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-2943&m=dev

  #### Convivencia Familiar e Comunitaria:
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-3749&m=dev
  
  #### Participação Em Serviços, Programas Ou Projetos Que Contribuam Para O Desenvolviemnto Da Convivência Comunitária E Para O Fortalecimento De Vínculos:
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-3612&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-3672&m=dev

  #### Situações de Violência e Violação de Direitos:
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-3013&m=dev

  #### Histórico de Cumprimento de Medidas Socioeducativas
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-3119&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-3218&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-3338&m=dev
  
  #### Histórico de Acolhimento Institucional ou Familiar
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-3444&m=dev
  - @https://www.figma.com/design/fee96pkYuFIqhPdGDfJLZD/Conecta-Raros---MODELO?node-id=4-3517&m=dev
