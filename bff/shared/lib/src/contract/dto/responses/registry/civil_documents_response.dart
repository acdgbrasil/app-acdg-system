import 'package:json_annotation/json_annotation.dart';

part 'civil_documents_response.g.dart';

@JsonSerializable()
class CivilDocumentsResponse {
  const CivilDocumentsResponse({this.cpf, this.nis, this.rgDocument, this.cns});

  factory CivilDocumentsResponse.fromJson(Map<String, dynamic> json) =>
      _$CivilDocumentsResponseFromJson(json);

  final String? cpf;
  final String? nis;
  final RgDocumentResponse? rgDocument;
  final CnsResponse? cns;

  Map<String, dynamic> toJson() => _$CivilDocumentsResponseToJson(this);
}

@JsonSerializable()
class RgDocumentResponse {
  const RgDocumentResponse({
    required this.number,
    required this.issuingState,
    required this.issuingAgency,
    required this.issueDate,
  });

  factory RgDocumentResponse.fromJson(Map<String, dynamic> json) =>
      _$RgDocumentResponseFromJson(json);

  final String number;
  final String issuingState;
  final String issuingAgency;
  final String issueDate;

  Map<String, dynamic> toJson() => _$RgDocumentResponseToJson(this);
}

@JsonSerializable()
class CnsResponse {
  const CnsResponse({required this.number, required this.cpf, this.qrCode});

  factory CnsResponse.fromJson(Map<String, dynamic> json) =>
      _$CnsResponseFromJson(json);

  final String number;
  final String cpf;
  final String? qrCode;

  Map<String, dynamic> toJson() => _$CnsResponseToJson(this);
}
