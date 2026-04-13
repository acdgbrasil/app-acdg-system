abstract final class HealthStatusL10n {
  // Nav
  static const navFamilies = 'Familias';
  static const navRegistration = 'Condicoes de Saude';

  // Header
  static const pageTitle = 'Condicoes de Saude da Familia';

  // Sections
  static const sectionDeficiencies = 'Deficiencias';
  static const sectionGestating = 'Membros gestantes';
  static const sectionCareNeeds = 'Necessidade de cuidados constantes';
  static const sectionFoodInsecurity = 'Inseguranca alimentar';

  // Labels — Deficiencies
  static const deficiencyMemberLabel = 'Membro da familia';
  static const deficiencyTypeLabel = 'Tipo de deficiencia';
  static const deficiencyNeedsConstantCareLabel = 'Necessita cuidado constante';
  static const deficiencyResponsibleLabel = 'Nome do cuidador responsavel';
  static const deficiencyResponsibleHint = 'Ex: Maria da Silva';
  static const addDeficiency = 'Adicionar deficiencia';
  static const removeDeficiency = 'Remover';

  // Labels — Gestating
  static const gestatingMemberLabel = 'Membro gestante';
  static const gestatingMonthsLabel = 'Meses de gestacao';
  static const gestatingPrenatalLabel = 'Iniciou pre-natal';
  static const addGestating = 'Adicionar gestante';
  static const removeGestating = 'Remover';

  // Labels — Care needs
  static const careNeedsMemberLabel = 'Membro que necessita cuidado';
  static const addCareNeed = 'Adicionar membro';
  static const removeCareNeed = 'Remover';

  // Labels — Food
  static const foodInsecurityLabel =
      'A familia vivencia situacao de inseguranca alimentar';

  // Validation
  static const gestationMonthsError = 'Gestacao deve ser entre 1 e 10 meses';

  // Empty states
  static const noDeficiencies = 'Nenhuma deficiencia registrada';
  static const noGestating = 'Nenhum membro gestante';
  static const noCareNeeds = 'Nenhuma necessidade de cuidado registrada';

  // Actions
  static const btnCancel = 'Cancelar';
  static const btnSave = 'Salvar';
}
