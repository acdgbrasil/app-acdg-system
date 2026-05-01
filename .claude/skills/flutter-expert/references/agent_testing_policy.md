# Agent Testing Policy — ACDG

> **Criado:** 2026-04-17
> **Escopo:** `packages/design_system/`, `apps/acdg_system/`, specs `.md` per-feature
> **Perfil alvo:** **A — dev/QA JIT (flutter run -d chrome)**
> **Princípio:** **Semantics é a API pública da UI para agentes — zero código de teste imperativo em Dart.**
> **Complementa:** `ENCAPSULATION_POLICY.md`, `PATTERN_MATCHING_POLICY.md`, `CONCURRENCY_AND_PERFORMANCE_POLICY.md`

---

## Motivação

Testes E2E do Flutter Web tradicionalmente batem nos mesmos problemas:
- **Canvas opaco** — `<canvas>` não tem DOM inspecionável
- **Código frágil** — testes que quebram quando muda label/cor/layout
- **Manutenção linear** — cada tela nova vira +N linhas de test code
- **Coverage x Custo** — tempo de escrever testes E2E é equivalente ao de escrever a feature

O Flutter 3.22+ tem `SemanticsRole` + `Semantics(identifier: ...)` nativo. Isso permite expor a árvore de acessibilidade como **DOM paralelo** que LLMs via MCP conseguem ler.

**A proposta:** a feature escreve UI normalmente usando **componentes do Design System**. Os componentes já expõem semantics. Um arquivo `spec_*.md` declara o que o agente QA deve validar. O agente carrega o spec, lê o DOM semântico, executa ações e assere — **sem código de teste imperativo**.

## Escopo desta versão

Este doc define **contrato** (Design System + formato do spec). O orquestrador MCP real é **ticket futuro** — quando o DS estiver estável com semantics, criamos o agente.

---

## Os 3 pilares

```
┌────────────────────────────────────┐
│   PILAR 1 — Design System          │  componentes Env* expõem
│   (Envolve UI)                     │  identifier + role + state
│   packages/design_system/          │  conforme tabela §4
└──────────────┬─────────────────────┘
               │
               ▼
┌────────────────────────────────────┐
│   PILAR 2 — Spec .md per-feature   │  Matriz de Estado
│   packages/<feature>/specs/        │  (Setup × Ação × Assertion)
│                                    │  formato canônico §5
└──────────────┬─────────────────────┘
               │
               ▼
┌────────────────────────────────────┐
│   PILAR 3 — Agent MCP (FUTURO)     │  orquestrador externo
│   (não escrito ainda)              │  consome spec + controla Chrome
└────────────────────────────────────┘
```

Pilares 1 e 2 são **parte desta política** e podem ser adotados já. Pilar 3 vira sub-ticket quando os Atoms tiverem cobertura semântica.

---

## Perfil A vs B

| Perfil | Quando | Setup | Status |
|--------|--------|-------|:------:|
| **A — dev/QA** | `flutter run -d chrome --dart-define-from-file=.env` + `ENABLE_SEMANTICS=true` | `ensureSemantics()` em entrypoint condicional | **foco atual** |
| **B — prod** | `flutter build web --wasm --release` | Semantics sempre ativo + investigar tree-shaking WASM | 🔭 Horizon — **adotar se** aparecer bug release-only |

**Decisão:** seguir Perfil A. Só revisita Perfil B se bug reproduzível só em `--wasm --release`.

---

## 1. Preparação Flutter (Pilar base)

### `main.dart` — enable semantics via flag

```dart
import 'package:flutter/semantics.dart';
import 'package:core/core.dart'; // Env utility

void main() {
  final enableSemantics = Env.bool('ENABLE_SEMANTICS', defaultValue: false);

  if (kIsWeb && enableSemantics) {
    SemanticsBinding.instance.ensureSemantics();
  }

  runApp(const AcdgRoot());
}
```

**Uso:**
- Dev normal: `flutter run -d chrome` → sem semantics, perf máxima
- QA run: `flutter run -d chrome --dart-define=ENABLE_SEMANTICS=true` → engine injeta `<flt-semantics>`
- Prod: sem mudança (flag não setada)

**Por que não ativar sempre:** apesar do overhead ser pequeno em JIT debug, ativar por padrão cria hábito de "testar em dev e quebrar em prod" se o agente fizer asserts que só passam com semantics ligada. Manter explícito é mais seguro.

---

## 2. Design System — exposição da API machine-readable

