# Auditoria Arquitetural Detalhada — Camada de Views e Pages (`packages/social_care/lib/src/**/view/page/*`)
**Data:** 02 de Abril de 2026
**Especialista:** flutter-arch-review (Gemini CLI)

Esta auditoria foca especificamente nas **Pages (Telas)** do módulo `social_care`, analisando o acoplamento, tamanho dos arquivos, separação de responsabilidades (UI vs Lógica) e uso do Design System.

As páginas estão, de fato, "gigantes e estranhas" porque estão acumulando responsabilidades que violam o princípio da "UI Burra" (Dumb UI) e o padrão de Atomic Design estabelecido para o projeto.

---

## 1. Problemas Críticos nas Pages

### 1.1 "Fat Pages" e Componentes Inline (Falta de Componentização)
**Arquivos afetados:** 
- `src/ui/family_composition/view/page/family_composition_page.dart` (Mais de 400 linhas)

**🚫 Anti-padrão:**
A página inteira está construída em um único arquivo gigantesco, usando dezenas de métodos privados como `_buildNavBar()`, `_buildHeader()`, `_buildSpecificities()`, `_buildActionBar()`. Isso fere o **Atomic Design**. A página deve ser apenas um "Template" que posiciona "Organisms".
**✅ O Padrão Correto:**
- **Ação:** Extrair cada método `_build*` para sua própria classe `StatelessWidget` dentro da pasta `view/components/` (ex: `FamilyNavBar`, `FamilyActionBar`). A página deve ter, no máximo, 100-150 linhas, focando apenas na estrutura principal (Scaffold) e na injeção do ViewModel nesses componentes.

### 1.2 Orquestração de Fluxo e Regras de Negócio na UI
**Arquivos afetados:**
- `src/ui/patient_registration/view/page/patient_registration_page.dart` (Método `_handleSubmit`)
- `src/ui/family_composition/view/page/family_composition_page.dart` (Métodos `_openModal` e `_handleCaregiverToggle`)

**🚫 Anti-padrão:**
A UI está tomando decisões de fluxo complexas. No `patient_registration_page.dart`, o método `_handleSubmit` verifica se a string de erro contém `'SocketException'` ou `'TimeoutException'` para decidir qual modal mostrar. No `family_composition_page.dart`, o `_openModal` aguarda o fechamento do modal, busca manualmente um ID na lista e dispara outra requisição para definir o cuidador.
Isso é um vazamento gravíssimo de lógica: a UI está orquestrando regras de negócio e tratando erros de rede por string matching.
**✅ O Padrão Correto:**
- **Ação:** O ViewModel deve ser o único orquestrador. A UI deve apenas despachar a intenção: `viewModel.savePatient()`. O ViewModel altera seu estado para `Success` ou `Error(NetworkError)`. A UI usa um `ListenableBuilder` para reagir a esse estado e exibir o Toast ou Modal adequado. O parsing de erro de rede deve ser feito no `Repository` (retornando um `Failure(NetworkSocialCareError)`), nunca na UI.

### 3. Hardcoding de Cores e Fuga do Design System
**Arquivos afetados:**
- Basicamente todas as Pages e Components (ex: `home_page.dart`, `family_composition_page.dart`)

**🚫 Anti-padrão:**
Uso massivo de cores mágicas injetadas diretamente nos widgets: `Color(0xFFF2E2C4)`, `Color(0xFF4F8448)`, `Color(0x33261D11)`. Isso destrói a escalabilidade do app (impossibilita a troca de temas, como Dark Mode, e centralização de design tokens).
**✅ O Padrão Correto:**
- **Ação:** Substituir TODAS as instâncias de `Color(0xFF...)` por referências ao `AppColors` do `package:design_system` ou `Theme.of(context).colorScheme`. O pacote `design_system` já existe e deve ser a única fonte de verdade para tokens visuais.

### 4. Navegação Hardcoded e Acoplamento Estrito
**Arquivos afetados:**
- Todas as Pages.

**🚫 Anti-padrão:**
As páginas estão chamando `context.go('/social-care')` e `context.go('/patient-registration')` diretamente nos botões. Se a URL da rota mudar, dezenas de arquivos quebrarão.
**✅ O Padrão Correto:**
- **Ação:** Extrair a navegação. Ou o ViewModel dispara eventos de roteamento que um `RouterListener` pega, ou as rotas devem ser referenciadas por Constantes/Enums (ex: `context.goNamed(AppRoutes.home)`), usando o suporte a nomes do `go_router`.

---

## 2. Plano de Ação para as Pages (UI Refactoring)

Para limpar as páginas e trazê-las de volta ao "Gold Standard", siga este fluxo:

1. **Destruir o Hardcode Visual:**
   - Faça um _Find and Replace_ global na pasta `ui` substituindo `Color(0xFF...)` pelas cores correspondentes no `AppColors` do `design_system`.

2. **Componentização Extrema (Atomic Design):**
   - Quebre a `FamilyCompositionPage` em: `FamilyCompositionHeader`, `FamilyCompositionSpecificities`, `FamilyCompositionActionBar`.
   - Limpe o arquivo da página para que contenha apenas o `Scaffold`, `SafeArea` e a disposição em `Column`/`Row` desses componentes.

3. **Mover a Orquestração para o ViewModel:**
   - Em `PatientRegistrationPage`, remova toda a checagem de erros do `_handleSubmit`. O `PatientRegistrationViewModel` deve expor um `ValueNotifier<RegistrationState>` (contendo Idle, Loading, Success, Error). A página apenas escuta essa variável e reage (mostrando dialog).
   - O tratamento de erros de conexão (SocketException) DEVE ser feito no `BffPatientRepository` ou no `RegisterPatientUseCase`, que deve encapsular isso em um erro de domínio (ex: `NetworkSocialCareError`) e a UI só checa o tipo do erro.

4. **Desacoplar Lógica de Modais:**
   - Em `FamilyCompositionPage`, a lógica "se adicionou X e era cuidador, então faça Y" deve estar **dentro** do ViewModel (`addMemberAndSetCaregiver()`). A UI apenas chama esse método único com os dados do modal.
