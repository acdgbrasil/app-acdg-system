final class SocialIdentityDetail {
  final String typeId;
  final String? otherDescription;

  const SocialIdentityDetail({required this.typeId, this.otherDescription});

  factory SocialIdentityDetail.fromJson(Map<String, dynamic> json) {
    return SocialIdentityDetail(
      typeId: json['typeId'] as String,
      otherDescription: json['otherDescription'] as String?,
    );
  }
}