### Regra fundamental

> **Toda tela de domínio NUNCA instancia `Semantics` bruto. Toda tela usa componentes `Env*` do Design System. A semântica mora na biblioteca de UI.**

Se o dev precisa lembrar de `Semantics` em cada tela, vira débito garantido. Centralizar **é** a política.

### Contrato de cada componente core

| Componente | Campos obrigatórios | Semantics gerado |
|------------|---------------------|------------------|
| `EnvButton` | `semanticId`, `label`, `onPressed` | `Semantics(identifier, button: true, enabled, label)` |
| `EnvTextField` | `semanticId`, `controller`, `hint` | `Semantics(identifier, textField: true, label, error)` |
| `EnvCard` | `semanticId` (opcional: `role`) | `Semantics(identifier, container: true)` |
| `EnvList` | `semanticId`, `role: SemanticsRole.list` | `Semantics(identifier, container, role: list)` |
| `EnvShimmerLoader` | (nenhum extra) | `BlockSemantics(blocking: true)` — oculta o resto |
| `EnvDecorativeIcon` | (nenhum) | `ExcludeSemantics(child: Icon(...))` |

### §2.1 Botões — identifier obrigatório

**❌ DON'T:**
```dart
ElevatedButton(
  key: const Key('btn_salvar'),  // Key não vira DOM
  onPressed: onSave,
  child: const Text('Salvar'),
)
```

**✅ DO (no Design System):**
```dart
final class EnvButton extends StatelessWidget {
  const EnvButton({
    super.key,
    required this.semanticId,    // test-id estável (não muda por locale)
    required this.label,         // texto visível (muda por locale)
    required this.onPressed,
    this.isLoading = false,
  });

  final String semanticId;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticId,
      button: true,
      enabled: onPressed != null && !isLoading,
      label: label,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CircularProgressIndicator()
            : Text(label),
      ),
    );
  }
}
```

**Uso na tela:**
```dart
EnvButton(
  semanticId: 'btn_salvar_paciente',
  label: 'Salvar',
  isLoading: viewModel.save.running,
  onPressed: viewModel.save.execute,
)
```

### §2.2 Campos de texto — papel + erro explícitos

```dart
final class EnvTextField extends StatelessWidget {
  const EnvTextField({
    super.key,
    required this.semanticId,
    required this.controller,
    required this.hint,
    this.errorText,
  });

  final String semanticId;
  final TextEditingController controller;
  final String hint;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticId,
      textField: true,
      label: hint,
      enabled: true,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          errorText: errorText,
        ),
      ),
    );
  }
}
```

**Integração com §H9 (estado local UI):** `controller` vem do `_MyFormState` local — ViewModel não recebe keystrokes; agente lê `errorText` para asserts de validação.

### §2.3 Containers com role explícito (SemanticsRole)

Flutter 3.22+ permite declarar roles ARIA:

```dart
final class EnvForm extends StatelessWidget {
  const EnvForm({
    super.key,
    required this.semanticId,
    required this.child,
  });

  final String semanticId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      role: SemanticsRole.form,          // LLM sabe que é formulário
      identifier: semanticId,
      child: child,
    );
  }
}
```

Roles úteis: `SemanticsRole.form`, `.list`, `.grid`, `.alert`, `.banner`, `.dialog`.

### §2.4 Decorativos — esconder do DOM

Ícones decorativos, separadores, sombras inflam o DOM e estouram tokens do agente LLM.

```dart
final class EnvDecoratedCard extends StatelessWidget {
  const EnvDecoratedCard({
    super.key,
    required this.semanticId,
    required this.icon,
    required this.child,
  });

  final String semanticId;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      identifier: semanticId,
      child: Container(
        decoration: const BoxDecoration(/* cores, bordas */),
        child: Row(
          children: [
            ExcludeSemantics(child: Icon(icon)),  // ícone sumido do DOM
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
```

### §2.5 Loading states — bloquear leitura durante transição

```dart
final class EnvShimmerLoader extends StatelessWidget {
  const EnvShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const BlockSemantics(
      blocking: true,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
```

Agente não lê nada enquanto o loader está montado → evita alucinação ("li a tela antes dela carregar").

---

## 3. Convenção de `semanticId`

