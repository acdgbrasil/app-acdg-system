import '../infrastructure/people_context_client.dart';
import 'package:core_contracts/core_contracts.dart';

/// Enriches patient registration payloads with canonical PersonIds
/// from the people-context service.
///
/// Used by both the Web BFF (RegistryHandler) and the Desktop BFF
/// (SyncEngine) to ensure a single source of truth for this logic.
///
/// Non-blocking on failure: if people-context is unreachable, the
/// local UUIDs are kept and the registration proceeds.
class PatientEnrichmentService {
  const PatientEnrichmentService(this._peopleContext);

  final PeopleContextClient _peopleContext;

  /// Enriches a patient registration payload in-place.
  ///
  /// - Registers the reference person in people-context and replaces
  ///   `payload['personId']` with the canonical ID.
  /// - Registers each family member and replaces their `personId`
  ///   and `memberPersonId` with canonical IDs.
  ///
  /// Graceful degradation: failures are silently ignored.
  Future<void> enrichPayload(Map<String, dynamic> payload) async {
    await _enrichReferencePerson(payload);
    await _enrichFamilyMembers(payload);
  }

  Future<void> _enrichReferencePerson(Map<String, dynamic> payload) async {
    final personalData = payload['personalData'] as Map<String, dynamic>? ?? {};
    final civilDocs = payload['civilDocuments'] as Map<String, dynamic>? ?? {};
    final firstName = personalData['firstName'] as String? ?? '';
    final lastName = personalData['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final birthDate = personalData['birthDate'] as String? ?? '';
    final cpf = civilDocs['cpf'] as String?;

    if (fullName.isEmpty || birthDate.isEmpty) return;

    switch (await _peopleContext.registerPerson(
      fullName: fullName,
      birthDate: birthDate,
      cpf: cpf,
    )) {
      case Success(value: final canonicalId):
        payload['personId'] = canonicalId;
      case Failure():
        break;
    }
  }

  Future<void> _enrichFamilyMembers(Map<String, dynamic> payload) async {
    final familyMembers = payload['familyMembers'] as List<dynamic>? ?? [];
    for (final member in familyMembers) {
      if (member is Map<String, dynamic>) {
        final memberName = member['fullName'] as String? ?? '';
        final memberBirth = member['birthDate'] as String? ?? '';
        final memberCpf = member['cpf'] as String?;

        if (memberName.isNotEmpty && memberBirth.isNotEmpty) {
          switch (await _peopleContext.registerPerson(
            fullName: memberName,
            birthDate: memberBirth,
            cpf: memberCpf,
          )) {
            case Success(value: final id):
              member['personId'] = id;
              member['memberPersonId'] = id;
            case Failure():
              break;
          }
        }
      }
    }
  }
}
