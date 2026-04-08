# Camada de Apresentação e UI (UI Layer): Pacote Social Care

A camada visual do pacote adota práticas avançadas de MVVM focado em eficiência com `ValueNotifier` em conjunto com Riverpod para injeção. Segue estritamente o padrão "Atomic Design".

## 1. Injeção de Dependências (`di/`)
Os ViewModels são injetados de forma estrita pelo shell do aplicativo (App Module). O Riverpod é usado apenas como Service Locator (ex: `familyCompositionViewModelProvider`). Eles lançam `UnimplementedError` no escopo do pacote caso não sejam sobrescritos via `ProviderScope` no aplicativo raiz.

## 2. Modelos de UI (`models/` e `constants/`)
- `constants/*_ln10.dart`: Contêm 100% das strings visuais, tooltips e placeholders da UI. *Nada de "hardcoded strings" em arquivos de Widget.*
- Os Modelos da UI (`FamilyMemberModel`, `PatientSummary`, `PatientDetail`) são derivados dos Modelos de Domínio ou Entidades Brutas pelo `ViewModel` ou Repositório, para que o componente visual nunca dependa das complexidades do pacote `shared/domain`.
- Computações de visualização exclusivas (ex: método `age()` no `FamilyMemberModel`) ficam neles mesmos, simplificando os widgets.

## 3. View Models (`viewModels/`)
- **Herança:** Estendem `BaseViewModel`.
- **Commands:** Usa `Command0`, `Command1` para expor funções transacionais (carregamento, salvamento). Eles encapsulam status de `running` e `error`. Não crie variáveis `bool isLoading = false;` e setStates manuais em ViewModels, use a flag `command.running`.
- **Controle de Estado Mestre:** As interações não dependem de `ChangeNotifier` pesados em toda parte, os dados são atualizados internamente num ciclo coeso, e é emitido o `notifyListeners()` apenas quando a operação completa.

## 4. Form States (`view/components/forms/`)
Em vez de encher o ViewModel de Controladores de Texto, formulários longos têm suas propriedades encapsuladas em classes puras:
- Estão divididas por seções (ex: `PersonalDataFormState`, `AddressFormState`, `DiagnosesFormState`).
- Usam `TextEditingController` para inputs diretos de teclado, e `ValueNotifier<T?>` para inputs de seleção ou booleanos (Rádios, Dropdowns, Checkboxes).
- Definem de forma centralizada os Getters para erros (`String? get cpfError`). Retornam nulo se tudo estiver correto.
- **Métodos Funcionais:** `isValidForNextStep`, `validationErrors` (lista das strings de falha na ordem para o *ErrorBanner*).
- Devem incluir método `dispose()` explícito.

## 5. UI Components (Atomic Design)
- **Atoms/Molecules:** Construídos como classes `StatelessWidget`.
- Recebem os valores estritamente necessários via construtor:
  - Para inputs de texto: recebe o `TextEditingController`.
  - Para dropdown/rádios: recebe o `ValueNotifier<T>` usando internamente `ValueListenableBuilder` limitando reconstrução só praquele widget.
- **A regra de Ouro MVVM da UI:** Views são "dumb" (burras). Nenhum widget deve chamar lógica de UseCase; tudo é repassado via callbacks ou notifiers. 
- *Proibido criar métodos grandes tipo `_buildSection()` dentro da Page; Quebre tudo em Widgets (Files dedicados).*

## 6. Pages (Telas)
- Implementadas usualmente como `ConsumerStatefulWidget`.
- Inicializam os carregamentos (`vm.load.execute()`) dentro do `addPostFrameCallback` no `initState`.
- Utilizam `ListenableBuilder` atrelado aos *Commands* ou ao ViewModel em si para redesenhar partes da tela ao mudar status de execução (ex: mostrando loading circular quando `vm.load.running`).

## Resumo para IAs
- **Nunca use `setState` para regras de negócio e validação, use FormStates.**
- **Evite classes Widget gigantes.** Isole a lógica de formulário no FormState e os pedaços de tela em Widgets próprios.
- **Injete ViewModels.** Nunca construa instâncias pesadas na UI.
- Use `Command` para ações e interações. Escute a mudança na flag `.running`.