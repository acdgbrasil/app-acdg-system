/// Kernel compartilhado do BFF Social Care.
///
/// Contém modelos de domínio, value objects, o contrato de interface
/// e implementações "fake" para testes.
library shared;

// Contrato
export 'src/contract/social_care_contract.dart';

// Value Objects
export 'src/domain/value_objects/cep.dart';
export 'src/domain/value_objects/cpf.dart';
export 'src/domain/value_objects/nis.dart';

// Modelos de Domínio
export 'src/domain/models/lookup.dart';
export 'src/domain/models/patient.dart';

// Testes (Mocks/Fakes)
export 'src/testing/fake_social_care_bff.dart';
