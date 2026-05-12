# Report — Refatoracao Completa do Fluxo de Detalhe

**Data:** 2026-03-31
**Branch:** `feat/refactor-patient-detail-flow`

---

## Resumo

Refatoração end-to-end do fluxo de detalhe do paciente (`getPatient`), eliminando o vazamento de modelos de domínio (`package:shared`) na camada de UI, centralizando a lógica de mapeamento no Repositório e simplificando a ViewModel para gerenciar apenas estado puro.

---

## 1. UI Layer — Desacoplamento de Domínio

### FichaStatus agnóstica ao domínio
- Removido `import 'package:shared/shared.dart'` de `ficha_status.dart`.
- Método `fromPatient(Patient)` substituído por `fromDetail(PatientDetail)`.
- Agora as fichas são derivadas diretamente do modelo de UI, isolando a visualização de mudanças no core.

### PatientDetail limpo
- Removido `import 'package:shared/shared.dart'` de `patient_detail.dart`.
- Removida factory `fromPatient(Patient)` e lógica de analytics computada (`_buildAnalytics`).
- O modelo agora é um POJO puro de UI com getters computados para formatação de strings.

### Novo VO: PatientDetailResult
- Criado `PatientDetailResult` para agrupar `PatientDetail` e `List<FichaStatus>` em um único retorno da camada de dados.

---

## 2. Data Layer — Repositório como Mapper

### BffPatientRepository (Mapeamento Robusto)
- `PatientRepository.getPatient` agora retorna `Future<Result<PatientDetailResult>>`.
- Implementada lógica de mapeamento completa de `Patient` (Domain) -> `PatientDetail` (UI) no repositório.
- Centraliza a conversão de enums (camelCase) e formatação de listas de sub-modelos.
- Repositório assume o papel de "Mapper de Saída", entregando dados prontos para a UI.

### PatientService
- Adicionado método `getPatient(PatientId)` como wrapper puro para o contrato BFF.

---

## 3. Logic Layer — Orquestração de UseCase

### GetPatientUseCase
- Refatorado para aceitar `String` como entrada em vez de `PatientId`.
- Encapsula a criação e validação do Value Object `PatientId`.
- Retorna `PatientDetailResult`, protegendo a ViewModel de conhecer tipos de domínio ou realizar mapeamentos manuais.

---

## 4. UI Layer — ViewModel Simplificada

### HomeViewModel
- Removidos todos os imports de `package:shared/shared.dart`.
- `_selectPatient` agora passa apenas a `String` ID para o UseCase.
- Atribuição direta do resultado (`bundle.patientDetail` e `bundle.fichas`) ao estado, sem lógica de transformação.
- Redução drástica de boilerplate e acoplamento.

---

## 5. Alinhamento com Contratos v3.0.0

### PatientSummaryApiModel
- Adicionado campo `personId` (required no novo contrato) para consistência com o backend.

---

## 6. Verificação e Testes

### Cobertura de Testes
- **23 testes** no package `social_care` passando com sucesso.
- Criados testes unitários para `PatientService`.
- Atualizados testes de `BffPatientRepository` e `GetPatientUseCase` para o novo contrato.
- Corrigidas regressões em testes de UI/Registration que dependiam do UseCase antigo.

### Fakes
- `InMemoryPatientRepository` atualizado para implementar o mapeamento interno, garantindo que testes de integração reflitam o comportamento real de produção.

---

## 7. Fluxo Final do Detalhe

```
View (ID String)
    | execute(id)
    v
HomeViewModel (Command1)
    | execute(id)
    v
GetPatientUseCase (Valida UUID -> PatientId)
    | getPatient(patientId)
    v
BffPatientRepository (Mapeia Patient -> PatientDetailResult)
    | getPatient(patientId)
    v
PatientService (Wrapper BFF)
    | getPatient(patientId)
    v
BFF Contract (SocialCareContract) -> Retorna Patient (Domain)
```

---

**Commit History:**
- `✨ feat(social_care): add getPatient to PatientService and update api models`
- `🏗️ refactor(social_care): decouple PatientDetail and FichaStatus from domain`
- `🔄 refactor(social_care): update repository and implement domain-to-UI mapping`
- `⚡ refactor(social_care): update GetPatientUseCase to handle string input and result bundle`
- `🧹 refactor(social_care): simplify HomeViewModel and remove UI domain leaks`
- `🧪 test(social_care): update unit tests and fakes for the new detail flow`
