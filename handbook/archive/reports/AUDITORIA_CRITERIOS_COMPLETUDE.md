# ✅ Diretriz de Verificação — Sistema de Informação ACDG
**Associação Brasileira de Profissionais Atuantes em Doenças Genéticas, Pacientes, Familiares e Voluntários**
**Projeto:** Atendimento e Estruturação de Fluxo para Pessoas com Doenças Raras e Neurodivergências
**Local:** Boa Vista – Roraima

---

## Como usar este documento

Para cada item abaixo, marque com:
- `[x]` — **Atende** completamente
- `[~]` — **Atende parcialmente** (descreva o que falta)
- `[ ]` — **Não atende** (registre observações)

---

## 1. Prontuário Eletrônico

- [x] O sistema possui módulo de prontuário eletrônico por paciente
- [x] O prontuário é vinculado a um identificador único do paciente
- [x] Permite visualização do histórico completo de atendimentos
- [x] Suporta múltiplos profissionais acessando o mesmo prontuário

**Observações:**
> O sistema utiliza `patientId` (UUID) como identificador único. A especificação OpenAPI (`openapi.yaml`) define endpoints para listar pacientes, obter detalhes (`getPatientById`) e trilha de auditoria (`getAuditTrail`). A interface `SocialCareHomePage` possui um `DetailPanel` para visualização de dados e fichas do paciente. O backend exige `X-Actor-Id`, permitindo rastreabilidade por profissional.

---

## 2. Ficha de Cadastro (Social e Econômico do Paciente)

- [x] Nome completo
- [x] Data de nascimento
- [x] CPF / RG
- [x] Endereço completo
- [x] Telefone de contato
- [x] Responsável legal (quando aplicável)
- [x] Diagnóstico (se houver)
- [~] Unidade de saúde de referência
- [x] Benefícios sociais recebidos
- [x] Data do cadastro
- [x] Responsável pelo preenchimento

**Observações:**
> O formulário `PatientRegistrationPage` coleta dados pessoais, documentos (CPF, RG, NIS, CNS), endereço e diagnósticos iniciais. Benefícios sociais são mapeados em `RegisterIntakeInfoRequest` (`linkedSocialPrograms`). A unidade de saúde de referência não possui um campo explícito no cadastro inicial, mas `originName` na triagem (`intake-info`) pode ser usado para este fim. A data de cadastro e responsável são gerados automaticamente nos metadados da API.

---

## 3. Acompanhamento e Evolução do Paciente

- [x] Registro de atendimentos por especialistas com campo de evolução
- [ ] Campo para indicação de **alta clínica**
- [x] Campo para **encaminhamento a outro serviço** (com justificativa — paciente fora do público-alvo)
- [ ] Registro de **exames solicitados** (diagnóstico e rotina)
- [ ] Registro de **exames complementares**
- [ ] Indicação se a consulta foi presencial ou por **telemedicina**
- [ ] Campo para agendamento de **retorno**
- [x] Assinatura/registro do profissional responsável

**Observações:**
> O endpoint `registerAppointment` permite registrar `summary` (evolução) e `actionPlan`. Existe suporte formal para encaminhamentos via `createReferral`. No entanto, não foram encontrados campos para alta clínica, exames (solicitados ou complementares), modalidade de atendimento (telemedicina) ou data de retorno no schema `RegisterAppointmentRequest`.

---

## 4. Agendamento de Consultas via Aplicativo ("Atendimento na Mão")

- [~] Existe módulo ou integração com aplicativo móvel para agendamento
- [~] O paciente consegue agendar via celular (Android e/ou iOS)
- [ ] Confirmação de agendamento é enviada ao paciente (notificação, SMS ou e-mail)
- [x] O profissional consegue visualizar a agenda pelo app ou sistema

**Observações:**
> O sistema é desenvolvido em Flutter (`acdg_system`), sendo naturalmente responsivo e multiplataforma (Android/iOS). O registro de consultas (`registerAppointment`) existe, mas funciona mais como um registro de evento realizado do que um agendamento futuro com calendário e gestão de horários. Não foram encontradas funcionalidades de notificação automática ao paciente.

---

## 5. Segunda Opinião com Médico Especialista

- [ ] O sistema suporta solicitação formal de segunda opinião
- [ ] É possível vincular especialistas externos (ex: cardiologista, ortopedista, neurologista)
- [ ] O resultado da segunda opinião é registrado no prontuário do paciente
- [ ] Controle de prazo para resposta da segunda opinião

**Observações:**
> Nenhuma referência a "Segunda Opinião" foi encontrada nos contratos de API ou no código do frontend.

---

## 6. Protocolos Clínicos e Linha de Cuidado

- [ ] Permite implementar **protocolos clínicos** já existentes no fluxo de atendimento
- [ ] Suporta criação de **linha de cuidado individualizada** por paciente
- [ ] Os protocolos são aplicáveis por tipo de condição (doença rara, neurodivergência, etc.)
- [ ] Notifica o profissional quando um protocolo deve ser seguido

