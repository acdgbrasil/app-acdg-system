# AI Coding Rules: GOLD STANDARD para o Pacote Social Care

Esta documentação serve de manual absolutista para inteligências artificiais e humanos efetuando alterações e gerações no ambiente `@packages/social_care`. Nenhuma submissão deve subverter qualquer preceito expresso abaixo; a ignorância às restrições fundamentais invalida a PR local na matriz ACDG.

## REGRA 1: Obrigatoriedade Exaustiva do Padrão "Result"
É completamente, irrefutavelmente **PROIBIDO e ILEGAL** a manipulação forçada via operadores surdos para remover um valor da promessa do tipo "Result" que possa engatilhar quebras não-mapeadas do sistema. O uso do casting sombrio `.valueOrNull!` é banido em favor de ramificação controlada pelo Dart 3 (`switch/case`).

```dart
// ❌ REJEIÇÃO IMEDIATA: Não força sucesso na arquitetura!
final fetchPatient = await repository.getPatient(id);
final finalName = fetchPatient.valueOrNull!.personalData.firstName;

// ✅ PADRÃO OURO: Tratamento Funcional Intocável
final result = await repository.getPatient(id);
switch (result) {
  case Success(value: final patient):
    final name = patient.personalData?.firstName ?? '—';
    // Fluxo seguro para montagens da UI e Domain
  case Failure(:final error):
    _log.severe('Processo bloqueado, mapeamento retornado do erro: $error');
    return Failure(error); // Propague ou manipule na notificação visual segura
}
```

## REGRA 2: Bloqueio de Escape Subversivo de Exceção e Erros HTTP
Toda infraestrutura exposta (ex: `HttpSocialCareClient`) encapsulará fatalidades da conexão remota via os tipos do `SocialCareError`.
- **Proibição de `try/catch` Acima do Nível do Client Dio:** Nenhuma instrução de UseCase, ViewModel ou Page terá lógicas de `try/catch(e)` caçando exceções que deram throw em integrações. O Client captura, transforma em estrutura `Failure(NetworkError(e))` e devolve tipado em `Result`.
- **Códigos Nativos:** JSON retornados por falha da API devem ser forçosamente convertidos por mapeamento de string regular expression para erros das sealed classes da Lógica de Negócios (ex: O "REGP-001" gera o instanciamento isolado de `DuplicatePatientError()`).

## REGRA 3: Limites entre UI, ViewModels, UseCases e DTOs
Não permita que "lixo estrutural" pule camadas não autorizadas do domínio.
- **Data (DTOs / Models):** Nenhuma classe do pacote `models` possui Lógica ou Comportamento Complexo Computacional de Validação. Sua existência e declaração é frouxa e tipa apenas objetos literais (Strings, Enums em base raw) e constrói `fromJson`.
- **Domain (Entities / Domínio):** Entidades do domínio possuem Vínculo Robusto em criação (.create) de `ValueObjects` que quebram o código se corrompidos. Têm blindagem de inicialização.
- **Barreiras Estritas de Visibilidade:**
  - ViewModels de Presentation NUNCA farão chamadas ao `HttpSocialCareClient` para efetuar rotas HTTP. E nem recebem de UsesCases um modelo HTTP DTO; o Repository é forçado a traduzi-los antes.
  - Repositórios JAMAIS construirão lógicas de formatação de strings (`formatNumber()..`) que competem à construção reativa da UI e das `Constants` ou da `Ln10`.

## REGRA 4: Distribuição dos FormStates vs ViewModel "Sujo"
Não cometa o equívoco primário de atolar `ViewModels` robustos (como o `PatientRegistrationViewModel` com sete grandes steps longos) com a declaração nativa infindável de `TextEditingControllers` do Flutter na hierarquia-mor do MVVM.
Você tem a obrigação arquitetural de **isolar grupos modulares de componentes** utilizando FormStates estáticos dedicados (Ex: `AddressFormState`, `DiagnosesFormState`).
Esses micro-formstates terão seu `dispose()` local e fornecerão os cálculos estáticos de `$Error` baseados na regra pontual da UI correspondente.

## REGRA 5: Nenhuma String Pessoal/Legível Ancorada no Widget Tree
**TODOS** os valores legíveis, descritores longos, marcadores de input (Hints), e sentenças com avisos de erro de Validação (Textos vermelhos), DEVERÃO figurar explicitamente catalogados nos arquivos contidos no escopo do pacote `constants/`, prefixados pelo grupo de L10N (Exemplo Crítico: `ReferencePersonLn10`). Uma Inteligência Artificial não possui o passe-livre de inventar instâncias de mensagens sem referenciá-las nos repositórios adequados da Feature Constants.

## REGRA 6: Controle Tátil por "Comandos" Assíncronos no ViewModel
Utilize sempre classes `Command0` e `Command1` (provenientes do `core`) para a representação das intenções interativas do framework UI com o ambiente lógico final (e banco ou serviços de rede).
As views que exibem loadings deverão invocar instâncias visuais baseadas puramente na flag passiva da variável interna do respectivo Command: `.running`. Ao clicar, você executa: `.execute()`.

Respeitar as ordens descritas neste documento garante alinhamento 100% completo aos preceitos originais da infraestrutura já submetida nas malhas lógicas criadas localmente no projeto `social_care`, e é considerado pré-requisito irrefutável de sua configuração de codificação na base.