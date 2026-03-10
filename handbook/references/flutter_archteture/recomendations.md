# Recomendações e recursos de arquitetura

Recomendações para construir aplicações Flutter escaláveis.

---

Esta página apresenta as melhores práticas de arquitetura, por que elas importam e se as recomendamos para sua aplicação Flutter. Você deve tratar estas recomendações como sugestões, e não como regras rígidas, e deve adaptá-las aos requisitos únicos do seu app.

As melhores práticas nesta página possuem uma prioridade, que reflete o quão fortemente o time do Flutter as recomenda.

- **Fortemente recomendado:** Você deve sempre implementar esta recomendação se estiver começando a construir uma nova aplicação. Você deve considerar fortemente refatorar um app existente para implementar esta prática, a menos que isso entre em conflito fundamental com sua abordagem atual.
- **Recomendado:** Esta prática provavelmente vai melhorar seu app.
- **Condicional:** Esta prática pode melhorar seu app em certas circunstâncias.

---

## Separação de responsabilidades

Você deve separar seu app em uma **camada de UI** e uma **camada de dados**. Dentro dessas camadas, você deve separar ainda mais a lógica em classes por responsabilidade.

| Recomendação | Prioridade | Descrição |
|---|---|---|
| **Use camadas de dados e UI claramente definidas.** | Fortemente recomendado | A separação de responsabilidades é o princípio arquitetural mais importante. A camada de dados expõe os dados da aplicação para o restante do app e contém a maior parte da lógica de negócios. A camada de UI exibe os dados da aplicação e escuta eventos dos usuários. A camada de UI contém classes separadas para lógica de UI e widgets. |
| **Use o padrão repository na camada de dados.** | Fortemente recomendado | O padrão repository é um padrão de design de software que isola a lógica de acesso a dados do restante da aplicação. Ele cria uma camada de abstração entre a lógica de negócios da aplicação e os mecanismos de armazenamento subjacentes (bancos de dados, APIs, sistemas de arquivos, etc.). Na prática, isso significa criar classes Repository e classes Service. |
| **Use ViewModels e Views na camada de UI. (MVVM)** | Fortemente recomendado | A separação de responsabilidades é o princípio arquitetural mais importante. Essa separação em particular torna seu código muito menos propenso a erros, porque seus widgets permanecem "burros". |
| **Use ChangeNotifiers e Listenables para lidar com atualizações de widgets.** | Condicional | A API ChangeNotifier faz parte do SDK do Flutter e é uma forma conveniente de fazer seus widgets observarem mudanças nos seus ViewModels. Existem muitas opções para gerenciamento de estado, e a decisão depende de preferência pessoal. Leia sobre nossa recomendação de ChangeNotifier ou outras opções populares. |
| **Não coloque lógica nos widgets.** | Fortemente recomendado | A lógica deve ser encapsulada em métodos no ViewModel. A única lógica que uma view deve conter é: instruções `if` simples para mostrar/esconder widgets com base em uma flag ou campo nullable no ViewModel; lógica de animação que depende do widget para calcular; lógica de layout baseada em informações do dispositivo (tamanho de tela ou orientação); lógica de roteamento simples. |
| **Use uma camada de domínio.** | Condicional | Uma camada de domínio só é necessária se sua aplicação possui lógica excessivamente complexa que sobrecarrega seus ViewModels, ou se você se encontra repetindo lógica nos ViewModels. Em apps muito grandes, use-cases são úteis, mas na maioria dos apps eles adicionam overhead desnecessário. Use em apps com requisitos de lógica complexa. |

---

## Manipulação de dados

Manipular dados com cuidado torna seu código mais fácil de entender, menos propenso a erros e previne dados malformados ou inesperados.