**Observações:**
> Não foram encontrados módulos de protocolos clínicos ou automação de linhas de cuidado. O `actionPlan` no atendimento é um campo de texto livre.

---

## 7. Triagem Multiprofissional

- [~] Ficha de triagem com campo para queixa principal
- [x] Campo de diagnóstico (confirmado ou suspeito)
- [ ] Indicação de especialidades necessárias
- [ ] Classificação de prioridade: baixo / médio / alto
- [x] Registro de encaminhamentos realizados
- [x] Identificação do profissional responsável pela triagem
- [x] Data da triagem

**Observações:**
> O módulo de "Ingresso" (`intake-info`) coleta o motivo do atendimento (`serviceReason`) e o tipo de ingresso. Diagnósticos iniciais são coletados no cadastro. Falta uma classificação formal de prioridade (Risco/Urgência) e a indicação explícita de especialidades na triagem.

---

## 8. Solicitação e Emissão de Laudos e Relatórios

- [ ] Módulo para solicitação formal de laudo/relatório
- [ ] Registro da finalidade do documento
- [ ] Identificação dos profissionais envolvidos
- [ ] Possibilidade de anexar documentos clínicos
- [ ] Controle de prazo para emissão
- [ ] Registro da entrega ao usuário/responsável

**Observações:**
> Não foi encontrado módulo específico para gestão de laudos e relatórios oficiais.

---

## 10. Monitoramento Mensal e Geração de Indicadores

- [~] Relatório mensal com número de pacientes atendidos
- [~] Relatório com número de atendimentos realizados
- [ ] Relatório com quantidade de laudos emitidos
- [x] Relatório com encaminhamentos realizados
- [~] Relatório com perfil dos usuários atendidos
- [ ] Especialidades mais demandadas no período
- [ ] Exportação de relatórios (PDF, Excel ou similar)
- [~] Painel de indicadores (dashboard) acessível para gestores

**Observações:**
> Existem definições avançadas de indicadores em `contracts/shared/validation-rules/analytics.yaml` (densidade habitacional, indicadores financeiros, perfil etário e vulnerabilidades educacionais). No entanto, a visualização consolidada em dashboards ou a exportação de relatórios mensais formatados ainda não foi identificada na interface do usuário.

---

## 11. Requisitos Gerais do Sistema

- [x] Controle de acesso por perfil de usuário (recepção, profissional, gestor)
- [x] Registro de log de alterações (auditoria)
- [~] Backup automático dos dados
- [~] Conformidade com a LGPD (Lei Geral de Proteção de Dados)
- [x] Interface responsiva (funciona em celular e tablet)
- [x] Suporte a múltiplos locais/unidades de atendimento

**Observações:**
> O sistema utiliza autenticação JWT e possui trilha de auditoria (`audit-trail`). A interface em Flutter é responsiva. A conformidade com a LGPD é endereçada pela identificação de atores e trilha de auditoria, mas requer revisão de políticas de consentimento explícito. O backup automático depende da infraestrutura de backend.

---

## Resumo da Avaliação

| Módulo | Status | Pendências |
|---|---|---|
| 1. Prontuário Eletrônico | [x] | - |
| 2. Ficha de Cadastro | [x] | Unidade de saúde de referência |
| 3. Acompanhamento/Evolução | [~] | Alta, Exames, Telemedicina, Retorno |
| 4. Agendamento via App | [~] | Agendamento futuro (calendário), Notificações |
| 5. Segunda Opinião | [ ] | Todo o módulo |
| 6. Protocolos Clínicos | [ ] | Todo o módulo |
| 7. Triagem Multiprofissional | [~] | Classificação de prioridade e especialidades |
| 8. Laudos e Relatórios | [ ] | Todo o módulo |
| 9. Mutirões/Ações Coletivas | [ ] | Todo o módulo |
| 10. Monitoramento/Indicadores | [~] | Dashboards e exportação |
| 11. Requisitos Gerais | [~] | Backup, LGPD (políticas) |

---

## Conclusão

**Data da avaliação:** 01/04/2026
**Responsável pela avaliação:** Gemini CLI
**Versão do sistema avaliado:** 1.0.0-draft

**Resultado geral:**
- [~] **Sistema atende parcialmente** — O núcleo de prontuário e cadastro social está bem estruturado, mas faltam módulos críticos de apoio à decisão (protocolos), gestão documental (laudos), ações de campo (mutirões) e ferramentas gerenciais (dashboards).

**Próximos passos:**
1. Priorizar a implementação da classificação de prioridade na triagem.
2. Estruturar o módulo de Segunda Opinião conforme solicitado.
3. Desenvolver a exportação de indicadores já mapeados no `analytics.yaml`.
4. Adicionar campos de Alta e Retorno no fluxo de atendimento.

---

*Documento gerado com base no PDF "Sistema de Informações Próprio ACDG" — Projeto de Atendimento para Doenças Raras e Neurodivergências, Boa Vista/RR.*
