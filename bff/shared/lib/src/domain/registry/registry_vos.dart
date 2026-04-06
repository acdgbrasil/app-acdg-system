import 'package:core/core.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';
import '../kernel/ids.dart';
import '../kernel/time_stamp.dart';
import '../kernel/cns.dart';
import '../kernel/cpf.dart';
import '../kernel/nis.dart';
import '../kernel/rg_document.dart';

// =============================================================================
// ENUMS
// =============================================================================

enum Sex { masculino, feminino, outro }

enum RequiredDocument {
  cn('CN', 'Certidão de Nascimento'),
  rg('RG', 'Registro Geral'),
  ctps('CTPS', 'Carteira de Trabalho e Previdência Social'),
  cpf('CPF', 'Cadastro de Pessoa Física'),
  te('TE', 'Título de Eleitor');

  const RequiredDocument(this.value, this.description);
  final String value;
  final String description;
}

// =============================================================================
// VALUE OBJECTS
// =============================================================================

final class PersonalData with Equatable {
  const PersonalData._({
    required this.firstName,
    required this.lastName,
    required this.motherName,
    required this.nationality,
    required this.sex,
    this.socialName,
    required this.birthDate,
    this.phone,
  });

  final String firstName;
  final String lastName;
  final String motherName;
  final String nationality;
  final Sex sex;
  final String? socialName;
  final TimeStamp birthDate;
  final String? phone;

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    motherName,
    nationality,
    sex,
    socialName,
    birthDate,
    phone,
  ];

  static Result<PersonalData> create({
    required String? firstName,
    required String? lastName,
    required String? motherName,
    required String? nationality,
    required Sex sex,
    String? socialName,
    required TimeStamp? birthDate,
    String? phone,
    TimeStamp? now,
  }) {
    final fn = firstName?.nullIfEmptyNormalized();
    if (fn == null) {
      return Failure(_buildError('PDT-001', 'Nome não pode ser vazio.'));
    }

    final ln = lastName?.nullIfEmptyNormalized();
    if (ln == null) {
      return Failure(_buildError('PDT-002', 'Sobrenome não pode ser vazio.'));
    }

    final mn = motherName?.nullIfEmptyNormalized();
    if (mn == null) {
      return Failure(_buildError('PDT-003', 'Nome da mãe não pode ser vazio.'));
    }

    final nat = nationality?.nullIfEmptyNormalized();
    if (nat == null) {
      return Failure(
        _buildError('PDT-005', 'Nacionalidade não pode ser vazia.'),
      );
    }

    if (birthDate == null) {
      return Failure(
        _buildError('PDT-004', 'Data de nascimento é obrigatória.'),
      );
    }

    final refNow = now ?? TimeStamp.now;
    if (birthDate.date.isAfter(refNow.date)) {
      return Failure(
        _buildError('PDT-004', 'Data de nascimento não pode ser no futuro.'),
      );
    }

    return Success(
      PersonalData._(
        firstName: fn,
        lastName: ln,
        motherName: mn,
        nationality: nat,
        sex: sex,
        socialName: socialName?.nullIfEmptyNormalized(),
        birthDate: birthDate,
        phone: phone?.nullIfEmptyTrimmed(),
      ),
    );
  }

  static AppError _buildError(String code, String message) {
    return AppError(
      code: code,
      message: message,
      module: 'social-care/personal-data',
      kind: 'domainValidation',
      http: 422,
      observability: const Observability(
        category: ErrorCategory.domainRuleViolation,
        severity: ErrorSeverity.warning,
      ),
    );
  }
}

final class CivilDocuments with Equatable {
  const CivilDocuments._({this.cns, this.cpf, this.nis, this.rgDocument});

  final Cns? cns;
  final Cpf? cpf;
  final Nis? nis;
  final RgDocument? rgDocument;

  @override
  List<Object?> get props => [cns, cpf, nis, rgDocument];

  static Result<CivilDocuments> create({
    Cns? cns,
    Cpf? cpf,
    Nis? nis,
    RgDocument? rgDocument,
  }) {
    if (cns == null && cpf == null && nis == null && rgDocument == null) {
      return Failure(
        AppError(
          code: 'CVD-001',
          message:
              'Pelo menos um documento civil deve ser informado (CNS, CPF, NIS ou RG).',
          module: 'social-care/civil-documents',
          kind: 'domainValidation',
          http: 422,
          observability: const Observability(
            category: ErrorCategory.domainRuleViolation,
            severity: ErrorSeverity.warning,
          ),
        ),
      );
    }

    if (cpf != null && cns?.cpf != null && cpf.value != cns!.cpf!.value) {
      return Failure(
        AppError(
          code: 'CNS-006',
          message:
              'O CPF informado não corresponde ao CPF do Cartão do SUS (CNS).',
          module: 'social-care/civil-documents',
          kind: 'domainValidation',
          http: 422,
          observability: const Observability(
            category: ErrorCategory.domainRuleViolation,
            severity: ErrorSeverity.warning,
          ),
        ),
      );
    }

    return Success(
      CivilDocuments._(cns: cns, cpf: cpf, nis: nis, rgDocument: rgDocument),
    );
  }
}

final class SocialIdentity with Equatable {
  const SocialIdentity._({required this.typeId, this.otherDescription});

  final LookupId typeId;
  final String? otherDescription;

  @override
  List<Object?> get props => [typeId, otherDescription];

  static Result<SocialIdentity> create({
    required LookupId typeId,
    String? otherDescription,
    bool isOtherType = false,
  }) {
    final desc = otherDescription?.nullIfEmptyTrimmed();

    if (isOtherType && desc == null) {
      return Failure(
        AppError(
          code: 'SID-003',
          message:
              "Descrição é obrigatória quando o tipo de identidade é 'Outras'.",
          module: 'social-care/social-identity',
          kind: 'domainValidation',
          http: 422,
          observability: const Observability(
            category: ErrorCategory.domainRuleViolation,
            severity: ErrorSeverity.warning,
          ),
        ),
      );
    }

    return Success(SocialIdentity._(typeId: typeId, otherDescription: desc));
  }
}
