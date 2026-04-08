# Guia de Implementação do Pacote Social Care

Este documento serve como índice mestre para as diretrizes de desenvolvimento, arquitetura e refatoração do pacote `@packages/social_care`. Todos os agentes de inteligência artificial e desenvolvedores humanos devem basear-se nestes documentos antes de propor alterações.

Foram gerados os seguintes guias detalhados refletindo fielmente a estrutura atual do projeto:

1. **[Visão Geral da Arquitetura](01_social_care_architecture_overview.md):** MVVM + Clean Architecture Funcional, explicando os fluxos Downstream e Upstream.
2. **[Camada de Dados (Data Layer)](02_social_care_data_layer.md):** Intents (Commands), Models (DTOs), Repositories e Services. Inclui regras estritas de não conter lógica de negócios nos DTOs e mapeamento global de falhas no Dio.
3. **[Camada Lógica e de Domínio (Logic Layer)](03_social_care_logic_layer.md):** Regras de Mappers, UseCases, validação via `zard` (Schemas) e padronização do `SocialCareError`.
4. **[Camada de UI e Apresentação (UI Layer)](04_social_care_ui_layer.md):** MVVM sem exceções. Separação de ViewModels, FormStates, Componentização Atômica (Dumb UI) e uso extensivo de `ValueNotifier`/`ListenableBuilder` para micro-renderizações.
5. **[Regras Estritas para IAs (AI Coding Rules)](05_social_care_ai_coding_rules.md):** Mandatos absolutos como a proibição do uso de `.valueOrNull!`, exigência de *Pattern Matching* com `switch (result)`, isolamento de tratamentos `try/catch` apenas em serviços periféricos, e internacionalização estrita (`constants/*_ln10.dart`).

> **Nota:** Estes documentos devem ser lidos integralmente por qualquer agente ou implementador envolvido em atividades neste pacote para garantir total conformidade com o *Gold Standard* do ecossistema ACDG.