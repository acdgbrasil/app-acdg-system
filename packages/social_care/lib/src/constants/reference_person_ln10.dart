/// Constants for the registration flow strings.
/// Includes corrections from original design.
abstract final class ReferencePersonLn10 {
  static const String wizardTitle = 'Pessoa de Referência';
  static const String navFamilies = 'Famílias';
  static const String navRegistration = 'Cadastro';
  static const String btnBack = 'Voltar';
  static const String btnNext = 'Próximo';
  static const String btnSave = 'Salvar';

  static const String stepPersonalData = 'Dados pessoais';
  static const String stepDocuments = 'Documentos & nascimento';
  static const String stepAddress = 'Endereço';
  static const String stepDiagnoses = 'Diagnósticos';

  static const String firstNameLabel = 'Nome';
  static const String firstNamePlaceholder = 'Primeiro Nome';

  static const String identificationSectionTitle = 'Identificação';
  static const String additionalInfoSectionTitle = 'Informações adicionais';
  static const String requiredFieldLegend = '* Campo obrigatório';
  static const String socialNameHint =
      'Preencha apenas se diferente do nome civil';

  static const String lastNameLabel = 'Sobrenome';
  static const String lastNamePlaceholder = 'Sobrenome Completo';

  static const String socialNameLabel = 'Nome Social';
  static const String socialNamePlaceholder =
      'Se possuir, digite o nome social';

  static const String motherNameLabel = 'Nome da Mãe';
  static const String motherNamePlaceholder = 'Nome completo da mãe';

  static const String nationalityLabel = 'Nacionalidade';
  static const String nationalityPlaceholder = 'Selecione a nacionalidade';

  static const String genderLabel = 'Sexo';
  static const String genderPlaceholder = 'Selecione o sexo';

  static const String phoneNumberLabel = 'Número de Telefone';
  static const String phoneNumberPlaceholder = '(00) 000000-0000';

  static const String nationalityOptionBrasilian = 'Brasileira';
  static const String nationalityOptionForeigner = 'Estrangeira';
  static const String nationalityOptionNationalized = 'Naturalizada';

  static const String genderOptionMale = 'Masculino';
  static const String genderOptionFemale = 'Feminino';
  static const String genderOptionOther = 'Outro';

  // ── Step 1: Documentos & Nascimento ──────────────────────────

  static const String sectionDocuments = 'Documentos Civis';
  static const String sectionRg = 'RG';
  static const String sectionBirth = 'Nascimento';

  static const String cpfLabel = 'CPF';
  static const String cpfPlaceholder = '000.000.000-00';
  static const String cpfError = 'CPF inválido';

  static const String nisLabel = 'NIS';
  static const String nisPlaceholder = '00000000000';
  static const String nisError = 'NIS deve ter 11 dígitos';

  static const String rgNumberLabel = 'Número do RG';
  static const String rgNumberPlaceholder = '00.000.000-0';

  static const String rgUfLabel = 'UF do RG';
  static const String rgUfPlaceholder = 'Selecione o estado';

  static const String rgAgencyLabel = 'Órgão Emissor';
  static const String rgAgencyPlaceholder = 'Ex: SSP, DETRAN';

  static const String rgDateLabel = 'Data de Emissão';
  static const String rgDatePlaceholder = 'DD / MM / AAAA';

  static const String birthDateLabel = 'Data de Nascimento';
  static const String birthDatePlaceholder = 'DD / MM / AAAA';
  static const String birthDateError = 'Informe a data de nascimento';
  static const String birthDateFutureError = 'Data deve ser no passado';
  static const String birthDateInvalidError = 'Data inválida';

  static const String rgGroupError = 'Preencha todos os campos do RG';

  // ── Step 2: Endereço ─────────────────────────────────────────

  static const String sectionAddress = 'Endereço';

  static const String isShelterLabel = 'É um abrigo?';
  static const String isShelterError = 'Informe se é um abrigo';
  static const String radioYes = 'Sim';
  static const String radioNo = 'Não';

  static const String residenceLocationLabel = 'Localização';
  static const String residenceLocationError = 'Selecione a localização';
  static const String radioUrban = 'Urbano';
  static const String radioRural = 'Rural';

  static const String cepLabel = 'CEP';
  static const String cepPlaceholder = '00000-000';
  static const String cepError = 'CEP inválido';

  static const String streetLabel = 'Endereço';
  static const String streetPlaceholder = 'Rua, Avenida, etc.';

  static const String numberLabel = 'Número';
  static const String numberPlaceholder = 'Nº';

  static const String complementLabel = 'Complemento';
  static const String complementPlaceholder = 'Apto, Bloco, etc.';

  static const String neighborhoodLabel = 'Bairro';
  static const String neighborhoodPlaceholder = 'Nome do bairro';

  static const String stateLabel = 'UF';
  static const String statePlaceholder = 'Selecione o estado';
  static const String stateError = 'Selecione o estado';

