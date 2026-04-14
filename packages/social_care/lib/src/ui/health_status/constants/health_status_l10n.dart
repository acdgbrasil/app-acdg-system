abstract final class HealthStatusL10n {
  // Nav
  static const navFamilies = 'Famílias';
  static const navRegistration = 'Condições de Saúde';

  // Header
  static const pageTitle = 'Condições de Saúde da Família';

  // Sections
  static const sectionDeficiencies = 'Deficiências';
  static const sectionGestating = 'Membros gestantes';
  static const sectionCareNeeds = 'Necessidade de cuidados constantes';
  static const sectionFoodInsecurity = 'Insegurança alimentar';

  // Labels — Deficiencies
  static const deficiencyMemberLabel = 'Membro da família';
  static const deficiencyTypeLabel = 'Tipo de deficiência';
  static const deficiencyNeedsConstantCareLabel = 'Necessita cuidado constante';
  static const deficiencyResponsibleLabel = 'Nome do cuidador responsável';
  static const deficiencyResponsibleHint = 'Ex: Maria da Silva';
  static const addDeficiency = 'Adicionar deficiência';
  static const removeDeficiency = 'Remover';

  // Labels — Gestating
  static const gestatingMemberLabel = 'Membro gestante';
  static const gestatingMonthsLabel = 'Meses de gestação';
  static const gestatingPrenatalLabel = 'Iniciou pré-natal';
  static const addGestating = 'Adicionar gestante';
  static const removeGestating = 'Remover';

  // Labels — Care needs
  static const careNeedsMemberLabel = 'Membro que necessita cuidado';
  static const addCareNeed = 'Adicionar membro';
  static const removeCareNeed = 'Remover';

  // Labels — Food
  static const foodInsecurityLabel =
      'A família vivencia situação de insegurança alimentar';

  // Validation
  static const gestationMonthsError = 'Gestação deve ser entre 1 e 11 meses';
  static const gestatingOnlyFemaleError =
      'Apenas membros do sexo feminino podem ser gestantes';

  // Empty states
  static const noDeficiencies = 'Nenhuma deficiência registrada';
  static const noGestating = 'Nenhum membro gestante';
  static const noCareNeeds = 'Nenhuma necessidade de cuidado registrada';

  // Actions
  static const btnCancel = 'Cancelar';
  static const btnSave = 'Salvar';
}
