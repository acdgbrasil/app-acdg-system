import 'package:core/core.dart';

/// Civil documents attached to a patient (CPF, NIS, RG, CNS).
///
/// All fields are optional because at intake time some documents may still
/// be missing; the BFF is responsible for enforcing integrity rules.
class CivilDocuments with Equatable {
  const CivilDocuments({this.cpf, this.nis, this.rgDocument, this.cns});

  final String? cpf;
  final String? nis;
  final RgDocument? rgDocument;
  final Cns? cns;

  CivilDocuments copyWith({
    String? cpf,
    String? nis,
    RgDocument? rgDocument,
    Cns? cns,
  }) {
    return CivilDocuments(
      cpf: cpf ?? this.cpf,
      nis: nis ?? this.nis,
      rgDocument: rgDocument ?? this.rgDocument,
      cns: cns ?? this.cns,
    );
  }

  @override
  List<Object?> get props => [cpf, nis, rgDocument, cns];
}

/// Brazilian `Registro Geral` (state-issued ID document).
class RgDocument with Equatable {
  const RgDocument({
    required this.number,
    required this.issuingState,
    required this.issuingAgency,
    required this.issueDate,
  });

  final String number;
  final String issuingState;
  final String issuingAgency;
  final String issueDate;

  RgDocument copyWith({
    String? number,
    String? issuingState,
    String? issuingAgency,
    String? issueDate,
  }) {
    return RgDocument(
      number: number ?? this.number,
      issuingState: issuingState ?? this.issuingState,
      issuingAgency: issuingAgency ?? this.issuingAgency,
      issueDate: issueDate ?? this.issueDate,
    );
  }

  @override
  List<Object?> get props => [number, issuingState, issuingAgency, issueDate];
}

/// `Cartão Nacional de Saúde` — Brazilian national health card.
class Cns with Equatable {
  const Cns({required this.number, required this.cpf, this.qrCode});

  final String number;
  final String cpf;
  final String? qrCode;

  Cns copyWith({String? number, String? cpf, String? qrCode}) {
    return Cns(
      number: number ?? this.number,
      cpf: cpf ?? this.cpf,
      qrCode: qrCode ?? this.qrCode,
    );
  }

  @override
  List<Object?> get props => [number, cpf, qrCode];
}
