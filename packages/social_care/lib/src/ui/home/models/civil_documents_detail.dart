final class CivilDocumentsDetail {
  final String? cpf;
  final String? nis;
  final RgDocumentDetail? rgDocument;

  const CivilDocumentsDetail({this.cpf, this.nis, this.rgDocument});

  factory CivilDocumentsDetail.fromJson(Map<String, dynamic> json) {
    return CivilDocumentsDetail(
      cpf: json['cpf'] as String?,
      nis: json['nis'] as String?,
      rgDocument: json['rgDocument'] != null
          ? RgDocumentDetail.fromJson(
              json['rgDocument'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

final class RgDocumentDetail {
  final String number;
  final String issuingState;
  final String issuingAgency;
  final String issueDate;

  const RgDocumentDetail({
    required this.number,
    required this.issuingState,
    required this.issuingAgency,
    required this.issueDate,
  });

  factory RgDocumentDetail.fromJson(Map<String, dynamic> json) {
    return RgDocumentDetail(
      number: json['number'] as String,
      issuingState: json['issuingState'] as String,
      issuingAgency: json['issuingAgency'] as String,
      issueDate: json['issueDate'] as String,
    );
  }
}
