/// Constants for the home/listing screen strings.
abstract final class HomeLn10 {
  // ── Top Bar ──────────────────────────────────────────────────
  static const String tabFamilies = 'Famílias';
  static const String tabRegistration = 'Cadastro';
  static String familyCounter(int count) => '$count famílias cadastradas';

  // ── Search ───────────────────────────────────────────────────
  static const String searchPlaceholder = 'Pesquisar família...';
  static const String emptyStateTitle = 'Nenhuma família encontrada';

  // ── FAB ──────────────────────────────────────────────────────
  static const String newRegistration = 'Novo cadastro';

  // ── Detail Panel: Dados ──────────────────────────────────────
  static const String panelDadosTitle = 'Dados';
  static const String labelFullName = 'Nome completo';
  static const String labelMotherName = 'Nome da mãe';
  static const String labelDiagnosis = 'Diagnóstico';
  static const String labelBirthDate = 'Data de nascimento';
  static const String labelCpf = 'CPF';
  static const String labelStatus = 'Status';
  static const String labelEntryDate = 'Data de ingresso';
  static const String labelResponsible = 'Tec. responsável';
  static const String labelCep = 'CEP';
  static const String labelPhone = 'Telefone';
  static const String labelAddress = 'Endereço';
  static const String statusActive = 'Ativo';
  static const String statusInactive = 'Inativo';
  static const String emptyValue = '—';

  // ── Detail Panel: Fichas ─────────────────────────────────────
  static const String panelFichasTitle = 'Fichas';
  static String fichasSubtitle(String lastName, int filled, int total) =>
      'Família $lastName — $filled de $total preenchidas';

  // ── Members subtitle ─────────────────────────────────────────
  static String membersLabel(int count) => '$count membros';
}
