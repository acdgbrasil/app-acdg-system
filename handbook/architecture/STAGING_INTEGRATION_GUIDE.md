# Guia de Integração com Ambiente de Homologação (Staging)

Este documento consolida as lições aprendidas durante a integração do Frontend/BFF com o backend ACDG em ambiente de Staging (HML). Siga estas diretrizes para garantir uma conexão bem-sucedida e evitar erros comuns de infraestrutura e segurança.

## 1. Autenticação via Service Account (Zitadel)

A autenticação em Staging utiliza o fluxo de **JWT Profile** com chaves RSA.

### Injeção da Chave Privada
Ao usar `--dart-define` para injetar a chave PEM, o shell frequentemente corrompe as quebras de linha (`\n`), invalidando a assinatura RSA.
*   **Solução:** Envie a chave codificada em **Base64**.
*   **Comando:** `KEY_B64=$(jq -r '.key' service_account.json | base64 | tr -d '\n')`
*   **Factory:** Use `HmlAuthHelper.fromEnv()`, que detecta e decodifica Base64 automaticamente.

### Escopos Obrigatórios (Audience)
O backend Swift/Vapor exige que o token contenha a audiência (Project ID) correta para validar o JWKS.
*   **Escopo necessário:** `urn:zitadel:iam:org:project:id:363109883022671995:aud`
*   Sem este escopo, o Zitadel gera um token válido, mas o backend retornará **401 Unauthorized**.

---

## 2. Formatação de Dados e Mapeamento

O backend é rigoroso quanto aos tipos e formatos de dados.

### Datas (ISO8601)
Todas as datas, incluindo datas de nascimento (`birthDate`) e datas de emissão de documentos, devem seguir o formato **ISO8601 completo** (`YYYY-MM-DDTHH:mm:ss.SSSZ`).
*   Use a extensão `TimeStampApiExtensions.toIso8601()` definida em `bff/shared`.
*   Formatos curtos como `YYYY-MM-DD` resultam em **400 Bad Request**.

### Enums e Localização
Existem discrepâncias entre o OpenAPI e a implementação real do domínio Swift:
*   **Sexo:** Deve ser enviado em português e minúsculo: `"masculino"` ou `"feminino"`.
*   **Local de Residência:** Deve ser enviado em UPPERCASE: `"URBANO"` ou `"RURAL"`.

### Tipos Complexos (JSONB)
Campos mapeados como `jsonb` no PostgreSQL (ex: `required_documents`) devem ser enviados como **arrays JSON reais**, não como strings serializadas.
*   Correto: `"requiredDocuments": ["CPF"]`
*   Incorreto: `"requiredDocuments": "[\"CPF\"]"`

---

## 3. Gestão de Composição Familiar (Registry)

A composição familiar segue regras rígidas de integridade referencial e lógica de negócio no Backend Swift/Vapor.

### Adição de Membros
*   **Rota:** `/api/v1/patients/{patientId}/family-members` (POST).
*   **Parâmetro `prRelationshipId`:** Mesmo sendo um comando para adicionar um *novo* membro, o backend exige o `prRelationshipId` (UUID da relação da Pessoa de Referência) no corpo do JSON para validar que o agregado continua tendo exatamente uma PR.
*   **Conflito de PR:** Se você tentar adicionar um membro usando o mesmo `relationshipId` que define a PR, o backend retornará `multiplePrimaryReferencesNotAllowed`.

### Atribuição de Cuidador Principal
*   **Rota:** `/api/v1/patients/{patientId}/primary-caregiver` (PUT).
*   **Regra:** O membro deve primeiro existir na família (ter sido adicionado via POST) antes de ser promovido a cuidador.

### Remoção de Membros
*   **Rota:** `/api/v1/patients/{patientId}/family-members/{memberPersonId}` (DELETE).
*   **Atenção:** Use o `personId` do membro na URL, não o `patientId` do prontuário nem IDs de relacionamento.

### Atualização de Identidade Social
*   **Rota:** `/api/v1/patients/{patientId}/social-identity` (PUT).
*   **Atenção:** O sufixo da rota é `/social-identity` (completo), não `/social-id`.
*   **Dados:** Requer um `typeId` válido da lookup table `dominio_tipo_identidade`.

---

## 4. Regras de Negócio e Invariantes

### Agregado Patient
O `Patient` exige a definição explícita do `prRelationshipId` no momento da criação. Este ID deve vir de uma lookup table real (`dominio_parentesco`).

### Mapeamento Reverso (API -> Domain)
Ao ler dados do backend (`GET`), use sempre o método `reconstitute` dos modelos Dart. Isso evita que validações de "novo objeto" (como obrigatoriedade de certos campos apenas no ato da criação) quebrem a exibição de dados já existentes no banco.

### Documentação Obrigatória
O backend exige ao menos um documento civil válido para o registro (`REGP-018`). Em testes, use o `generateValidCpf()` para evitar colisões no banco de dados.

---

## 5. Diagnóstico de Erros em HML

### Campo `details`
Em ambiente HML, o backend retorna um campo extra no JSON de erro chamado `details`.
```json
{
  "error": {
    "code": "REGP-024",
    "message": "Falha de infraestrutura...",
    "details": "issues: [\"Erro real do Postgres aqui\"]"
  }
}
```
Sempre inspecione este campo em caso de erro 500 para identificar falhas de constraint ou colunas inexistentes.

### Verificação de Rollout (`X-Build-Version`)
Para confirmar se o seu fix foi implantado no cluster via FluxCD, verifique os headers da resposta:
*   **Header:** `X-Build-Version`
*   Se o header estiver ausente, o ambiente ainda está rodando uma versão antiga do código.

---

## 5. Testes de Regressão
Sempre que uma nova regra de mapeamento for descoberta, adicione um teste unitário em `bff/social_care_desktop/test/social_care_bff_remote_test.dart` usando o `MockDio` para garantir que o formato do JSON enviado nunca mude acidentalmente.
