import 'package:core/core.dart';
import '../contract/social_care_contract.dart';
import '../domain/models/lookup.dart';
import '../domain/models/patient.dart';

/// Implementação Fake do BFF para testes de UI e simulação local.
///
/// Armazena os dados em memória e simula delays de rede.
class FakeSocialCareBff implements SocialCareContract {
  FakeSocialCareBff({this.networkDelay = const Duration(milliseconds: 500)});

  final Duration networkDelay;

  final Map<String, Patient> _patients = {};

  final Map<String, List<LookupItem>> _lookupTables = {
    'dominio_tipo_identidade': [
      const LookupItem(id: '1', codigo: '01', descricao: 'RG'),
      const LookupItem(id: '2', codigo: '02', descricao: 'CNH'),
    ],
    'dominio_sexo': [
      const LookupItem(id: '1', codigo: 'M', descricao: 'Masculino'),
      const LookupItem(id: '2', codigo: 'F', descricao: 'Feminino'),
    ],
  };

  @override
  Future<Result<Patient>> getPatient(String patientId) async {
    await Future.delayed(networkDelay);
    final patient = _patients[patientId];
    if (patient != null) {
      return Success(patient);
    }
    return const Failure('Paciente não encontrado.');
  }

  @override
  Future<Result<Patient>> getPatientByPersonId(String personId) async {
    await Future.delayed(networkDelay);
    try {
      final patient = _patients.values.firstWhere((p) => p.personId == personId);
      return Success(patient);
    } catch (_) {
      return const Failure('Paciente não encontrado para este Person ID.');
    }
  }

  @override
  Future<Result<String>> registerPatient(Patient patient) async {
    await Future.delayed(networkDelay);
    
    if (_patients.containsKey(patient.id)) {
      return const Failure('Paciente já cadastrado com este ID.');
    }

    _patients[patient.id] = patient;
    return Success(patient.id);
  }

  @override
  Future<Result<List<LookupItem>>> getLookupTable(String tableName) async {
    await Future.delayed(networkDelay);
    final table = _lookupTables[tableName];
    if (table != null) {
      return Success(table);
    }
    return const Failure('Tabela de domínio não encontrada.');
  }

  /// Método auxiliar (apenas no Fake) para popular dados de teste.
  void seedPatient(Patient patient) {
    _patients[patient.id] = patient;
  }
}