| Padrão | Uso | Exemplo |
|--------|-----|---------|
| `btn_<verbo>_<entidade>` | Botões de ação | `btn_salvar_paciente` |
| `input_<campo>` | Campos de texto | `input_cpf`, `input_nome` |
| `form_<feature>` | Formulários | `form_registro_paciente` |
| `list_<entidade>` | Listas | `list_pacientes` |
| `card_<entidade>` | Cards selecionáveis | `card_paciente` |
| `status_<estado>` | Indicadores de estado | `status_sincronizando`, `status_offline` |
| `msg_<tipo>` | Mensagens | `msg_sucesso`, `msg_erro_rede` |
| `dialog_<contexto>` | Modais | `dialog_confirmar_exclusao` |

**Regras:**
- **snake_case** — linguagem universal, não depende de locale
- **Prefix determinístico** — agent faz queries por prefix (ex: `[identifier^="status_"]`)
- **Sem números/IDs dinâmicos no identifier** — `card_paciente_$id` é anti-padrão; prefira `card_paciente` + filtro por `label` quando necessário desambiguar

---

## 4. Formato canônico do spec `.md`

### Location

```
packages/<feature>/specs/
  spec_<fluxo>.md
```

**Exemplos:**
- `packages/social_care/specs/spec_registro_paciente.md`
- `packages/social_care/specs/spec_ficha_habitacional.md`
- `packages/people_admin/specs/spec_gerenciar_equipe.md`

Rationale: **per-feature alinha com `feat/<id>` PR** — quem mexe na feature mexe no spec no mesmo commit. Zero drift.

### Template

````markdown
# Validação: <Nome do Fluxo>

> Feature: `<feature_id>`
> Autor: `<nome>`
> Última atualização: `<data>`
> Cobertura: `<lista de user journeys>`

## Pré-requisitos

- Flutter: `flutter run -d chrome --dart-define=ENABLE_SEMANTICS=true --dart-define-from-file=.env`
- URL inicial: `http://localhost:<porta>/<rota>`
- Estado do banco: `<empty | seeded with fixtures X>`

## Seletores Conhecidos

Lista dos `semanticId` que o agente deve conseguir localizar:

| Tipo | Identifier | Componente | Descrição |
|------|-----------|-----------|-----------|
| button | `btn_salvar_paciente` | EnvButton | Envia o cadastro |
| input | `input_nome` | EnvTextField | Nome completo |
| input | `input_cpf` | EnvTextField | CPF (máscara 000.000.000-00) |
| form | `form_dados_pessoais` | EnvForm | Seção de dados pessoais |
| status | `status_salvando` | EnvStatusBadge | Indica saving em progresso |
| msg | `msg_sucesso` | EnvAlert | Confirmação pós-save |
| msg | `msg_erro_cpf_invalido` | EnvAlert | Erro de validação de CPF |

## Matriz de Estados (Switch Cases)

| # | Setup (precondição) | Ação | Validação (assertion) |
|---|---------------------|------|-----------------------|
| 1 | `status_novo` visível, form vazio | Digitar "João Silva" em `input_nome`, "11144477735" em `input_cpf`, clicar `btn_salvar_paciente` | `status_salvando` aparece → `status_salvo` + `msg_sucesso` após ≤ 3s |
| 2 | `status_novo` visível | Digitar "João", CPF "111" (inválido), clicar `btn_salvar_paciente` | `msg_erro_cpf_invalido` visível, botão mantém `enabled=true` |
| 3 | Rede offline (simular via DevTools) | Clicar `btn_salvar_paciente` com campos válidos | `msg_erro_rede` visível, `status_offline` ativo |
| 4 | `status_salvando` | (aguardar) | `btn_salvar_paciente` tem `aria-disabled="true"` |

## Cenários PII-safe

**Regra:** specs **NUNCA** usam dados reais. Sempre fixtures:

- CPF válido para teste: `111.444.777-35` (algoritmo mod 11 ok, não pertence a pessoa real)
- CPF inválido: `111.111.111-11`
- Nomes: padrão "Teste Silva", "Maria Exemplo"
- Datas: sempre relativas a hoje ("+30 dias", "-1 ano"), nunca datas que identifiquem pessoa real

## Casos fora de escopo

Cenários que **não** devem ser validados aqui:
- Responsividade (caber em tela pequena) — visual, não semântico
- Cores/tipografia — visual, não semântico
- Velocidade de render — performance, ticket próprio

## Notas de execução (para o agente futuro)

- Agente deve **sempre** ler o DOM antes e depois de cada ação.
- Assertions devem usar `aria-disabled`, `aria-checked`, `role`, `aria-label` — nunca cores/posição.
- Falha do case deve gerar PASS/FAIL com snapshot do DOM no momento da falha.
````

