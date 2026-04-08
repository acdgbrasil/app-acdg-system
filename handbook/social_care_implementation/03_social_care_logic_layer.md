# Camada Lógica e de Domínio (Logic & Domain Layer): Pacote Social Care

Esta camada abriga as regras de negócio puras, sem dependências do Flutter (sem `BuildContext`, sem `Widgets`).

## 1. Erros de Domínio (`domain/errors/`)
- Classes abstratas e seladas baseadas em `SocialCareError` (extends `Equatable implements Exception`).
- **Famílias de Erro:**
  - `PatientError` (ex: `DuplicatePatientError`, `InvalidDataError`, `PatientNotFoundError`)
  - `AssessmentError` (ex: `InconsistentAssessmentError`)
  - `FamilyError` (ex: `PrMemberRequiredError`, `MultiplePrimaryReferencesError`)
  - `NetworkError` e `ServerError` (Infraestrutura)
- **Mensagem User-Facing:** Toda classe define um `toString()` retornando uma string amigável que a UI pode mostrar diretamente ao usuário final.

## 2. Schemas de Validação (`domain/schemas/`)
- Utiliza a biblioteca `zard` (equivalente ao Zod no TypeScript).
- `SocialCareSchemas` consolida regras complexas em validadores, como obrigatoriedade de formato de nomes (`name`), validações cruzadas de especificidades, e lógicas compartilhadas (ex: Validação real do dígito de `Cpf`).

## 3. Mappers (`logic/mappers/`)
A montagem de uma Entidade de Domínio madura não acontece na UI, nem no Repository. É de responsabilidade dos Mappers, que pegam os Intents e retornam entidades complexas (`Patient`, `FamilyMember`, etc).
- **Processo (ex: `RegistryMapper.toPatient`):**
  1. Executa validação de schema (`zard`). Se falhar, retorna `Failure(AppError(...))`.
  2. Inicializa Value Objects que fazem suas próprias validações de tipagem e formato (`Cpf.create(intent.cpf)`, `TimeStamp.fromDate`).
  3. Agrupa as primitivas em grupos do domínio (`PersonalData.create`, `CivilDocuments.create`, `Address.create`).
  4. Agrega tudo na entidade raiz `Patient.create`.
- **Por que isso é importante?** Garante a validade em todos os aspectos (formatos e regras invariantes) de uma entidade antes mesmo de o código chegar no Repositório.

## 4. Casos de Uso (`logic/use_case/`)
Classes orquestradoras derivadas de `BaseUseCase<Input, Output>` (onde `NoInputUseCase` é para entradas sem parâmetro).
- **Composição:** 
  - Recebem o `PatientRepository` via injeção pelo construtor.
  - O método `execute` recebe um `Intent` (ou ID).
- **Fluxo Típico (Comando de Gravação):**
  1. Chama um `Mapper` para traduzir o `Intent` num agregado de Domínio.
  2. Verifica de forma segura se o mapper retornou falha: `if (domainRes case Failure(:final error)) return Failure(error);`
  3. O UseCase invoca o Repositório injetado, desempacotando o tipo do Mapper: `return _patientRepository.updateSomething((domainRes as Success<Type>).value);`
- **Isolamento e Formato Padrão:** Não lidam com parsing ou controle de estado local; são completamente stateless, encapsulados e fáceis de testar utilizando stubs fakes do Repositório.

## Resumo para IAs
- **Sempre utilize Switch/Pattern Matching para `Result`.** Evite usar o casting sujo `.valueOrNull!`.
- Casos de Uso só devem falar com `Mappers` e `Repositories`.
- **Nunca insira lógica de regras de formatação (Data, Nomes) dentro do View ou do Repository.** Eles devem ficar em Schemas, Value Objects ou Entidades construídas pelos Mappers.