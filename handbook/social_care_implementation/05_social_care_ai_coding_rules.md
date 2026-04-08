# Regras Estritas para LLMs (AI Coding Guidelines): Pacote Social Care

Estas são regras não-negociáveis que a Inteligência Artificial DEVE respeitar rigorosamente ao modificar ou escrever código para o ecossistema `social_care` e demais pacotes da aplicação. A base arquitetural está consolidada.

## 1. Pattern Matching Obrigatório
Sempre trate retornos `Result` com a exaustividade proporcionada por `switch` ou `case` do Dart 3.
**NUNCA** utilize atalhos perigosos de desembrulhar valor ignorando o caso de falha.
```dart
// ❌ PROIBIDO E ILEGAL
final success = result.valueOrNull!;

// ✅ CORRETO
switch (result) {
  case Success(:final value):
    return Success(value); // Ou proceda com a regra
  case Failure(:final error):
    return Failure(error); // Trate a falha propriamente
}
```

## 2. Mapeamento da Camada de Rede no Cliente HTTP
Em classes de Cliente HTTP de Serviços do Web BFF (ex: `HttpSocialCareClient` ou similares):
- Todo erro não previsto no JSON retornado da API ou capturado de `Exception` da conexão de rede deve passar pelo mapeamento de falha que traduzirá para a família `SocialCareError`.
- **Sem try/catch vazando:** Use o bloco `try/catch` no Dio para que qualquer `throw` se transforme formalmente em `Failure(NetworkError(e))`, `Failure(ServerError(...))` etc. O Repositório e o ViewModel *NUNCA* poderão ter um `try/catch` nativo para resolver falha de API. Eles só leem a variável `Result`.

## 3. Entidades e DTOs Estritos
- **Models/DTOs (Camada Data):** Use `factory` de `fromJson` e mantenha-os sem complexidade (`final`). Podem conter propriedades opcionais (`?`) frouxas.
- **Domínio/Entities (Camada Domain):** Construtores fortemente tipados e blindados (Mappers os montam e chamam o `.create()` estático ou ValueObjects internos).
- **Não cruze fronteiras:** View Models não leem HTTP. Repositories não geram Widgets. Widgets nunca manipulam DTOs brutos; eles enxergam apenas Modelos Visuais de UI (`PatientSummary`, `FamilyMemberModel`) passados pelo seu ViewModel.

## 4. Uso Adequado dos UI States e Form States
- Não declare `String error` ou `String campo` na raiz do `ViewModel`.
- Form States complexos são Classes à parte do VM. O VM possui uma instância de um Form State.
- Utilize `ValueNotifier` para propriedades individuais ao invés de refazer build de páginas pesadas. Utilize `ListenableBuilder` para monitorar o `ValueNotifier` e realizar Micro-Renderizações, limitando o peso da reconstrução da UI ao escopo atômico de uma Molecule/Input.
- Use extensivamente `.trim()` nos inputs do Controller e evite mutar os controllers na árvore de Build.

## 5. MVVM Commands
Qualquer ação assíncrona feita pelo ViewModel (clique num botão `Salvar`, carregamento de lista na tela Inicial, exclusão de paciente) obrigatoriamente deve utilizar a sintaxe de pacote `core/core.dart` das classes `Command0<R>`, `Command1<R, T>`.
```dart
// Declaração no VM
late final Command1<void, AtualizarAlgoIntent> atualizarCmd;

// Inicialização no VM (Construtor)
atualizarCmd = Command1<void, AtualizarAlgoIntent>((intent) => usecase.execute(intent));

// Na UI (Listener)
ListenableBuilder(
    listenable: vm.atualizarCmd,
    builder: (context, _) => ElevatedButton(
        onPressed: vm.atualizarCmd.running ? null : () => vm.atualizarCmd.execute(intent),
        child: vm.atualizarCmd.running ? Loading() : Text('Atualizar'),
    )
)
```

## 6. L10N (Internacionalização) Rigorosa
NENHUMA string de interface de usuário (texto de botões, erros de formulários, hint text, títulos) deverá ficar solta numa classe `.dart` de widget.
Tudo obrigatoriamente é registrado na classe estática do diretório `constants/` correspondente ao escopo da feature (ex: `ReferencePersonLn10.btnNext`).

Se atenha puramente à estruturação já imposta pelos arquivos dentro de `handbook/` e os documentos listados neste guia de implementação.
