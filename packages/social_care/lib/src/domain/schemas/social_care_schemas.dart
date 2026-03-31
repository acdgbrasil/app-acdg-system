import 'package:shared/shared.dart';
import 'package:zard/zard.dart';

/// Centralized schemas for Social Care validation, integrating with the shared domain.
abstract final class SocialCareSchemas {
  /// Schema for CPF validation using shared domain logic.
  static final cpf = z.string().refine(
    (v) => Cpf.create(v).isSuccess,
    message: 'CPF inválido',
  );

  /// Schema for required names.
  static final name = z.string().trim().min(
    2,
    message: 'Mínimo de 2 caracteres',
  );

  /// Full Patient Registration Schema.
  /// Primitives are used for zard 0.0.26 compatibility.
  static final patientRegistration = z.map({
    'firstName': name,
    'lastName': name,
    'motherName': name,
    'nationality': name,
    'sex': z.string().min(1, message: 'Sexo obrigatório'),
    'cpf': cpf,
    'birthDate': z.date(),
    'addressState': z
        .string(), // Optional at schema level, validated in domain if present
    'city': z.string(),
    'residenceLocation': z.string(),
  });

  /// Schema for family member addition/edition.
  static final familyMember = z.map({
    'fullName': name,
    'relationship': z.string().min(1, message: 'Selecione o parentesco'),
    'sex': z.string().min(1, message: 'Selecione o sexo'),
  });

  /// Schema for specificities validation.
  static final specificities = z
      .map({
        'isIndigenousResident': z.bool(),
        'indigenousResidentEtnia': z.string(),
        'isIndigenousNonResident': z.bool(),
        'indigenousNonResidentEtnia': z.string(),
        'isOtherSpecificity': z.bool(),
        'otherSpecificityDescription': z.string(),
      })
      .refine((data) {
        if (data['isIndigenousResident'] == true &&
            (data['indigenousResidentEtnia'] as String).isEmpty) {
          return false;
        }
        if (data['isIndigenousNonResident'] == true &&
            (data['indigenousNonResidentEtnia'] as String).isEmpty) {
          return false;
        }
        if (data['isOtherSpecificity'] == true &&
            (data['otherSpecificityDescription'] as String).isEmpty) {
          return false;
        }
        return true;
      }, message: 'Especifique o povo / etnia ou descrição');
}
