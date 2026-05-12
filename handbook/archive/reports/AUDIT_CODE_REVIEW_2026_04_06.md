# Auditoria de Código e Arquitetura - Padrão Ouro ACDG
**Data:** 06 de Abril de 2026
**Auditor:** ACDG Code Reviewer (Principal Software Engineer)

Esta auditoria baseia-se nas regras estabelecidas pelo Gold Standard da arquitetura ACDG e nos resultados das execuções de testes arquiteturais automatizados (`architectural_guard_test.dart`, `widget_isolation_test.dart`, etc).

## 🛑 Violações de Tolerância Zero (Zero Tolerance)

### 1. Higiene de Widgets (Widget Isolation e Private Build Methods)
**Regra:** Cada arquivo `.dart` na camada de UI DEVE conter no máximo UM `StatelessWidget`. Métodos privados que retornam `Widget` (ex: `_buildHeader()`) são estritamente proibidos. Componentes internos devem ser extraídos para classes `StatelessWidget` separadas para permitir a otimização de `const` pelo Flutter e restringir rebuilds da árvore.
**Referência:** `handbook/references/flutter_archteture/ui_layer.md`

**Arquivos infratores que precisam ser refatorados:**
- **Múltiplos Widgets no mesmo arquivo:**
  - `packages/social_care/lib/src/ui/home/view/components/home_top_bar.dart`
  - `packages/social_care/lib/src/ui/patient_registration/view/components/forms/reference_person/step_diagnoses_content.dart`
  - `packages/social_care/lib/src/ui/patient_registration/view/components/wizard/wizard_button_bar.dart`
  - `packages/social_care/lib/src/ui/patient_registration/view/components/wizard/wizard_stepper.dart`
- **Uso de Métodos Privados de Build (`_build...`):**
  - `packages/social_care/lib/src/ui/patient_registration/view/components/forms/reference_person/step_specificities_content.dart`
  - `packages/social_care/lib/src/ui/patient_registration/view/components/forms/reference_person/step_family_composition_content.dart`
  - `packages/social_care/lib/src/ui/patient_registration/view/components/forms/reference_person/family_member_modal.dart`
  - `packages/social_care/lib/src/ui/patient_registration/view/components/forms/reference_person/step_intake_info_content.dart`
  - `packages/social_care/lib/src/ui/patient_registration/view/components/wizard/wizard_nav_bar.dart`
  - `packages/social_care/lib/src/ui/family_composition/view/components/add_member_modal.dart`

**Sugestão de Refatoração:**
```dart
// ❌ ANTI-PADRÃO
Widget _buildTitle() {
  return Text('Título');
}

// ✅ PADRÃO OURO (Em arquivo próprio ou final do arquivo caso permitido)
class _TitleSection extends StatelessWidget {
  const _TitleSection();
  
  @override
  Widget build(BuildContext context) {
    return const Text('Título');
  }
}
```

---

## 🏛️ Violações de Domínio e Nomenclatura

### 2. Modelos de Domínio e Igualdade (Equatable)
**Regra:** Modelos de domínio (`Entities`, `ValueObjects`, `Sealed Errors`) DEVEM utilizar a extensão `Equatable` para garantir a comparação de objetos por valor e não por referência de memória.
**Referência:** `handbook/principles/ARCHITECTURAL_GOLD_STANDARD.md`

**Arquivos infratores:**
- `packages/social_care/lib/src/domain/schemas/social_care_schemas.dart`
- `packages/social_care/lib/src/domain/errors/social_care_errors.dart`

**Ação Necessária:** Implementar `extends Equatable` e o override do `get props` em todas as classes destes arquivos.

### 3. Convenção de Nomenclatura de Pastas
**Regra:** Nomes de pastas estruturais devem estar sempre no plural quando contiverem múltiplos elementos do mesmo tipo.
**Referência:** `handbook/principles/ARCHITECTURAL_GOLD_STANDARD.md`

**Arquivos infratores:**
- A pasta `packages/social_care/lib/src/data/model` está no singular.
**Ação Necessária:** Renomear para `models` ou `dto`.

---

## 💅 Inconsistências de Design System e UI

### 4. Fidelidade Visual do Design System
O pacote `design_system` possui testes que validam as especificações exatas de componentes Figma. Atualmente, os átomos falham por não estarem "pixel-perfect".

**Componentes quebrados:**
- `AcdgPillButton`: O botão premium de Desktop deve ter sombreamento em múltiplas camadas (multi-layered shadows para "depth"), porém atualmente renderiza apenas uma camada ou nenhuma. (Teste falhando em `acdg_pill_button_premium_test.dart`).
- `AcdgCheckbox`: As dimensões exatas obrigatórias de `24x24` não estão sendo respeitadas.
- `AcdgRegistrationHeader` & `AcdgMemberList`: Apresentam falhas de renderização (overflow ou erros de layout) tanto no desktop quanto no formato responsivo mobile.

---

## 📡 Integração e Regressões Offline-First

### 5. Falhas no Sincronismo (`social_care_desktop`)
O repositório offline-first e o sistema de mensageria estão apresentando falhas críticas de tipo ao tentar mockar ou integrar chamadas remotas de sincronização.

**Erros identificados:**
- **Erro de Tipagem em Sincronização:** `type 'Null' is not a subtype of type 'Future<bool>'`.
  A classe `OfflineFirstRepository` está falhando na função `fetchPatient` porque o mock (`MockLocalRepo.hasPendingActions`) está retornando nulo em vez de uma `Future<bool>`.
- **Mapeamento BFF:** O teste de regressão `REGP-024-FIX: Should map family members and requiredDocuments correctly` está retornando `null` em vez de uma resposta booleana (ou lista válida).

**Ação Necessária:** 
- Corrigir os stubs do `mockito` / `mocktail` no teste do repositório para utilizar `.thenAnswer((_) async => false)`.
- Revisar a Anti-Corruption Layer (Mappers) para `requiredDocuments` de forma a tratar valores possivelmente nulos com `.nonNulls` ou retornos padrão `[]`.

---

## 📋 Resumo do Plano de Ação

1. **Refatorar os `_build...`:** Limpar todos os widgets complexos de formulário e wizard, criando `StatelessWidgets` puros, preferencialmente `const`.
2. **Aplicar Equatable:** Adicionar a dependência e aplicar o mixin nas classes de esquemas e erros no domínio.
3. **Renomear Pasta de Modelos:** `lib/src/data/model` -> `models`.
4. **Fix no Design System:** Ajustar a `BoxDecoration` do `AcdgPillButton` para ter lista de `BoxShadow` com 2 ou mais elementos. Corrigir tamanho fixo (`SizedBox(width: 24, height: 24)`) no Checkbox.
5. **Corrigir Testes de Repositório:** Acertar os mocks que retornam Null no fluxo do `social_care_desktop`.

> Ao resolver estas pendências, todos os comandos do `melos run test` devem finalizar sem erros e o app retornará ao estado de aderência máxima (Gold Standard).
