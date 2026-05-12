# Auditoria Arquitetural Detalhada — Integridade de Mappers (DTO vs Domain)
**Data:** 02 de Abril de 2026
**Especialista:** flutter-arch-review (Gemini CLI)

Esta auditoria concentrou-se na camada de infraestrutura e comunicação de dados do projeto, especificamente em como as respostas da API e o banco de dados local (`Map<String, dynamic>`) são convertidos de e para Entidades de Domínio. O foco foi a pasta `bff/shared/lib/src/infrastructure/mappers/` e sua utilização no Flutter (`BffPatientRepository`).

A análise identificou que o modelo atual de Mappers manuais escalou de forma insustentável, tornando a base de código extremamente verbosa, frágil e propensa a erros silenciosos.

---

## 1. O Problema Fundamental: "JSON na Mão" e Boilerplate Extremo

### 1.1. Fragilidade e Verbosidade nos Mappers Manuais
**Arquivos afetados:** 
- `bff/shared/lib/src/infrastructure/patient_mapper.dart`
- Todos os submáppers (`registry_mapper.dart`, `assessment_mapper.dart`, etc.)

**🚫 Anti-padrão:**
O projeto optou por não utilizar ferramentas de geração de código (como `json_serializable` ou `freezed`) para a camada de serialização. Em vez disso, criou-se um exército de mappers manuais.
No `PatientMapper.fromJson`, existem quase 150 linhas contínuas de blocos `switch` gigantes apenas para tentar converter as chaves do JSON e tratar os `Result/Failure`. 
- **Por que é errado:** Qualquer alteração no contrato do backend (adição/remoção de uma chave) exige atualização manual de strings mágicas (`json['socialIdentity']`) em múltiplos arquivos. Além disso, a verbosidade torna o código ilegível e desencoraja refatorações. Um único typo em uma string resulta em falha silenciosa em tempo de execução (runtime crash), em vez de ser pego pelo compilador.

### 1.2. Ausência de DTOs Estruturados (Domain Leak)
**Arquivo afetado:** `bff/shared/lib/src/infrastructure/patient_mapper.dart`

**🚫 Anti-padrão:**
A arquitetura não possui classes puras de DTO (Data Transfer Objects) que espelhem a API. O código tenta mapear um `Map<String, dynamic>` bruto e sem tipagem diretamente para o Agregado de Domínio (`Patient` e `PersonalData`).
- **Por que é errado:** A Entidade de Domínio é rica (possui validações de invariantes e tipos fechados como `PatientId` ou `TimeStamp`). O JSON da API é anêmico (strings puras). Tentar unir os dois passos (parse do JSON e construção do Domínio) em um único método infla a complexidade e viola o princípio de responsabilidade única.

### 1.3. O "Frankenstein" no Repositório Flutter
**Arquivo afetado:** `packages/social_care/lib/src/data/repositories/bff_patient_repository.dart`

**🚫 Anti-padrão:**
Conforme auditado anteriormente, como o domínio retorna as Entidades puras, o `BffPatientRepository` precisou transformar o `Patient` de volta em DTOs de tela (ex: `PatientDetail` e `FichaStatus`). Para piorar, as classes de tela (como `HousingConditionDetail.fromJson`) esperam um JSON, forçando o Repositório a pegar uma Entidade, mapear para um JSON na unha (`PatientMapper.housingConditionToJson`), para então chamar o `.fromJson` do modelo de tela.
Isso é um "crime arquitetural": `Domain -> Map -> UI Model`.

---

## 2. A Solução: Padrões de Projeto Recomendados

Para resolver esse problema crônico de verbosidade e segurança de tipagem, a arquitetura deve obrigatoriamente adotar **Geração de Código** e **Separação em DTOs**.

### O Padrão Correto a ser implementado:

#### Passo A: Implementar DTOs de API usando `json_serializable` (ou `freezed`)
Criar representações literais (e anêmicas) da resposta da API. Elas servem apenas de "ponte" segura e tipada.

```dart
import 'package:json_annotation/json_annotation.dart';

part 'patient_dto.g.dart';

@JsonSerializable()
class PatientDTO {
  final String patientId;
  final String personId;
  final PersonalDataDTO? personalData;
  // ...

  PatientDTO({required this.patientId, required this.personId, this.personalData});

  factory PatientDTO.fromJson(Map<String, dynamic> json) => _$PatientDTOFromJson(json);
  Map<String, dynamic> toJson() => _$PatientDTOToJson(this);
}
```

#### Passo B: Simplificar os Mappers (DTO <-> Domain)
Com os DTOs em mãos (garantidos pelo compilador), o `PatientMapper` deixa de tratar `Map<String, dynamic>` e passa a converter de `PatientDTO` para `Patient` (Entidade). Isso remove 100% da necessidade de strings mágicas.

```dart
class PatientMapper {
  static Result<Patient> toDomain(PatientDTO dto) {
    // 1. O DTO já garantiu que os tipos base estão corretos.
    // 2. Agora o Mapper só foca em instanciar os ValueObjects do domínio.
    final idResult = PatientId.create(dto.patientId);
    if (idResult is Failure) return Failure(idResult.error);
    
    // ...
  }
}
```

#### Passo C: Interações do Repositório
O repositório (ex: `OfflineFirstRepository`) consome a rede (`dio`/`http`), faz o parse automático para `PatientDTO.fromJson()`, passa pelo `PatientMapper.toDomain(dto)` e salva no banco local.

O ViewModel no Flutter recebe a Entidade `Patient` e mapeia nativamente (sem gerar JSON intermediário) para seus próprios ViewModels de tela se precisar.

---

## 3. Plano de Ação & Roadmap

1. **Adotar Dependências Essenciais:**
   - Adicionar `json_annotation` (dependência) e `json_serializable`, `build_runner` (dev_dependencies) no pacote `bff/shared`.
2. **Criar a Camada de DTOs:**
   - Na pasta `bff/shared/lib/src/infrastructure/dtos/`, criar as classes de DTO para todas as entidades principais (e rodar o build_runner).
3. **Refatorar Mappers:**
   - Alterar todos os submáppers (como `RegistryMapper`) para que recebam e retornem os respectivos DTOs, ao invés de `Map<String, dynamic>`. Remover as validações exaustivas de tipos e nulos, delegando isso ao gerador de código do `json_serializable`.
4. **Limpar a Camada Flutter:**
   - Uma vez que os Mappers retornem as entidades com segurança e o BFF/Repositório utilize os DTOs no meio do caminho, todas as rotinas em `BffPatientRepository` de "fabricar JSON manualmente" podem (e devem) ser completamente apagadas.

---
**Conclusão:** 
O estado atual da serialização de dados é uma bomba-relógio de dívida técnica. A adoção do padrão DTO associado a ferramentas de geração de código de serialização (`json_serializable`) é mandatória para manter a resiliência e estabilidade exigidas pelo **Architectural Gold Standard** da ACDG.