# Caso de Estudo de Arquitetura

**Um passo a passo de um app Flutter que implementa o padrão arquitetural MVVM.**

Os exemplos de código deste guia são do aplicativo de exemplo Compass, um app que ajuda os usuários a criar e reservar itinerários de viagens. É um aplicativo de exemplo robusto, com muitas funcionalidades, rotas e telas. O app se comunica com um servidor HTTP, possui ambientes de desenvolvimento e produção, inclui estilização específica da marca e conta com alta cobertura de testes. Dessas formas e mais, ele simula um aplicativo Flutter real e rico em funcionalidades.

---

A arquitetura do app Compass se assemelha mais ao padrão arquitetural MVVM conforme descrito nas diretrizes de arquitetura de apps do Flutter. Este caso de estudo de arquitetura demonstra como implementar essas diretrizes, percorrendo a funcionalidade "Home" do app Compass. Se você não está familiarizado com MVVM, deve ler essas diretrizes primeiro.

A tela Home do app Compass exibe informações da conta do usuário e uma lista das viagens salvas do usuário. A partir dessa tela, você pode fazer logout, abrir páginas detalhadas de viagens, excluir viagens salvas e navegar até a primeira página do fluxo principal do app, que permite ao usuário criar um novo itinerário.

Neste caso de estudo, você aprenderá o seguinte:

- Como implementar as diretrizes de arquitetura de apps do Flutter usando repositórios e serviços na camada de dados e o padrão arquitetural MVVM na camada de UI
- Como usar o padrão Command para renderizar a UI de forma segura conforme os dados mudam
- Como usar objetos `ChangeNotifier` e `Listenable` para gerenciar estado
- Como implementar Injeção de Dependência usando `package:provider`
- Como configurar testes ao seguir a arquitetura recomendada
- Estrutura de pacotes eficaz para apps Flutter de grande porte

Este caso de estudo foi escrito para ser lido em ordem. Qualquer página pode fazer referência às páginas anteriores.

Os exemplos de código neste caso de estudo incluem todos os detalhes necessários para entender a arquitetura, mas não são trechos completos e executáveis. Se você preferir acompanhar com o app completo, pode encontrá-lo no GitHub.

---

## Estrutura de Pacotes

Código bem organizado é mais fácil de ser trabalhado por múltiplos engenheiros com conflitos mínimos de código e é mais fácil para novos engenheiros navegarem e entenderem. A organização do código tanto beneficia quanto se beneficia de uma arquitetura bem definida.

Existem dois meios populares de organizar código:

1. **Por funcionalidade** — As classes necessárias para cada funcionalidade são agrupadas juntas. Por exemplo, você pode ter um diretório `auth`, que conteria arquivos como `auth_viewmodel.dart`, `login_usecase.dart`, `logout_usecase.dart`, `login_screen.dart`, `logout_button.dart`, etc.

2. **Por tipo** — Cada "tipo" de arquitetura é agrupado junto. Por exemplo, você pode ter diretórios como `repositories`, `models`, `services` e `viewmodels`.

A arquitetura recomendada neste guia se presta a uma combinação das duas. Objetos da camada de dados (repositórios e serviços) não estão vinculados a uma única funcionalidade, enquanto objetos da camada de UI (views e view models) estão. A seguir está como o código é organizado dentro do aplicativo Compass.

```
▼ lib/
  ▼ ui/
    ▼ core/
      ▼ ui/
        <shared_widgets>
        themes/
    ▼ <feature_name>/
      ▼ view_models/
        <view_model_class>.dart
      ▼ widgets/
        <feature_name>_screen.dart
        <other_widgets>
  ▼ domain/
    ▼ models/
      <model_name>.dart
  ▼ data/
    ▼ repositories/
      <repository_class>.dart
    ▼ services/
      <service_class>.dart
    ▼ model/
      <api_model_class>.dart
  config/
  utils/
  routing/
  main_staging.dart
  main_development.dart
  main.dart

▼ test/          // Contém testes unitários e de widget.
  data/
  domain/
  ui/
  utils/

▼ testing/       // Contém mocks que outras classes precisam
                 // para executar testes.
  fakes/
  models/
```

A maior parte do código da aplicação vive nas pastas `data`, `domain` e `ui`. A pasta `data` organiza o código por tipo, porque repositórios e serviços podem ser usados em diferentes funcionalidades e por múltiplos view models. A pasta `ui` organiza o código por funcionalidade, porque cada funcionalidade tem exatamente uma view e exatamente um view model.

Outras características notáveis desta estrutura de pastas:

- A pasta UI também contém um subdiretório chamado "core". Core contém widgets e lógica de temas que são compartilhados por múltiplas views, como botões com a estilização da sua marca.
- A pasta `domain` contém os tipos de dados da aplicação, porque eles são usados pelas camadas de dados e UI.
- O app contém três arquivos "main", que atuam como diferentes pontos de entrada para a aplicação em desenvolvimento, staging e produção.
- Existem dois diretórios relacionados a testes no mesmo nível de `lib`: `test/` tem o código de teste, e sua própria estrutura espelha a de `lib/`. `testing/` é um subpacote que contém mocks e outros utilitários de teste que podem ser usados no código de teste de outros pacotes. A pasta `testing/` pode ser descrita como uma versão do seu app que você não distribui. É o conteúdo que é testado.
- Há código adicional no app Compass que não está relacionado à arquitetura. Para a estrutura completa de pacotes, veja no GitHub.

---

## Outras Opções de Arquitetura

O exemplo neste caso de estudo demonstra como uma aplicação segue nossas regras arquiteturais recomendadas, mas há muitos outros apps de exemplo que poderiam ter sido escritos. A UI deste app se apoia fortemente em view models e `ChangeNotifier`, mas poderia facilmente ter sido escrita com streams, ou com outras bibliotecas como `riverpod`, `flutter_bloc` e `signals`. A comunicação entre camadas deste app tratou tudo com chamadas de método, incluindo polling por novos dados. Poderia, em vez disso, ter usado streams para expor dados de um repositório para um view model e ainda assim seguir as regras cobertas neste guia.

Mesmo se você seguir este guia exatamente, e optar por não introduzir bibliotecas adicionais, você tem decisões a tomar: Você terá uma camada de domínio? Se sim, como gerenciará o acesso aos dados? A resposta depende tanto das necessidades individuais de cada equipe que não há uma única resposta correta. Independentemente de como você responda a essas perguntas, os princípios neste guia ajudarão você a escrever apps Flutter escaláveis.

E se você olhar com atenção, todas as arquiteturas não são MVVM de qualquer forma?