abstract final class TeamL10n {
  static const String pageTitle = 'Equipe';
  static const String addWorker = 'Novo profissional';
  static const String emptyState = 'Nenhum membro da equipe cadastrado.';
  static const String searchHint = 'Buscar por nome ou CPF';
  static const String loadingTeam = 'Carregando equipe...';
  static const String loadError = 'Falha ao carregar a equipe.';
  static const String retry = 'Tentar novamente';

  static const String roleSocialWorker = 'Assistente Social';
  static const String roleAdmin = 'Administrador';
  static const String roleUnknown = 'Papel desconhecido';

  static const String statusActive = 'ATIVO';
  static const String statusInactive = 'INATIVO';

  static const String actionDeactivate = 'Desativar';
  static const String actionReactivate = 'Reativar';
  static const String actionResetPassword = 'Redefinir senha';

  static const String modalTitleAdd = 'Cadastrar profissional';
  static const String fieldFullName = 'Nome completo';
  static const String fieldCpf = 'CPF (opcional)';
  static const String fieldEmail = 'E-mail';
  static const String fieldBirthDate = 'Data de nascimento';
  static const String fieldRole = 'Papel';
  static const String fieldInitialPassword = 'Senha inicial (opcional)';
  static const String buttonRegister = 'Cadastrar';
  static const String buttonCancel = 'Cancelar';
  static const String buttonConfirm = 'Confirmar';

  static const String errorRequired = 'Campo obrigatorio';
  static const String errorMinChars3 = 'Minimo 3 caracteres';
  static const String errorInvalidEmail = 'E-mail invalido';
  static const String errorDateIncomplete = 'Data incompleta';
  static const String errorDateInvalid = 'Data invalida';
  static const String errorSelectRole = 'Selecione um papel';

  static const String registerSuccess = 'Profissional cadastrado com sucesso.';
  static const String registerError = 'Falha ao cadastrar profissional.';
  static const String deactivateSuccess = 'Profissional desativado.';
  static const String reactivateSuccess = 'Profissional reativado.';
  static const String resetPasswordSuccess = 'Senha redefinida com sucesso.';

  static const String confirmDeactivateTitle = 'Desativar profissional';
  static const String confirmReactivateTitle = 'Reativar profissional';
  static const String confirmResetPasswordTitle = 'Redefinir senha';

  static String confirmDeactivateMessage(String name) =>
      'Deseja realmente desativar o acesso de $name?';
  static String confirmReactivateMessage(String name) =>
      'Deseja realmente reativar o acesso de $name?';
  static String confirmResetPasswordMessage(String name) =>
      'Deseja realmente redefinir a senha de $name?';
}
