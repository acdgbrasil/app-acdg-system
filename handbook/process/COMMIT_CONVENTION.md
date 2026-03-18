# Commit Convention — Padrão ACDG

Seguimos o padrão **Conventional Commits** com a adição de **emojis** para facilitar a leitura visual do histórico do Git.

## Formato
`<emoji> <tipo>(<escopo>): <descrição curta>`

Exemplo: `✨ feat(auth): add login command logic`

---

## Tabela de Emojis e Tipos

| Emoji | Tipo | Descrição |
| :--- | :--- | :--- |
| ✨ | **feat** | Nova funcionalidade. |
| 🐛 | **fix** | Correção de bug. |
| 🏗️ | **refactor** | Refatoração de código que não altera comportamento. |
| 📚 | **docs** | Alterações na documentação. |
| 🧪 | **test** | Adição ou correção de testes. |
| 🛠️ | **chore** | Manutenção, atualização de dependências, builds. |
| ⚡ | **perf** | Melhoria de performance. |
| 🎨 | **style** | Mudanças de formatação ou estilo (sem alterar lógica). |
| 🧠 | **logic** | Mudanças específicas na camada de lógica (UseCases). |
| ⚛️ | **ui** | Mudanças específicas na camada de UI (Atomic Design). |
| 🌍 | **env** | Mudanças em variáveis de ambiente ou configurações de infra. |

---

## Regras de Ouro
1. **Frequência:** Commits pequenos e frequentes são melhores que um "mega commit" no fim do dia.
2. **Atomicidade:** Cada commit deve ter uma única responsabilidade lógica.
3. **Mensagem:** Use o imperativo ("add feature" em vez de "added feature").
4. **Escopo:** Sempre que possível, especifique o package ou módulo afetado entre parênteses.
