# Camada de Apresentação e UI (UI Layer): Pacote Social Care

A camada visual do pacote transcende os modelos normais do Flutter. Utiliza as disciplinas puristas do padrão **MVVM**, reativas, guiadas a eventos via Riverpod como locador e `Command` objects, combinadas com um isolamento visual completo chamado **Atomic Design**. Evita sobrecargas da árvore de reconstrução global do sistema (as onerosas chamadas nativas globais `setState` da Widget Tree).

## 1. O Fluxo Riverpod e Modelos da UI (`models/`, `constants/`, `di/`)
- **Strings Intocadas em Código (`Constants`):** Nenhum widget de formulário possui código de UI "Hardcoded". Placeholders e títulos de steps (`"Diagnóstico"`, `"Informar Endereço"`) situam-se restritamente no diretório `constants/` (`ReferencePersonLn10.dart`). Mudanças de nomenclatura de botões e erros da tela operam sempre pelos arquivos `Ln10`.
- **Injeção de ViewModels:** Os Provedores assinam dependências em `di/` (ex: `patientRegistrationViewModelProvider`). O pacote em si recusa-se a instanciar o UseCase; no Provider, o dev notará um gatilho de bloqueio: `throw UnimplementedError()`. Somente a raiz global principal da aplicação (O Core do ecossistema) será capaz de sobrepor e injetar implementações via escopo Riverpod.
- **Modelos de Vista Isolados:** Widgets que desenham linhas e tabelas complexas (A tabela de familiares, listagem principal de home) recebem modelos finos e traduzidos (`PatientSummary`, `FamilyMemberModel`) com métodos computados (o cálculo real da idade por string temporal ocorre na `age()` deste Model), o que purga poluição computacional das camadas visuais.

## 2. Gerenciamento do Estado Local: FormStates e ViewModels
Os cenários gigantes de formulários em passo-a-passo (Wizards) tornariam o ViewModel numa classe insalubre de milhares de linhas caso hospedasse cada entrada de input.

### 2.1 Os FormStates Específicos (`view/components/forms/`)
O ViewModel particiona propriedades pesadas em instâncias de classes de manipulação separadas chamadas **FormStates**.
- **Exemplo Real:** `AddressFormState`, `SpecificitiesFormState`.
- **Mecanismos:** Eles armazenam os `TextEditingController` de campos textuais e `ValueNotifier<Type?>` para listas suspensas (UFs) e opções fechadas em botões rádio.
- **Funções Funcionais Nativas:** Os getters de erro existem no nível do próprio campo. O formulário verifica a obrigatoriedade internamente. Se vazio, devolve um erro da Constante correspondente:
  ```dart
  String? get cityError {
     if (city.text.trim().isEmpty) return ReferencePersonLn10.errorInformCity;
     if (city.text.length < 2) return ReferencePersonLn10.errorMinChars2;
     return null;
  }
  ```
- **Lista de Agregado de Falhas:** O FormState oferece `isValidForNextStep` (calculado de getters) e consolida a coleção de strings no vetor `validationErrors` para exibição sumária nos banners visuais superiores da página vermelha.

### 2.2 O Maestro: The View Model
- **Comandos de Async Action:** Utilizando a tipagem de encapsulamento seguro e reativo do módulo core do pacote da plataforma: `Command0` e `Command1`. O Action Flow mapeia estados automáticos do seu `execute()`, mudando flags internas (`running`, `completed`) sem exigir códigos paralelos repetitivos (`isLoading = true; await ...; isLoading = false;`).
- **A Função Colossal `buildIntent()`:** Na classe do `PatientRegistrationViewModel`, a transição dos infinitos micro-estados (`FormStates`) de campos é aglomerada meticulosamente na montagem manual e tradução no Intent primário (ex. unindo os strings com "trim()", mascarando e traduzindo "masculino" de radio button para "Sex.masculino" de Domain Enum).

## 3. Práticas do Atomic Design: Dumb Components vs Micro-Renders
- **Dumb UI:** Nem o mais profundo componente (`FirstNameInput`) do diretório `components/` deverá ler da injeção central o Riverpod ou extrair algo mágico de instâncias de `ViewModel` ocultas. É mandatório que o elemento superior instancie propriedades isoladas: "Tome seu `Controller` aqui. Tome seu CallBack aqui." Componentes menores respondem cegamente.
- **Isolamento Constante do Elemento `ListenableBuilder` / `ValueListenableBuilder` (Micro-renders):** Cada preenchimento com clique e caractere afeta o framework no recálculo e layout repaints da UI. No lugar de engatilhar os updates nos "Pais" grandiosos de layout, os TextFields e RadioGroups inserem no invólucro do próprio input individual seus Listeners (`listenable: firstNameController`) garantindo eficiência massiva por repintura apenas do campo que pulsa ou mostra mensagens de texto-inferiores vermelhas.
- **Elimine `_buildMethods` Gigantes na Pagina:** Todo fragmento lógico da UI visual complexa requer arquivos separados dentro de `view/components/`. A classe mestre (ex: `PatientRegistrationPage`) compõe a junção (`RegistrationWizardTemplate` com o switch de telas via `RegistrationStepSwitcher`).
- **A Complexidade Aninhada Modular (Composição Familiar):** O passo 4 de Adicionar Familiares tem vida autônoma. O `FamilyMemberModal` opera com seu state transitório, submete as strings de formulários para seu formstate interno isolado de pop-up e, em salvamento, remete via callback onSave o snapshot computado final para que a Tabela Externa do formulário mestre empilhe e calcule os agregadores de perfis de Idade visualmente em tempo real.