  static const String cityLabel = 'Cidade';
  static const String cityPlaceholder = 'Nome da cidade';
  static const String cityError = 'Informe a cidade';
  static const String cityMinError = 'Mínimo de 2 caracteres';

  // ── Step 3: Diagnósticos ─────────────────────────────────────

  static const String sectionDiagnoses = 'Diagnósticos';

  static const String icdCodeLabel = 'Código CID';
  static const String icdCodePlaceholder = 'Ex: Q90.0';
  static const String icdCodeError = 'Informe o código CID';

  static const String diagnosisDateLabel = 'Data do Diagnóstico';
  static const String diagnosisDatePlaceholder = 'DD / MM / AAAA';
  static const String diagnosisDateError = 'Informe a data do diagnóstico';
  static const String diagnosisDateInvalidError = 'Data inválida';

  static const String descriptionLabel = 'Descrição';
  static const String descriptionPlaceholder = 'Descrição do diagnóstico';
  static const String descriptionError = 'Informe a descrição';

  static const String addDiagnosisBtn = 'Adicionar diagnóstico';
  static const String diagnosisMinError = 'Adicione pelo menos um diagnóstico';
  static const String diagnosisCardTitle = 'Diagnóstico';

  // ── Step 1: CNS ─────────────────────────────────────────────

  static const String cnsLabel = 'CNS';
  static const String cnsPlaceholder = '000 0000 0000 0000';
  static const String cnsHint = 'Cartão Nacional de Saúde';
  static const String cnsError = 'CNS deve ter 15 dígitos';

  // ── Step 3: CID Callout ─────────────────────────────────────

  static const String cidCalloutTitle = 'CIDs úteis para este cadastro';
  static const String cidCalloutText =
      'Diagnóstico ainda não fechado ou em investigação? Use Z03.9 — padrão do sistema para casos sob observação.';
  static const String cidCalloutChipLabel = 'Em investigação';
  static const String cidCalloutApplied = 'CID aplicado!';

  // ── Step 4: Composição Familiar ─────────────────────────────

  static const String stepFamilyComposition = 'Composição Familiar';
  static const String sectionFamilyMembers = 'Membros da família';
  static const String addMemberBtn = 'Adicionar membro';
  static const String badgeReference = 'Referência';
  static const String memberModalTitle = 'Adicionar Membro';
  static const String memberModalEditTitle = 'Editar Membro';
  static const String memberModalSave = 'Salvar';
  static const String memberNameLabel = 'Nome completo';
  static const String memberNamePlaceholder = 'Nome completo do membro';
  static const String memberBirthDateLabel = 'Data de nascimento';
  static const String memberSexLabel = 'Sexo';
  static const String memberRelationshipLabel = 'Parentesco';
  static const String memberRelationshipPlaceholder = 'Selecione';
  static const String memberPcdLabel = 'Pessoa com deficiência?';
  static const String memberResidingLabel = 'Reside com o paciente?';
  static const String memberCaregiverLabel = 'Cuidador principal?';
  static const String memberDocsLabel = 'Documentos necessários';
  static const String loadingRelationship = 'Carregando parentesco...';

  // ── Step 5: Especificidades ─────────────────────────────────

  static const String stepSpecificities = 'Especificidades';
  static const String sectionSpecificities =
      'Especificidades sociais, étnicas ou culturais da família';
  static const String specFamilyType = 'Tipo de família';
  static const String specIndigenousOther = 'Povos indígenas e outras';
  static const String specCigana = 'Família cigana';
  static const String specQuilombola = 'Família quilombola';
  static const String specRibeirinha = 'Família ribeirinha';
  static const String specHomeless = 'Família / pessoa em situação de rua';
  static const String specIndigenousVillage =
      'Família indígena residente em aldeia / reserva';
  static const String specIndigenousOutside =
      'Família indígena não residente em aldeia / reserva';
  static const String specOther = 'Outras';
  static const String specDescriptionPlaceholder = 'Especifique o povo / etnia';
  static const String specOtherPlaceholder = 'Descreva';
  static const String specLegend = 'Marque a que se aplica à família';

  // ── Step 6: Forma de Ingresso ───────────────────────────────

  static const String stepIntakeInfo = 'Forma de Ingresso';
  static const String sectionIngressType = 'Forma de ingresso na unidade';
  static const String sectionReferralDetails = 'Em caso de encaminhamento';
  static const String sectionSocialPrograms = 'Programas sociais';
  static const String socialProgramsHint =
      'A família, ou algum de seus membros, é beneficiária de:';
  static const String originNameLabel = 'Nome do encaminhador';
  static const String originNamePlaceholder = 'Nome completo';
  static const String originContactLabel = 'Contato';
  static const String originContactPlaceholder = 'Telefone ou e-mail';
  static const String serviceReasonLabel = 'Razões do primeiro atendimento';
  static const String serviceReasonPlaceholder =
      'Descreva os motivos do primeiro atendimento...';
  static const String observationsLabel = 'Observações gerais';
  static const String observationsPlaceholder =
      'Observações adicionais relevantes...';

