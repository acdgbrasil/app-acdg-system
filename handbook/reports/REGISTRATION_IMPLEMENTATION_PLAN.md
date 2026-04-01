# Plano de Implementação — Cadastro de Pacientes (Wizard 3 Etapas)

## Visão Geral
Implementação do fluxo de cadastro (Pessoa de Referência, Composição Familiar e Especificidades) seguindo o **Atomic Design** e o padrão **Apple HIG Adaptive Layout** (3 breakpoints).

---

## Status do Progresso

### Fase 0: Infraestrutura e Assets
- [x] Criar estrutura do pacote `design_system`
- [x] Download e configuração das fontes (Satoshi, Erode, Inter)
- [x] Criação do arquivo de constantes de strings (`social_care/lib/src/constants/registration_strings.dart`) com correções ortográficas

### Fase 1: Design Tokens (`design_system/lib/src/tokens/`)
- [x] `AppColors`: Paleta de cores (Off-White, Dark Brown, Deep Blue, etc.)
- [x] `AppSpacing`: Escala baseada em múltiplos de 8px
- [x] `AppBreakpoints`: Definição de Mobile (<600), Tablet (600-1199) e Desktop (>=1200)
- [x] `AppTypography`: Escala responsiva em 3 níveis (Satoshi/Erode/Inter)
- [x] `AppShadows`: Tokens de sombra (xs, buttonGlow, etc.)
- [x] `AppTheme`: Configuração do `ThemeData` com estilos de input underline e checkbox/radio

### Fase 2: Átomos (Widgets Base)
- [x] `AcdgText`: Widget de texto adaptável
- [x] `AcdgPillButton`: Botão arredondado (alturas 72/56/48px)
- [x] `AcdgUnderlineInput`: Campo de texto minimalista
- [x] `AcdgCheckbox`: Componente de seleção customizado
- [x] `AcdgRadioButton`: Componente quadrado arredondado (não circular)
- [x] `AcdgIconButton`: Wrapper para Material Icons

### Fase 3: Moléculas e Organismos
- [x] `AcdgFormField`: Molécula base com 5 variantes
- [x] `AcdgRegistrationHeader`: Hambúrguer + Breadcrumb adaptável
- [x] `AcdgActionRow`: Conjunto de botões de rodapé (3 breakpoints)
- [ ] `AcdgMemberTableRow`: Linha de tabela (Desktop)
- [ ] `AcdgMemberCard`: Card de membro (Tablet/Mobile) com fundo alternado
- [ ] `AcdgMemberTableHeader`: Cabeçalho da tabela (Desktop)
- [ ] `AcdgMemberList`: Organismo orquestrador da lista adaptável

### Fase 4: Lógica de Fluxo (`social_care`)
- [x] `RegistrationViewModel`: Gerenciamento de estado das 3 etapas (Provider)
- [ ] Configuração de rotas no `GoRouter` (/registration/step1, step2, step3)
- [x] `MemberModal`: Popup de Adicionar/Editar membros (Deep Blue theme)

### Fase 5: Telas Finais (Páginas)
- [ ] `ReferencePersonPage`: Etapa 1 (Grid 12 -> 4 colunas)
- [ ] `FamilyCompositionPage`: Etapa 2 (Tabela -> Cards)
- [ ] `SpecificitiesPage`: Etapa 3 (2 colunas -> 1 coluna)

---

## Diretrizes Técnicas
1. **Unidade Base**: 8px (múltiplos obrigatórios).
2. **Responsividade**: O layout muda de estrutura (ex: Tabela -> Cards) no breakpoint de 1200px.
3. **Tipografia Dual**: Satoshi (Informação) e Erode (Interação).
4. **Cores**: Inversão de tema no Modal (Deep Blue).
5. **Correções**: "Especeficidades" -> "Especificidades", etc.
