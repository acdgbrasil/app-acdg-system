# Domain & Logic Layer: Regras, Validações e UseCases

A camada Lógica isola completamente o "Core do Negócio" do pacote `social_care`, assegurando total imunidade em relação à sintaxe Flutter/Widget ou detalhes da rede (Dio, HTTP). A robustez técnica aqui preza pela pureza funcional, validações explícitas, imutabilidade e propagação limpa de resultados através de Value Objects e tipos abstratos.

## 1. Tratamento Tipado de Erros de Domínio (`domain/errors/social_care_errors.dart`)
Falhas não são meras exceções de runtime; elas são estruturas com taxonomias lógicas. Todas herdam de uma "Sealed Class" `SocialCareError` estendendo `Equatable` e `Exception`.

Cada erro carrega, intrinsecamente, a mensagem traduzida na sobrescrita do método `toString()`. Essa mesma string é exibida diretamente nos modais/toasts da camada visual, eliminando a criação manual de dicionários de erro no ViewModel.

**Anotações da Taxonomia:**
- `PatientError`: Subclasses focadas em persistência básica (`DuplicatePatientError`, `PatientNotFoundError`, `InvalidDataError`).
- `AssessmentError`: Focadas nas Fichas de Avaliação (ex: `InconsistentAssessmentError`).
- `FamilyError`: Exceções de cardinalidade da família (`PrMemberRequiredError`, `MultiplePrimaryReferencesError`).
- Infraestrutura (`NetworkError` e `ServerError`): Usadas como contêineres agnósticos pelo Client HTTP quando falhas generalizadas do BFF ocorrem.

**Diretriz Prática:** Quando necessitar de uma nova quebra de regra de negócio, crie uma subclasse de família específica (como `FamilyError`) em `social_care_errors.dart`, defina os campos (`props` do Equatable) e retorne sua descrição *User-Facing* em `toString()`.

## 2. Validação Estrutural e Tipagem Segura via `zard` (`domain/schemas/`)
Não se assume que strings que dizem ser "Cpf" sejam válidos nem se permite que a injeção do formulário corrompa o sistema.
A classe `SocialCareSchemas` emprega o pacote `zard` (um parser de schema comparável a Zod no ambiente TypeScript) para sanitizar as Intenções da UI:
- **Exemplo de validação de campo:** `static final cpf = z.string().refine((v) => Cpf.create(v).isSuccess, message: 'CPF inválido');`
- **Validação Cruzada Complexa:** O schema `specificities` é capaz de observar múltiplos campos adjacentes simulando a API final. Se `isIndigenousResident == true`, então o campo `indigenousResidentEtnia` passa a ser obrigatório no processamento da mesma árvore. O schema recusa a parse se os invariantes baterem de frente.

## 3. Mappers (Exemplo Crítico: `RegistryMapper`)
Localizados em `logic/mappers/`. Eles são os pedreiros da Arquitetura Limpa. Responsabilidade Absoluta: Pegar dados estúpidos dos `Intents`, executar as validações de Schema e Value Objects, montar o Agregado de Entidade Final, e devolver `Result<Entity>`.

**Dissecando O Fluxo do `RegistryMapper.toPatient(RegisterPatientIntent intent)`:**
1. **Passo de Checagem `zard`:** Compõe um `Map<String, dynamic>` com os dados soltos (Nome, CPF, Sexo) e chama `SocialCareSchemas.patientRegistration.safeParse()`. Se essa peneira reprovar, a função aborta o progresso imediatamente retornando `Failure(AppError(...))` categorizado com o prefixo `'VAL-001'`.
2. **Criação Rígida de Value Objects:**
   - Instancia `TimeStamp.fromDate(intent.birthDate)`. Trata falha se a biblioteca temporal barrar.
   - Monta `PersonalData` chamando seus .trims() (`intent.firstName.trim()`), garantindo sanidade espacial de Strings.
   - Resolve chaves opcionais `Cpf`, `Nis`, `RgDocument` com `.create()` de VOs. Concatena numa sub-entidade `CivilDocuments`.
   - Resolve a parte de Endereço unificando UF, Logradouro, Localização Rural/Urbana, resultando na sub-entidade `Address`.
3. **Geração de Chaves Mestre:** Chama a biblioteca compartilhada `UuidUtil.generateV4()` criando os IDs nativos (`PatientId`, `PersonId`) localmente e injetando neles as embalagens do ValueObject para type-safety.
4. **O Invariante "A Pessoa de Referência (PR) Deve Existir":** A composição da Família insere automaticamente os dados do dono do cadastro na sub-lista de Membros da Família (`FamilyMember`), designando o relacional forçosamente como o `isPrimaryCaregiver: true` da casa.
5. **Agregação Frouxa Condicional:** Algumas fichas preenchidas junto ao cadastro inicial ("Especificidades", "Informações de Ingresso") são criadas localmente no mapper e associadas à raiz final com funções `.copyWith`.

## 4. Orquestradores: Os Use Cases (`logic/use_case/`)
São executores enxutos `extends BaseUseCase<Intent, Retorno>`. 

A sua responsabilidade resume-se à trilogia: Mapear, Analisar a Falha e Delegar ao Repositório.
Ocasionalmente, como na submissão vital do `RegisterPatientUseCase`, ele possui **Dupla Responsabilidade Específica**: Se o `Mapper` de validação barrar dados, o erro solto nativo daquele `Shared` Core local (`AppError`) precisa de conversão para o ecossistema `SocialCareError` que é desenhado para o usuário ler, enquanto falhas naturais do Repositório (erros HTTP parseados ou rede) seguem adiante intocadas.

```dart
// Snippet fundamental de como um Mapper repassa erro mapeado em um UseCase
SocialCareError _mapAssemblyError(Object error) {
  if (error is AppError) {
    return switch (error.code) {
      'PAT-008' => const PrMemberRequiredError(),
      'PAT-009' => const MultiplePrimaryReferencesError(),
      _ => InvalidDataError(error.message),
    };
  }
  return UnexpectedSocialCareError(error);
}
```