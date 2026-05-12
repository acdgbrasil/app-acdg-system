# Auditoria Arquitetural Detalhada — Módulo Social Care (`packages/social_care/lib/src/**`)
**Data:** 02 de Abril de 2026
**Especialista:** flutter-arch-review (Gemini CLI)

Esta auditoria minuciosa foi realizada varrendo todo o código do pacote `social_care`, com foco estrito no **Architectural Gold Standard** do projeto (MVVM, Clean Architecture, BFF, State Management, e Padrões de Domínio).

Abaixo estão as violações arquiteturais encontradas, com explicações detalhadas de por que estão erradas (anti-patterns) e o direcionamento exato do que deve ser feito.

---

## 1. Camada de Dados (Data Layer) e Infraestrutura

### 1.1 Violação de Nomenclatura do Padrão Command
**Arquivos afetados:**
- `src/data/commands/assessment_intents.dart`
- `src/data/commands/family_intents.dart`
- `src/data/commands/intervention_intents.dart`
- `src/data/commands/register_patient_intent.dart`
- `src/data/commands/registry_intents.dart`

**🚫 Anti-padrão:**
A pasta está nomeada como `commands`, mas armazena classes com o sufixo `Intent` (DTOs/Value Objects de intenção, ex: `AddFamilyMemberIntent`). Conforme o Gold Standard (Seção 2), o termo **Command** é estritamente reservado para o encapsulamento de ações de interface no ViewModel (como `Command0`, `Command1`).
**✅ O Padrão Correto:**
Estas classes são DTOs puros.
- **Ação:** Renomear a pasta de `src/data/commands/` para `src/data/intents/` (ou `src/data/dtos/`).

### 1.2 Responsabilidades Indevidas no Repositório (God Object)
**Arquivo afetado:** `src/data/repositories/bff_patient_repository.dart`

**🚫 Anti-padrão:**
O Repositório está agindo como Mapeador Universal e Serviço Analítico. Ele realiza a montagem de dezenas de campos JSON "na mão" no método `_toPatientDetail` e, pior, implementa lógica de negócio pura no método `_buildAnalytics` (calculando idade em tempo real e definindo as faixas etárias da família). Repositórios não processam lógica de negócio.
**✅ O Padrão Correto:**
- **Ação:** O repositório deve delegar a conversão de/para o BFF usando as classes estáticas presentes em `bff/shared/lib/src/infrastructure/mappers/` (ex: `PatientMapper`).
- **Ação:** O cálculo do perfil etário (`AgeProfileDetail`) deve ser realizado por um `Domain Service` (ex: `family_analytics.dart` do `shared`) ou vir pronto do backend BFF.

---

## 2. Camada de Lógica (Use Cases e Mappers)

### 2.1 Uso Indireto/Incompleto de Mappers
**Arquivos afetados:** `src/logic/mappers/registry_mapper.dart` e `src/ui/patient_registration/viewModel/patient_registration_view_model.dart`

**🚫 Anti-padrão:**
Embora os mappers como `RegistryMapper` existam, o ViewModel `PatientRegistrationViewModel` continua criando a montagem gigantesca do `RegisterPatientIntent` manualmente em seu método `buildIntent()` — que conta com mais de 100 linhas e até faz resolução de UUIDs de `LookupItem` (`_resolveIdentityTypeId`).
**✅ O Padrão Correto:**
O ViewModel deve simplesmente repassar o FormState (ou um agregado dele) e um `Mapper` (ou o próprio `Intent.fromFormState`) fica responsável por unificar esses dados. ViewModels não resolvem chaves para UUIDs.

---

## 3. Camada de Apresentação (UI e ViewModels)

### 3.1 Reatividade Redundante e Anti-padrão de ValueNotifier
**Arquivos afetados:**
- `src/ui/patient_registration/viewModel/patient_registration_view_model.dart`
- `src/ui/home/viewModel/home_view_model.dart` (junto de `HomeFormState` e `DetailPanelState`)

**🚫 Anti-padrão:**
Os ViewModels herdam de `BaseViewModel` (que é um `ChangeNotifier`). No entanto, eles instanciam múltiplos `ValueNotifier` internamente (ex: `final currentStep = ValueNotifier<int>(0);`). Isso quebra a Fonte Única de Verdade (Single Source of Truth), forçando a UI a usar `ValueListenableBuilder` pulverizados.
**✅ O Padrão Correto:**
Variáveis de estado primitivas no ViewModel devem ser privadas com getters públicos. Quando uma variável sofre mutação, chama-se `notifyListeners()`.

