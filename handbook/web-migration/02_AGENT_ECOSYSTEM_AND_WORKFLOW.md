# O Ecossistema de Agentes e Workflow (Web React Funcional)

Para acelerar a migração para a web utilizando a Stack Deno + React + Vite, com foco em Programação Funcional e Clean Architecture Estrita, implementaremos um modelo de **Múltiplos Agentes Especializados (Skills)**. 

A ideia é que você (o Humano) atue apenas como **Arquiteto Diretor**, delegando tarefas para IAs que possuem papéis e restrições absolutas sobre como escrever o código.

## 🤖 Os Papéis (Skills a serem criadas via Gemini CLI)

### 1. `tdd-architect-web` (Arquiteto Funcional e Testes)
- **Sua Função:** É a IA inicial com a qual você conversa. Você dita a especificação (ex: "Fluxo de Listar Pacientes").
- **O que a IA faz:** 
  1. Cria os arquivos de domínio (tipos imutáveis e `Result`).
  2. Cria a assinatura dos **Commands** funcionais (ex: `listPatientsCommand(repo)`).
  3. Escreve os arquivos de teste falhos (`list_patients_command_test.ts`, `use_list_patients_controller_test.ts`).
  4. Define os schemas de `zod` como contratos invioláveis.
- **Regra de Ouro:** NUNCA escreve o corpo da função (implementação). Apenas o contrato (Tipos de Entrada/Saída) e a asserção (Teste). Usa sempre `Result` nativo de TS.

### 2. `react-implementer` (O Construtor Funcional)
- **Sua Função:** Pegar os testes escritos pelo `tdd-architect-web` e fazê-los passar.
- **O que a IA faz:** 
  1. Roda `deno test`.
  2. Implementa a lógica do **Command**, extraindo do repositório, mapeando os erros.
  3. Implementa o Hook (`Controller`) que despacha o Command e expõe o estado.
  4. Constrói o componente Visual (`View`) puro e "burro".
- **Regra de Ouro:** Não adiciona lógicas ao seu gosto. Se a assinatura do Command pede `Promise<Result<T, DomainError>>`, ele deve retornar exatamente isso e prever a exaustão de erros com o discriminador `ok: true | false`. Nada de `try/catch` que escape para a UI.

### 3. `web-code-reviewer` (O Sentinela de Segurança)
- **Sua Função:** Auditor implacável antes do Commit.
- **O que a IA faz:** 
  1. Analisa as alterações usando as regras do `01_ARCHITECTURE_AND_RULES.md`.
  2. **Checklist de Reprovação:**
     - Tem a palavra `class` usada fora de infraestrutura externa? (Reprova).
     - Tem `any` ou `as Tipo` sem usar validação do Zod? (Reprova).
     - A View (`.tsx`) faz `fetch` ou chama APIs indiretamente sem passar por um Command? (Reprova).
     - Componentes React estão decidindo fluxo de negócio ou fazendo mutação local que não é refletida no Command? (Reprova).
  3. Se achar erros, cria o documento `CLAUDE_CODE_REVIEW.md` exigindo correção da IA implementadora ou do humano.

---

## 🔄 O Workflow Proposto (O seu dia a dia)

Sempre que criarmos uma funcionalidade:

**Passo 1: O Comando Inicial (Arquiteto)**
> "Arquiteto, preciso do Command para inativar paciente. Leia a documentação do BFF sobre a rota. Crie a entidade e o teste do Command. Lembre de injetar o Repositório no teste via Fake (simples, sem mocks mágicos)."

**Passo 2: A Implementação (Pedreiro/Implementador)**
> "Implementador, faça o teste do Command de Inativação passar. Use a API de fetch encapsulada e devolva o Result usando o erro `PatientNotActiveError` no mapeamento do Zod se der problema."

**Passo 3: A Validação Final (Revisor)**
> "Revisor, audite o Command e a View recém-criados. Verifique explicitamente se não há Duck Typing, se a injeção funcional foi respeitada e se nenhum dado sensível vaza no erro."

---

## 🚀 Como Estruturar as Skills (Deno/CLI)

1. Para cada papel acima, criaremos um arquivo `SKILL.md` (via comando `/skill-creator` se preferir) usando a raiz deste handbook como prompt matriz (System Prompt).
2. Cada Skill exigirá a leitura dos guias do `handbook/web-migration/` em sua execução para evitar alucinações ("Ah, eu achei que podia usar class e axios aqui").
3. Essa será a principal defesa contra ferramentas como Cursor/Claude tentarem trazer o padrão deles de Next.js/MVVM verboso para dentro da nossa SPA funcional, garantindo previsibilidade e segurança extremas.