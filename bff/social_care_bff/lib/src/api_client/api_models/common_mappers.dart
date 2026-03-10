import '../../models/audit_event.dart';
import '../../models/computed_analytics.dart';
import '../../models/lookup_item.dart';

/// JSON → domain model mappers for shared/common types.
abstract final class CommonMappers {
  static LookupItem lookupItemFromJson(Map<String, dynamic> json) =>
      LookupItem(
        id: json['id'] as String,
        codigo: json['codigo'] as String,
        descricao: json['descricao'] as String,
      );

  static AuditEvent auditEventFromJson(Map<String, dynamic> json) =>
      AuditEvent(
        id: json['id'] as String,
        aggregateId: json['aggregateId'] as String,
        eventType: json['eventType'] as String,
        payload: json['payload'] as Map<String, dynamic>,
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        actorId: json['actorId'] as String?,
      );
}

/// JSON → [ComputedAnalytics] mapper.
abstract final class ComputedAnalyticsMapper {
  static ComputedAnalytics fromJson(dynamic json) {
    if (json == null) return const ComputedAnalytics();
    final m = json as Map<String, dynamic>;
    return ComputedAnalytics(
      housing: _parseHousingAnalytics(m['housing']),
      financial: _parseFinancialAnalytics(m['financial']),
      ageProfile: _parseAgeProfile(m['ageProfile']),
      educationalVulnerabilities: _parseEducationalVulnerabilities(
        m['educationalVulnerabilities'],
      ),
    );
  }

  static HousingAnalytics? _parseHousingAnalytics(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return HousingAnalytics(
      density: (m['density'] as num?)?.toDouble(),
      isOvercrowded: m['isOvercrowded'] as bool?,
    );
  }

  static FinancialAnalytics? _parseFinancialAnalytics(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return FinancialAnalytics(
      totalWorkIncome: (m['totalWorkIncome'] as num?)?.toDouble(),
      perCapitaWorkIncome: (m['perCapitaWorkIncome'] as num?)?.toDouble(),
      totalGlobalIncome: (m['totalGlobalIncome'] as num?)?.toDouble(),
      perCapitaGlobalIncome: (m['perCapitaGlobalIncome'] as num?)?.toDouble(),
    );
  }

  static AgeProfile? _parseAgeProfile(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return AgeProfile(
      range0to6: m['range0to6'] as int? ?? 0,
      range7to14: m['range7to14'] as int? ?? 0,
      range15to17: m['range15to17'] as int? ?? 0,
      range18to29: m['range18to29'] as int? ?? 0,
      range30to59: m['range30to59'] as int? ?? 0,
      range60to64: m['range60to64'] as int? ?? 0,
      range65to69: m['range65to69'] as int? ?? 0,
      range70Plus: m['range70Plus'] as int? ?? 0,
      totalMembers: m['totalMembers'] as int? ?? 0,
    );
  }

  static EducationalVulnerabilities? _parseEducationalVulnerabilities(
    dynamic json,
  ) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return EducationalVulnerabilities(
      notInSchool0to5: m['notInSchool0to5'] as int? ?? 0,
      notInSchool6to14: m['notInSchool6to14'] as int? ?? 0,
      notInSchool15to17: m['notInSchool15to17'] as int? ?? 0,
      illiteracy10to17: m['illiteracy10to17'] as int? ?? 0,
      illiteracy18to59: m['illiteracy18to59'] as int? ?? 0,
      illiteracy60Plus: m['illiteracy60Plus'] as int? ?? 0,
    );
  }
}