### 3.2 Validação Hardcoded no "FormsHold Pattern"
**Arquivos afetados:** `src/ui/patient_registration/view/components/forms/reference_person/personal_data_form_state.dart` (e demais FormStates)

**🚫 Anti-padrão:**
O uso do *FormsHold Pattern* é válido para dividir estados gigantes, mas o `PersonalDataFormState` contém funções locais como `_namesValidator` e Expressões Regulares (`_brazilPhoneRegex`) em hardcode, validando os dados na unha. O Gold Standard exige que validações de formato pertençam ao Domínio/Value Objects (ex: O pacote já tem `SocialCareSchemas.patientRegistration` usando Zard).
**✅ O Padrão Correto:**
A UI/FormState envia o dado bruto para a instância do Value Object ou tenta o `safeParse` no schema. Se retornar erro (ex: `Failure`), o erro do Domínio é pego e exibido na UI. Nunca replique a lógica do que compõe um telefone válido na camada visual.

### 3.3 Controle Manual de Carregamento (Loading Flags)
**Arquivo afetado:** `src/ui/family_composition/viewModel/family_composition_view_model.dart`

**🚫 Anti-padrão:**
Utilização da flag `bool _isLoading = false;` e reatribuições (`_isLoading = true; notifyListeners();`).
**✅ O Padrão Correto:**
O projeto usa a arquitetura baseada no `Command` (ex: `Command1`, `Command0`). Para fluxos de load (como o `loadPatient()`), este deve ser encapsulado em um `Command0`, de forma que a UI possa consumir `viewModel.loadPatientCommand.running` diretamente.

### 3.4 Inconsistência do Naming Convention de Pastas
**Arquivos afetados:** Diretórios nomeados como `viewModel`
- `src/ui/home/viewModel/`
- `src/ui/patient_registration/viewModel/`
- `src/ui/family_composition/viewModel/`

**🚫 Anti-padrão:**
O uso de camelCase ou singular em pastas do Dart viola a convenção (snake_case).
**✅ O Padrão Correto:**
Renomear todas as pastas de `viewModel/` para `view_models/`.

### 3.5 Conversão Estrutural Oculta (Domain logic vazando)
**Arquivo afetado:** `src/ui/family_composition/viewModel/family_composition_view_model.dart`

**🚫 Anti-padrão:**
O método `_extractMembers` e `ageProfile` transformam dados brutos (JSON) provenientes da consulta em modelos da interface. Processar JSON com casts brutos `json['personId'] as String?` na camada UI contorna toda a garantia de tipagem (type-safety) do Dart.
**✅ O Padrão Correto:**
A tipagem deve ser garantida no Mapper/Repositório e repassada ao ViewModel como entidade ou DTO estrito. A interface apenas consome e formata.

---

## 4. Plano de Ação & Guia de Correção Prático

1. **Refatoração dos Imports e Pastas:**
   - Renomear `/commands` para `/intents`.
   - Renomear `/viewModel` para `/view_models`.

2. **Limpeza do `BffPatientRepository`:**
   - Excluir o método interno `_buildAnalytics` e `_toPatientDetail`.
   - Usar as classes em `bff/shared/lib/src/infrastructure/mappers/` ou garantir que as tipagens das classes locais usem `factory .fromJson()` com `json_serializable`, removendo cálculos complexos.

3. **Otimização do `PatientRegistrationViewModel`:**
   - Trocar todas as variáveis `ValueNotifier<T>` (como `parentescoLookup`, `currentStep`, `showStepErrors`) para tipos puros (`T`) + `notifyListeners()`.
   - Mover todo o script de mais de 100 linhas de `buildIntent` para um método na camada lógica (como um `IntentFactory` ou injetá-lo na passagem do mapper).

4. **Padronização das FormStates:**
   - Em `PersonalDataFormState`, remover os RegEx de telefone e regras de string longa.
   - Enviar a string para validação via Zard/Schema ou pelo Value Object e, com base no `Failure` do domínio, refletir a mensagem traduzida da `ReferencePersonLn10`.

5. **Correção do Padrão Command no FamilyComposition:**
   - Substituir `_isLoading` e o método `loadPatient` por um `late final Command0<void> loadPatientCommand;`.

---
**Nenhum arquivo ou regra foi deixada de fora. O código listado requer refatoração para adequação técnica antes de iniciar novos desenvolvimentos no pacote.**