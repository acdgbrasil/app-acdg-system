# Auditoria Arquitetural Detalhada — Design System e UI Burra
**Data:** 02 de Abril de 2026
**Especialista:** flutter-arch-review (Gemini CLI)

Esta auditoria foca na sua suspeita (extremamente válida) sobre o `package:design_system`. Você sugeriu deletar o pacote inteiro e deixar cada app/módulo ter o seu próprio Design System.

## 1. O Veredito sobre "Deletar o Design System"

**Vou ser muito direto: DELETAR O DESIGN SYSTEM É UMA PÉSSIMA IDEIA.** 
Se você fizer isso, estará trocando um problema grave por um problema catastrófico.

**Por que não deletar?**
O ecossistema ACDG é um monorepo. Se cada módulo (`social_care`, `auth`, `admin`) tiver seu próprio Design System, em 3 meses:
- Alterar a cor primária (o "Verde ACDG") vai exigir PRs em 5 pacotes diferentes.
- Botões terão paddings diferentes dependendo da tela.
- O peso do app vai inchar porque a engine do Flutter vai carregar múltiplas implementações de `TextField` e Fontes.
- A "identidade visual" (a marca) do projeto vai se estilhaçar.

No entanto, **a sua intuição de que o Design System atual está errado está 100% correta.** 

O problema não é *existir* um Design System. O problema é que **o Design System atual foi poluído com Lógica de Negócio e Componentes de Domínio.**

---

## 2. A Auditoria: Os "Crimes" do Design System Atual

Um Design System de verdade deve ser **completamente agnóstico**. Ele não sabe o que é um "Paciente", um "Membro da Família" ou um "Cadastro". Ele só sabe desenhar Cores, Botões, Tipografia e Inputs.

Aqui estão os vazamentos grotescos que encontrei dentro de `packages/design_system/lib/src/`:

### 2.1 Componentes Estritamente de Domínio (Organisms)
**Arquivos afetados:**
- `acdg_member_list.dart`
- `acdg_member_card.dart`
- `acdg_member_table_header.dart`
- `acdg_registration_header.dart`
- `acdg_documents_checkbox_row.dart`

**🚫 Anti-padrão:**
O Design System está construindo tabelas de "Composição Familiar" e renderizando strings hardcoded como `'Nome'`, `'Idade'`, `'Sexo'`, `'PCD'`. Isso é um vazamento gravíssimo do domínio de `social_care` para dentro do pacote de UI. 
- O Design System não deve ter um `AcdgMemberCard`. Ele deve ter um `AcdgCard` genérico que aceita um `title` e um `subtitle`. Quem cria o layout do "Membro" é a feature de `social_care`.

### 2.2 O Padrão Correto a Ser Feito: "Purga do Design System"

Em vez de deletar o pacote, nós precisamos **limpar a sujeira** que colocaram nele. O Design System deve conter **APENAS**:

1. **Tokens (A fundação sagrada):**
   - `app_colors.dart`
   - `app_typography.dart`
   - `app_shadows.dart`
   - `app_spacing.dart`
   - `app_breakpoints.dart`
   *(Esses arquivos estão corretos e são o motivo principal de mantermos o pacote)*

2. **Atoms (Elementos primitivos e burros):**
   - `AcdgText` (Correto)
   - `AcdgPillButton` (Correto)
   - `AcdgDropdown` (Correto)
   - `AcdgCheckbox` / `AcdgRadioButton` (Correto)

3. **Molecules (Combinações genéricas):**
   - `AcdgFormField` (Label + Input + Error) -> Correto, desde que não tenha máscaras de "CPF" chumbadas nele.

---

## 3. O Dilema: Onde Coloco Meus Componentes Então? (A Regra de Ouro)

Para não poluir o Design System com o domínio da clínica, mas também não criar "Páginas Gigantes" (Fat Pages) de 500 linhas na sua feature, o **Atomic Design** divide a interface em dois mundos: **Os Tijolos** e **A Casa**.

### 3.1. O Mundo do `design_system` (Os Tijolos LEGO)
O pacote `design_system` fornece os blocos de construção universais. Eles são "burros", não sabem nada sobre o seu aplicativo de saúde e recebem dados apenas via parâmetros (`props`).

### 3.2. O Mundo da Sua Feature (A Casa Montada)
Dentro do pacote da sua funcionalidade (ex: `packages/social_care/lib/src/ui/patient_registration/view/components/`), você cria os seus próprios **Organisms** e **Templates**.

Esses são componentes riquíssimos, que montam pedaços inteiros de tela usando os "tijolos" do Design System, mas que **sabem do contexto do negócio**. Eles vivem **exclusivamente** dentro da feature que os utiliza.

**Exemplos do que deve morar na pasta `components/` local:**
- `FamilyTable` (Uma tabela que importa o `AcdgText` do Design System, mas preenche os textos iterando o modelo `FamilyMemberModel`).
- `DiagnosisCard` (Um card que junta 3 `AcdgFormField` para o usuário digitar a CID, Data e Descrição do diagnóstico).
- `AddMemberModal` (O modal de negócio para adicionar um membro familiar).

### 3.3. O Teste do "Delivery de Comida"
Para saber onde um componente deve morar, faça a si mesmo a seguinte pergunta:
> *"Se eu criar amanhã um aplicativo de 'Delivery de Pizzas' neste mesmo Monorepo ACDG, eu conseguiria usar esse componente lá sem alterar nenhuma linha de código?"*

- **SIM:** Então ele é um componente visual genérico e pertence ao `package:design_system`.
- **NÃO:** Ele contém palavras de domínio (ex: "Paciente", "Parentesco", "Cadastro") ou lógica atrelada a uma feature específica? Então ele pertence **exclusivamente à pasta `components/`** do seu pacote (ex: `package:social_care`).

Seguir essa divisão é o que manterá o seu código limpo, seus arquivos com menos de 100 linhas, e o Design System infinitamente reutilizável.

---

## 4. Plano de Ação Final (Refatoração do Design System)

Para alinhar o projeto ao Gold Standard da ACDG e resolver a frustração:

1. **Remova a pasta `organisms` do Design System:**
   Mova os arquivos `acdg_member_table_header.dart`, `acdg_member_list.dart`, `acdg_member_card.dart` e `acdg_registration_header.dart` DE VOLTA para `packages/social_care/lib/src/ui/`. Eles pertencem ao módulo de pacientes.
2. **Remova a "Document Row":**
   Mova o `acdg_documents_checkbox_row.dart` para o pacote de `social_care`, pois "Documentos Civis" (RG, CPF, NIS) são regras do negócio da ACDG.
3. **Crie "Dumb Components" no lugar:**
   Se a tela precisa de uma tabela, crie um `AcdgDataTable` no Design System que aceite colunas como um `List<String>`. Quem passará os textos `'Nome'`, `'Idade'` será a tela do Flutter.
4. **Aplique o L10n no lugar das Strings Chumbadas:**
   Como apontado na auditoria anterior, as telas em `social_care` devem usar as classes de constantes de LN10 (ou `AppLocalizations`), enviando o texto traduzido como parâmetro para os Widgets do Design System.

---
**Conclusão:**
A sua percepção estava perfeita: o pacote violou o limite do escopo visual e abraçou o escopo de negócio. **Mas a solução não é deletá-lo.** A solução é fazer a "Purga dos Organisms", extraindo a lógica de saúde social dali e garantindo que o `design_system` contenha apenas a fundação visual (Tijolos) da ACDG. Isso garante escalabilidade e consistência impecável ao longo dos anos.