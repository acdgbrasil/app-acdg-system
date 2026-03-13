import 'package:core/core.dart';
import '../domain/models/lookup.dart';
import '../domain/models/patient.dart';

/// Contrato principal do Backend For Frontend (BFF) do módulo Social Care.
///
/// Todas as implementações (Web/Desktop) devem respeitar esta interface,
/// garantindo que a camada de lógica do aplicativo permaneça agnóstica à plataforma.
///
/// Todos os métodos retornam [Result] para garantir tratamento de erros seguro.
abstract interface class SocialCareContract {
  // ==========================================
  // PATIENT REGISTRY (Pacientes)
  // ==========================================

  /// Busca um paciente pelo seu [patientId].
  Future<Result<Patient>> getPatient(String patientId);

  /// Busca um paciente pelo vínculo com o [personId] do Identity.
  Future<Result<Patient>> getPatientByPersonId(String personId);

  /// Registra um novo paciente no sistema.
  /// Retorna o [patientId] gerado em caso de sucesso.
  Future<Result<String>> registerPatient(Patient patient);

  // ==========================================
  // LOOKUP (Tabelas de Domínio)
  // ==========================================

  /// Busca todos os itens de uma tabela de domínio específica.
  /// 
  /// Exemplo de tabelas: `dominio_tipo_identidade`, `dominio_parentesco`, etc.
  Future<Result<List<LookupItem>>> getLookupTable(String tableName);
}