  // ── Step 2: Endereço (novo) ─────────────────────────────────

  static const String isShelterOptionYes = 'Sim — Abrigo';
  static const String isShelterOptionNo = 'Não';
  static const String isShelterOptionHomeless =
      'Família / pessoa em situação de rua';
  static const String homelessWarning =
      'Campos de endereço desabilitados — não aplicável para situação de rua.';

  // ── Validação compartilhada ─────────────────────────────────

  static const String errorRequired = 'Campo obrigatório';
  static const String errorMinChars3 = 'Mínimo de 3 caracteres';
  static const String errorMinChars2 = 'Mínimo de 2 caracteres';
  static const String errorDateIncomplete = 'Data incompleta';
  static const String errorDateInvalid = 'Data inválida';
  static const String errorDateFuture = 'Data deve ser no passado';
  static const String errorSelectNationality = 'Selecione a nacionalidade';
  static const String errorSelectGender = 'Selecione o sexo';
  static const String errorSelectRelationship = 'Selecione o parentesco';
  static const String errorSelectHousingSituation =
      'Selecione a situação do domicílio';
  static const String errorSelectLocation = 'Selecione a localização';
  static const String errorSelectState = 'Selecione o estado';
  static const String errorSelectIngressType = 'Selecione a forma de ingresso';
  static const String errorInformCity = 'Informe a cidade';
  static const String errorPhoneInvalid = 'Número de telefone inválido';
  static const String errorNameNoDigits = 'Nomes não podem conter números';
  static const String errorNameNoSpecialChars =
      'Nomes não podem conter caracteres especiais';
  static const String errorCnsFirstDigit =
      'Primeiro dígito deve ser 1, 2, 7, 8 ou 9';
  static const String errorCaregiverExists =
      'Já existe um cuidador principal. Remova o atual antes de atribuir outro.';

  // ── CID Z03.9 description ──────────────────────────────────

  static const String cidZ039Description =
      'Observação por suspeita de doença ou afecção não especificada';

  // ── Step 4: Tabela ──────────────────────────────────────────

  static const String tableHeaderName = 'Nome';
  static const String tableHeaderAge = 'Idade';
  static const String tableHeaderSex = 'Sexo';
  static const String tableHeaderRelationship = 'Parentesco';
  static const String tableHeaderPcd = 'PcD';
  static const String tableHeaderDocs = 'Docs';
  static const String tableRefPersonRelationship = '01 - Pessoa de Referência';
  static const String tableMembersHint =
      'Adicione outros membros da família abaixo, se houver.';
  static const String tooltipEdit = 'Editar';
  static const String tooltipRemove = 'Remover';
  static const String ageYears = 'anos';

  // ── Step 6: Ingresso options ────────────────────────────────

  static const String ingressEspontaneo = 'Por demanda espontânea';
  static const String ingressBuscaAtiva =
      'Em decorrência de busca ativa realizada pela equipe da unidade';
  static const String ingressEncSaude = 'Encaminhamento pela área de saúde';
  static const String ingressEncJudiciario =
      'Encaminhamento pelo Poder Judiciário';
  static const String ingressEncConselho =
      'Encaminhamento pelo Conselho Tutelar';
  static const String ingressEncEducacao =
      'Encaminhamento pela área de educação';
  static const String ingressEncSetoriais =
      'Encaminhamento por outras políticas setoriais';
  static const String ingressEncPsb =
      'Encaminhamento por serviços da Proteção Social Básica';
  static const String ingressEncPse =
      'Encaminhamento por serviços da Proteção Social Especial';
  static const String ingressEncSgd =
      'Encaminhamento pelo Sistema de Garantia de Direitos';
  static const String ingressOutros = 'Outros encaminhamentos';

  static const String programBolsaFamilia = 'Bolsa Família';
  static const String programBpc = 'BPC';
  static const String programPeti = 'PETI';
  static const String programOutros = 'Outros';

  // ── Error Modal ─────────────────────────────────────────────

  static const String errorNetworkTitle = 'Sem conexão';
  static const String errorServerTitle = 'Erro no servidor';
  static const String errorNetworkDescription =
      'Verifique sua internet e tente novamente. Seus dados não foram perdidos.';
  static const String errorServerDescription =
      'Algo deu errado ao salvar o cadastro. Seus dados estão seguros, tente novamente.';
  static const String errorNetworkCode = 'ERR_NETWORK_TIMEOUT';
  static const String errorServerCode = 'HTTP 500 — Internal Server Error';
  static const String btnClose = 'Fechar';
  static const String btnRetry = 'Tentar novamente';

  // ── Error Banner ────────────────────────────────────────────

  static const String bannerFieldsNeedAttention = 'campos precisam de atenção';

  // ── Success ─────────────────────────────────────────────────

  static const String savedSuccessfully = 'Salvo com sucesso!';
}
