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
  static const String socialNameHint = 'Preencha apenas se diferente do nome civil';

  static const String lastNameLabel = 'Sobrenome';
  static const String lastNamePlaceholder = 'Sobrenome Completo';

  static const String socialNameLabel = 'Nome Social';
  static const String socialNamePlaceholder = 'Se possuir, digite o nome social';

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

}
