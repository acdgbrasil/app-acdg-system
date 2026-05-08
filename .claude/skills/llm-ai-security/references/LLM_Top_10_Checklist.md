# OWASP LLM Top 10 — Checklist Operacional (2025)

Lista verificável para revisão de qualquer aplicação que usa LLM.

## LLM01 — Prompt Injection
- [ ] Instruções de sistema em mensagem `system`, sempre.
- [ ] Conteúdo do usuário e documentos do RAG em mensagens `user`, com delimitadores explícitos (`<docs>`, `<user_query>`).
- [ ] System prompt não contém dados de outro usuário (multi-tenant).
- [ ] Conteúdo recuperado de fontes externas (web, email, PDF, RAG) é tratado como **untrusted**.
- [ ] Pré-processamento normaliza/extrai texto de fontes externas (não passa HTML/PDF cru).
- [ ] Tools que o agente chama têm escopo restrito por usuário.
- [ ] Output de tool é validado antes de voltar ao loop do agente.

## LLM02 — Insecure Output Handling
- [ ] Output do LLM nunca vai direto para `innerHTML`/`dangerouslySetInnerHTML` sem sanitização.
- [ ] Output que vira argumento de tool passa por validação Zod/JSON Schema.
- [ ] Output que vira SQL passa por query builder seguro, nunca `db.execute(string)`.
- [ ] Output que vira shell command passa por allowlist + `execFile`/`spawn` com array de args.
- [ ] Renderização markdown sanitiza HTML embutido (DOMPurify ou marked com `breaks: false, sanitize: true`).

## LLM03 — Training Data Poisoning
- [ ] Datasets de fine-tune têm origem documentada.
- [ ] Hash dos datasets registrado e checado a cada build.
- [ ] Pipeline de coleta sob code review.
- [ ] Sem fine-tune com dados de produção sem anonimização.

## LLM04 — Model Denial of Service
- [ ] `max_tokens` (input e output) configurado por endpoint.
- [ ] Rate limit por usuário (req/min e tokens/min).
- [ ] Timeout por chamada (ex.: 30s).
- [ ] Budget alert por usuário/dia/total.
- [ ] Agentes têm `max_iterations` e watchdog para loops.

## LLM05 — Supply Chain
- [ ] Modelos open-source pinados por hash (não tag).
- [ ] Plugins/MCP servers de terceiros auditados ou em sandbox.
- [ ] SBOM inclui modelos e versões.
- [ ] Assinatura/checksums verificados quando disponíveis.

## LLM06 — Sensitive Information Disclosure
- [ ] System prompt não contém PII em sistemas multi-tenant.
- [ ] Embeddings sobre dados anonimizados quando viável.
- [ ] Vector store isolado por tenant (filtro obrigatório).
- [ ] Logs de prompts passam por redaction (regex de email/CPF/cartão).
- [ ] Cache de respostas isolado por sessão/usuário.
- [ ] Memória de conversa expira ou tem retenção definida.

## LLM07 — Insecure Plugin/Tool Design
- [ ] Cada tool tem escopo específico (não tools genéricas).
- [ ] Cada argumento valida-se com schema rigoroso (sem `additionalProperties: true`).
- [ ] Tool checa autorização do usuário, não confia em ID passado pelo modelo.
- [ ] Tool retorna o mínimo necessário (sem campos internos).

## LLM08 — Excessive Agency
- [ ] Ações irreversíveis (delete, transfer, send, deploy) requerem confirmação humana.
- [ ] Agente opera com escopo limitado por sessão (não com superuser).
- [ ] Toda tool call é auditada (userId, sessionId, args, resultado).
- [ ] Limite de "espaço de ação" — número de tool calls por sessão.

## LLM09 — Overreliance
- [ ] UI deixa claro que conteúdo é gerado por IA.
- [ ] Decisões de impacto (médico, jurídico, financeiro) têm validação humana.
- [ ] Métricas: taxa de "minha IA inventou" detectada por feedback / correção.
- [ ] Disclaimer onde aplicável.

## LLM10 — Model Theft
- [ ] Rate limit em endpoints de inferência.
- [ ] Watermarking nas respostas quando viável.
- [ ] Monitoramento de padrões de extração (queries similares para mapear espaço latente).

## Auditoria Periódica
- [ ] Revisão trimestral do pipeline completo.
- [ ] Re-execução de testes de prompt injection (`security-test-generator`) a cada deploy de mudança no system prompt.
- [ ] Reavaliação de bases legais com DPO a cada novo dado adicionado ao pipeline.

## Referências
- OWASP Top 10 for LLM Applications — https://genai.owasp.org/llm-top-10/
- OWASP AI Exchange — https://owaspai.org/