| Recomendação | Prioridade | Descrição |
|---|---|---|
| **Use fluxo de dados unidirecional.** | Fortemente recomendado | Atualizações de dados devem fluir apenas da camada de dados para a camada de UI. Interações na camada de UI são enviadas para a camada de dados onde são processadas. |
| **Use Commands para lidar com eventos de interação do usuário.** | Recomendado | Commands previnem erros de renderização no seu app e padronizam como a camada de UI envia eventos para a camada de dados. Leia sobre commands no estudo de caso de arquitetura. |
| **Use modelos de dados imutáveis.** | Fortemente recomendado | Dados imutáveis são cruciais para garantir que quaisquer mudanças necessárias ocorram apenas no lugar adequado, geralmente na camada de dados ou domínio. Como objetos imutáveis não podem ser modificados após a criação, você deve criar uma nova instância para refletir mudanças. Esse processo previne atualizações acidentais na camada de UI e suporta um fluxo de dados unidirecional claro. |
| **Use freezed ou built_value para gerar modelos de dados imutáveis.** | Recomendado | Você pode usar pacotes para gerar funcionalidades úteis nos seus modelos de dados, como `freezed` ou `built_value`. Eles podem gerar métodos comuns como serialização/deserialização JSON, verificação de igualdade profunda e métodos de cópia. Esses pacotes de geração de código podem adicionar tempo de build significativo se você tiver muitos modelos. |
| **Crie modelos de API e modelos de domínio separados.** | Condicional | Usar modelos separados adiciona verbosidade, mas previne complexidade nos ViewModels e use-cases. Use em apps grandes. |

---

## Estrutura do app

Código bem organizado beneficia tanto a saúde do app em si quanto da equipe trabalhando nele.

| Recomendação | Prioridade | Descrição |
|---|---|---|
| **Use injeção de dependência.** | Fortemente recomendado | Injeção de dependência previne que seu app tenha objetos globalmente acessíveis, o que torna seu código menos propenso a erros. Recomendamos usar o pacote `provider` para lidar com injeção de dependência. |
| **Use go_router para navegação.** | Recomendado | `go_router` é a forma preferida de escrever 90% das aplicações Flutter. Existem alguns casos de uso específicos que o `go_router` não resolve, nos quais você pode usar a API do Flutter Navigator diretamente ou experimentar outros pacotes encontrados no pub.dev. |
| **Use convenções de nomenclatura padronizadas para classes, arquivos e diretórios.** | Recomendado | Recomendamos nomear classes pelo componente arquitetural que representam. Por exemplo: `HomeViewModel`, `HomeScreen`, `UserRepository`, `ClientApiService`. Para clareza, não recomendamos usar nomes que possam ser confundidos com objetos do SDK do Flutter. Por exemplo, coloque seus widgets compartilhados em um diretório chamado `ui/core/` em vez de `/widgets`. |
| **Use classes de repository abstratas.** | Fortemente recomendado | Classes de repository são as fontes de verdade para todos os dados no seu app e facilitam a comunicação com APIs externas. Criar classes abstratas permite criar diferentes implementações para diferentes ambientes do app, como "development" e "staging". |

---

## Testes

Boas práticas de testes tornam seu app flexível. Também tornam simples e de baixo risco adicionar nova lógica e nova UI.

| Recomendação | Prioridade | Descrição |
|---|---|---|
| **Teste componentes arquiteturais separadamente e em conjunto.** | Fortemente recomendado | Escreva testes unitários para cada classe de service, repository e ViewModel. Esses testes devem testar a lógica de cada método individualmente. Escreva testes de widget para views. Testar roteamento e injeção de dependência são particularmente importantes. |
| **Crie fakes para testes (e escreva código que aproveite os fakes).** | Fortemente recomendado | Fakes não se preocupam com o funcionamento interno de um dado método tanto quanto se preocupam com entradas e saídas. Se você tem isso em mente ao escrever código da aplicação, é forçado a escrever funções e classes modulares e leves com entradas e saídas bem definidas. |

---

## Recursos recomendados

### Código e templates

- **Código fonte do app Compass** — Código fonte de uma aplicação Flutter completa e robusta que implementa muitas destas recomendações.
- **very_good_cli** — Um template de aplicação Flutter feito pelos especialistas em Flutter da Very Good Ventures. Este template gera uma estrutura de app similar.

### Documentação

- **Documentação de arquitetura Very Good Engineering** — Very Good Engineering é um site de documentação da VGV que possui artigos técnicos, demos e projetos open-source. Inclui documentação sobre arquitetura de aplicações Flutter.

### Ferramentas

- **Flutter developer tools** — DevTools é um conjunto de ferramentas de performance e debugging para Dart e Flutter.
- **flutter_lints** — Um pacote que contém os lints para apps Flutter recomendados pelo time do Flutter. Use este pacote para encorajar boas práticas de código na equipe.