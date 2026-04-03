# Relatório de Auditoria Arquitetural — Ecossistema ACDG
**Data:** 02 de Abril de 2026
**Status:** 🔴 CRÍTICO (Necessita Refatoração em Módulos Chave)

## 1. Executivo
Esta auditoria identificou desvios significativos do **Architectural Gold Standard** estabelecido para o projeto ACDG. Embora o núcleo de domínio (`bff/shared`) esteja bem estruturado com imutabilidade e invariantes, as camadas de **Apresentação (ViewModels)** e **Dados (Repositories)** nos pacotes Flutter apresentam vazamentos de responsabilidade, reatividade redundante e lógica de negócio mal posicionada.

---

## 2. Problemas Críticos e Anti-padrões

### 2.1. Reatividade Redundante (ValueNotifier dentro de ChangeNotifier)
**Problema:** O uso de `ValueNotifier` para campos de estado dentro de ViewModels que já herdam de `BaseViewModel` (ou `ChangeNotifier`).
- **Onde encontrar:** `AuthViewModel`, `PatientRegistrationViewModel`.
- **Por que é errado:** Força a View a gerenciar múltiplos `ValueListenableBuilders` ou `ListenableBuilders`, quebrando o contrato de "fonte única de verdade" do ViewModel. Além disso, gera reconstruções duplicadas quando `notifyListeners()` é chamado.
- **Padrão Correto:** Campos privados com getters e atualização via `notifyListeners()` centralizado.
- **Referência:** `handbook/principles/ARCHITECTURAL_GOLD_STANDARD.md` — Seção 3.

### 2.2. Gestão Manual de Estado de Carga (isLoading booleans)
**Problema:** Uso de variáveis booleanas manuais para controlar estados de carregamento.
- **Onde encontrar:** `FamilyCompositionViewModel` (`_isLoading`).
- **Por que é errado:** O projeto utiliza o **Command Pattern**. O estado de execução (`running`) já é provido nativamente pelo objeto `Command`. Gerenciar manualmente cria estados inconsistentes e código verboso.
- **Padrão Correto:** Encapsular ações assíncronas em `Command` e usar `command.running` na UI.
- **Referência:** `handbook/architecture/IMPLEMENTATION_REFERENCE.md` — Seção 2.

### 2.3. Vazamento de Lógica de Mapeamento (Mapping in VM/Repo)
**Problema:** ViewModels e Repositories realizando conversões complexas de JSON ou montagem de objetos de domínio.
- **Onde encontrar:** 
    - `PatientRegistrationViewModel`: Métodos `_buildFamilyMembers`, `_resolveIdentityTypeId`.
    - `FamilyCompositionViewModel`: Método `_extractMembers` (processamento direto de JSON).
    - `BffPatientRepository`: Método `_toPatientDetail` (montagem manual de JSON Maps).
- **Por que é errado:** O ViewModel deve apenas orquestrar intents. O Repository deve apenas entregar dados. A lógica de conversão deve viver em **Mappers** isolados.
- **Padrão Correto:** Criar `Mappers` estáticos (ex: `PatientMapper`) para converter entre DTOs, API Models e Domain Entities.
- **Referência:** `handbook/principles/ARCHITECTURAL_GOLD_STANDARD.md` — Seção 6.

### 2.4. Lógica de Negócio em Camadas Erradas
**Problema:** Cálculo de analíticos e regras de negócio dentro do Repository.
- **Onde encontrar:** `BffPatientRepository` (`_buildAnalytics`).
- **Por que é errado:** Repositories não devem "saber" calcular perfis etários ou outras métricas. Isso é lógica de domínio ou de um serviço especializado.
- **Padrão Correto:** Mover a lógica para um `Domain Service` ou utilizar os serviços de analíticos já existentes em `bff/shared/lib/src/domain/analytics/`.

### 2.5. Strings Hardcoded e Falta de L10n
**Problema:** Mensagens de erro e labels de UI escritas diretamente no código.
- **Onde encontrar:** `AppRouter` ('Pagina nao encontrada'), `FamilyCompositionViewModel` ('Masculino', 'Feminino').
- **Por que é errado:** Impede a internacionalização (L10n) e dificulta a manutenção de termos técnicos em todo o app.
- **Padrão Correto:** Usar `AppLocalizations` ou constantes de tradução centralizadas.

---

## 3. Inconsistências de Nomenclatura e Estrutura

| Item | Situação Atual | Padrão Esperado |
| :--- | :--- | :--- |
| **Pastas** | `.../viewModel/` (minúsculo/singular) | `.../view_models/` (snake_case/plural) |
| **IDs** | `UuidUtil.generateV4()` no VM | Geração na Infra/Mapper ou Domain |
| **Erros** | `result.error.toString()` na UI | `switch (result)` exaustivo com Sealed Classes |

---

## 4. Plano de Ação Recomendado

1.  **Sprints de Refatoração de ViewModels:**
    - Eliminar `ValueNotifier` de todos os ViewModels.
    - Substituir `isLoading` por `Command.running`.
    - Extrair lógicas de mapping para classes `Mapper`.
2.  **Saneamento do Repository:**
    - Remover cálculos de analíticos do `BffPatientRepository`.
    - Garantir que o Repository retorne Entidades de Domínio ou DTOs estruturados, nunca construindo JSON manualmente.
3.  **Padronização de Pastas:**
    - Renomear diretórios `viewModel` para `view_models` em todo o pacote `social_care`.
4.  **Implementação de L10n:**
    - Varrer a UI e mover strings fixas para arquivos de tradução.

---
**Auditor:** Gemini CLI (Specialist)
**Nível de Confiança:** 95% (Baseado em varredura heurística e análise de Gold Standard)