### PII em specs

- **Nunca** usar CPF, CNS, RG de pessoa real
- **Nunca** usar e-mail real (`@exemplo.com` ou `@test.invalid`)
- **Sempre** usar datas relativas ("+30d", "-1y")
- Se precisar imagem, usar placeholder (`via.placeholder.com` ou gerador)
- Specs são versionados em Git — **não commite** dados que violem LGPD

---

## 5. Relação com as 15 políticas existentes

| Política relacionada | Como dialoga |
|---------------------|--------------|
| **Atomic Design** (skill §5) | Atoms `Env*` são o ponto natural da semântica |
| **H1–H9 Encapsulation** | `EnvButton extends StatelessWidget` — pode ser `final class`; H9 (state local) funciona com `EnvTextField.controller` |
| **P1 State Matrix** | Spec `.md` ES a state matrix: `(setup, action) → assertion` |
| **P2 if-case** | Usado em parse de query na lógica de navegação QA |
| **P4 `unreachable`** | Um case logicamente impossível no spec pode lançar `unreachable` se agente detectar |

---

## 6. Roadmap de implementação

### Já aplicável (checklist para próximo componente do DS)
- [ ] Componente exige `semanticId` no construtor (obrigatório)
- [ ] Wrappear com `Semantics(identifier, ...)` conforme tabela §2
- [ ] Propriedades de estado (`enabled`, `selected`, `expanded`) refletem no Semantics
- [ ] Ícones/decoradores envoltos em `ExcludeSemantics`
- [ ] Loading states usam `BlockSemantics`

### Tickets futuros (não neste doc)
- **Sub-ticket DS-semantics:** aplicar §2 em todos os componentes existentes de `packages/design_system/` (audit + refactor)
- **Sub-ticket QA-agent-v0:** escrever orquestrador MCP em Dart — consome `specs/spec_*.md` + controla Chrome via CDP ou Puppeteer
- **Sub-ticket QA-agent-ci:** integração no CI para rodar specs contra staging em cada PR

### Perfil B (horizon)
Quando migrar para `flutter build web --wasm --release`, revisitar:
- Tree-shaking de tear-offs — checar se `Semantics(...)` com identifier dinâmico sobrevive
- Deferred loading — specs de features lazy-loaded precisam guard
- Abrir issue upstream se houver gap

---

## 7. Antipadrões explícitos (DON'T)

### ❌ Não usar `Key` para localização via agent
```dart
ElevatedButton(key: const Key('btn_x'), ...)  // Key não sai no DOM web
```

### ❌ Não localizar por texto visível
```dart
// Spec ruim: "Clicar no botão que diz 'Salvar'"
// Spec bom: "Clicar em `btn_salvar_paciente`"
```

Motivo: locale, A/B test, copy iterations quebram tudo.

### ❌ Não colocar `Semantics` em telas
```dart
// Em uma Page:
Semantics(identifier: 'btn_x', child: ElevatedButton(...))
```
**Onde vai:** **no Design System**. Tela usa `EnvButton(semanticId: 'btn_x')`.

### ❌ Não usar `semanticId` com ID dinâmico
```dart
EnvCard(semanticId: 'card_paciente_${patient.id}', ...)  // ruim
EnvCard(semanticId: 'card_paciente', ...)                // bom
```

Agente filtra por prefixo + diferencia por `label` se precisar.

### ❌ Não confiar em cores/posição para estado
```dart
// Botão cinza = inativo? Agente não enxerga cor.
```
Sempre:
```dart
EnvButton(
  semanticId: 'btn_x',
  onPressed: canSubmit ? onSubmit : null,  // enabled flag vira aria-disabled
)
```

---

## 8. Referências

- Flutter Web Accessibility — dart.dev/flutter docs
- `SemanticsRole` — Flutter 3.22+ changelog
- Model Context Protocol (Anthropic) — referência para Pilar 3 futuro
- `handbook/architecture/ENCAPSULATION_POLICY.md`
- `handbook/architecture/PATTERN_MATCHING_POLICY.md`
- `handbook/architecture/CONCURRENCY_AND_PERFORMANCE_POLICY.md`

---

## Resumo em 1 frase

> **Design System expõe semantics universalmente; specs `.md` per-feature declaram a matriz de estados; um agente MCP (futuro) lê os dois e valida o app sem código de teste imperativo em Dart.**
