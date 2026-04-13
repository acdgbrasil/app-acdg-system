# Manual de Domínio e Arquitetura Web (Agnóstico à Tecnologia)

Este documento atua como a **Única Fonte de Verdade (Single Source of Truth)** para a migração ou reescrita da aplicação ACDG para o ambiente Web. Ele foi estruturado de forma estritamente **agnóstica à tecnologia**, focando exclusivamente nos padrões de arquitetura, decisões de domínio e regras de segurança. Seu propósito é servir como o "DNA" do projeto, de forma que o sistema possa ser recriado em qualquer framework ou linguagem suportado pela web.

> **Nota Crítica:** Por focar em arquiteturas web modernas e conectadas à nuvem, o paradigma de "Offline-First" foi removido deste manual. A aplicação web atua em modo *Always-Online*.

---

## 1. O Domínio de Negócio (ACDG)

A ACDG é uma plataforma de gestão social e clínica para pacientes com doenças genéticas raras e neurodivergências. O domínio é altamente estruturado e se divide nos seguintes **Contextos Delimitados (Bounded Contexts)**:

### 1.1. Registry (Cadastro Unificado)
- **Escopo:** Paciente Principal (Pessoa de Referência), Composição Familiar, Cuidador Principal e Identidade Social.
- **Decisão Crítica (Identidade Desacoplada):** O sistema não cria as identidades das pessoas. A aplicação Web deve, primeiramente, consultar/registrar dados em um microsserviço externo de identidades (`people-context`) para obter um Identificador Global Único (`personId`). Este identificador é o núcleo de toda a composição da família e do paciente.

### 1.2. Assessment (Avaliações Modulares)
- **Escopo:** Módulos independentes cobrindo: Condição Habitacional, Situação Socioeconômica, Educação, Trabalho e Renda, Status de Saúde e Rede de Apoio.
- **Decisão Crítica:** Cada módulo funciona como uma mutação do estado do Paciente. Não se envia o cadastro inteiro de uma vez, mas sim fragmentos semânticos do paciente de acordo com a área sendo avaliada.

### 1.3. Care & Protection (Cuidado e Proteção)
- **Escopo:** Histórico de Consultas, Triagem (Ingresso), Histórico de Acolhimento, Relatos de Violência/Violação e Encaminhamentos Institucionais.
- **Decisão Crítica:** Entidades destas áreas possuem rigorosos ciclos de vida e máquinas de estado (ex: um encaminhamento passa de PENDENTE para CONCLUÍDO ou CANCELADO, nunca podendo retroceder).

### 1.4. Lookup (Tabelas de Domínio e Dicionários)
- **Escopo:** Alimentação de todos os formulários e listas de opções (Tipos de Parentesco, Níveis de Escolaridade, etc.).
- **Decisão Crítica:** O Frontend não pode possuir valores de negócio "chumbados" (hardcoded). Todos os domínios de seleção são dinâmicos e dependem de tabelas de Lookup fornecidas pelo servidor. Isso permite à administração do sistema adicionar novas opções sem necessidade de relançar o aplicativo web.

---

## 2. Princípios de Arquitetura de Software (Clean Architecture Funcional)

A arquitetura Web adotada prioriza a **Separação Rígida de Camadas** e o **Fluxo Unidirecional de Dados**. Cada camada desconhece a camada imediatamente superior a ela.

### 2.1. Camada de Domínio (O Núcleo)
- **Modelos Puros e Imutáveis:** Os dados de domínio não sofrem mutação no mesmo objeto (sem setters). Atualizações devem sempre gerar cópias enriquecidas dos objetos.
- **Erros como Valores (Result Pattern):** É estritamente proibido utilizar `try/catch` para conduzir fluxos de negócio na aplicação. Toda operação que possa falhar deve retornar um tipo unificado que deixe explícito se ocorreu um `Sucesso` ou uma `Falha`, forçando a verificação exaustiva antes da utilização dos dados.

### 2.2. Camada de Aplicação (Commands / Orquestradores)
- **Commands vs. Intents:**
  - **Intent (DTO de Interface):** O pacote de dados puramente capturado da UI.
  - **Command:** A função ou estrutura que encapsula uma Ação de Negócio, coordenando requisições, invocando a camada de dados e gerenciando os estados da tarefa (`Idle`, `Loading`, `Success`, `Error`).
- A Interface Gráfica não chama requisições de rede diretamente; ela despacha *Intents* para os *Commands*.

### 2.3. Camada de Dados e Camada Anti-Corrupção (ACL)
- **Sem Duck-Typing (Tipagem Cega):** Não confie nos dados que vêm do exterior (APIs e BFFs).
- **Validação em Tempo de Execução:** Todo dado ingerido da rede deve obrigatoriamente passar por um validador de Esquema (Schema Validator). Respostas malformadas ou campos ausentes são capturados aqui e barrados de entrar no Domínio.
- **Tradução:** Modelos de resposta de APIs são meros DTOs. Esta camada converte a resposta da rede em Entidades Ricas do nosso Domínio.

### 2.4. Camada de Apresentação (Dumb UI & Atomic Design)
- **Atomicidade Visual:** Os componentes gráficos são organizados hierarquicamente (Átomos, Moléculas, Organismos e Páginas). O "Átomo" de um Botão não tem ideia de que está salvando um Paciente; ele só sabe desenhar, receber cliques e avisar a camada superior.
- **Zero Lógica de Negócio na View:** Um componente visual não decide fluxos baseado em erros HTTP ou regras matemáticas. Se há necessidade de validar uma formatação complexa, esta validação ocorre na Camada de Aplicação/Domínio, que devolverá uma representação visual de "Estado Inválido".

---

## 3. Regras de Negócio, Formatação e Invariantes

Ao transportar este sistema para outras linguagens e tecnologias, as seguintes regras são obrigatórias na modelagem:

1. **Protocolo ISO8601:**
   - Comunicações envolvendo datas com o servidor exigem obrigatoriamente a formatação ISO8601 com carimbo de tempo completo (`YYYY-MM-DDTHH:mm:ss.SSSZ`). Qualquuer variação gerará falhas de validação estrita no servidor.

2. **Uniformidade de Strings Mágicas:**
   - Valores como Sexo ou Regiões possuem regras rígidas impostas pelo Backend e Banco de Dados (Ex: sexo deve ser `"masculino"` em minúsculo, mas zonas residenciais como `"URBANO"` exigem tudo maiúsculo). O Mapper da Camada de Aplicação deve realizar esse casting perfeitamente.

3. **Validações Condicionais Direcionadas por Metadados:**
   - Ao receber os dados da Tabela de Lookup (ex: Tipos de Benefício Social), eles carregam metadados lógicos (`exige_registro_nascimento = true`).
   - O Frontend Web DEVE ler esses metadados para ditar se novos campos no formulário passam a ser de preenchimento obrigatório e travar o comando de Envio se não forem respeitados.

4. **Validações Cruzadas de Entidades:**
   - Se a marcação indicar "Gestante" no Módulo de Saúde para a Pessoa de Referência, e o `people-context` retornar que a pessoa é do sexo Biológico compatível apenas com o perfil masculino, o cadastro deve ser bloqueado visual e funcionalmente, impedindo envio da requisição defeituosa ao backend.
   - Históricos que contenham Início e Fim (Acolhimento Institucional) precisam ter validação matemática rígida: `DataFim >= DataInicio`.

---

## 4. Regras de Segurança, Identidade e Sessão (Max Security)

A Web apresenta vetores de ataque específicos, como XSS (Injeção de Scripts) e CSRF (Falsificação de Requisição Entre Sites). Para garantir a integridade total do sistema, os seguintes padrões são INEGOCIÁVEIS:

### 4.1. Split-Token Pattern (OIDC PKCE)
- **Access Token (Token JWT de Acesso):** 
  - Regra de Ouro: O Token de Autorização **NUNCA DEVE TOCAR O DISCO RÍGIDO** do Navegador. O uso de `localStorage`, `sessionStorage` ou banco de dados do navegador (IndexedDB) para salvar este token é expressamente proibido, prevenindo o roubo por meio de ataques de XSS.
  - Ele viverá exclusivamente na memória em tempo de execução da aplicação e fluirá através dos módulos. Em caso de *reload* (F5), ele é destruído.
- **Refresh Token (Renovação Silenciosa):** 
  - Emitido pelo Provedor de Identidade, este passaporte viaja atrelado a um **Cookie de Navegador**.
  - O Cookie DEVE ter as seguintes tags ativadas em infraestrutura: `HttpOnly` (Impede o acesso do JavaScript do lado do cliente), `Secure` (Apenas trafega em túnel HTTPS criptografado) e `SameSite=Strict` (Previne ataques de CSRF isolando a requisição ao domínio original).
  - O cliente web fará requisições de re-obtenção de Access Token (Refresh) automaticamente, permitindo que o cookie seguro trabalhe como o portador da verdadeira sessão, recuperando o Access Token para a memória volátil.

### 4.2. Autorização Estrita e Auditoria Injetada (RBAC)
- As roles e permissões (Ex: `social_worker`, `owner`, `admin`) são decodificadas do interior do Access Token (JWT Claim).
- **Proteção Roteada (Guards):** O navegador NÃO DEVE processar partes estruturais de páginas cuja *Role* do usuário ativamente desautoriza visualização. O controle de acesso bloqueia antes do desenho visual.
- **Assinatura de Transações:** Cada Command que envia mutações ao backend (`POST`, `PUT`, `DELETE`) tem o dever arquitetural inadiável de empacotar o ID único de sujeito que está realizando a ação (tirado do Token da memória) enviando-o via um Header HTTP `X-Actor-Id`. Isso sustenta o rastro de auditoria legal no cluster do Backend.

### 4.3. Fail-Fast Environments e Zero Segredos
- Nenhuma Chave Privada, "Client Secret" ou String sensitiva pode estar escrita na base de código web sob nenhuma circunstância.
- O carregamento da aplicação exige a checagem imediata das Variáveis de Ambiente Injetadas pela pipeline de deploy (ex: Endpoint Base, OIDC Issuer e Client ID Público). A ausência destas travará completamente o processo de renderização e alertará com falha crítica do sistema, no padrão *Fail-Fast*.

### 4.4. Mascaramento Sistêmico de Erros (Sanitização)
- Uma falha técnica real no backend (Ex: Um erro de PostgreSQL `500 Internal Server Error`, Timeout de conexão, Deserilização errada) NÃO DEVE chegar até a Interface de Usuário.
- A Camada de Dados/Anti-Corrupção captura e silencia erros nativos e constrói um "Erro Semântico de Domínio" (Ex: "O serviço de Identidade encontra-se temporariamente instável"). Isso elimina o vazamento de topologia de infraestrutura da ACDG e minimiza sustos operacionais para os usuários da ponta.