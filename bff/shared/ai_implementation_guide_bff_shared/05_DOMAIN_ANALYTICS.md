# 05 - DOMAIN ANALYTICS: Servicos de Analise

> Servicos estaticos (abstract final class) para calculo de indicadores: Housing, Financial, Family, Education.

---

## 1. HousingAnalyticsService

**Arquivo:** `domain/analytics/housing_analytics_service.dart`

```dart
abstract final class HousingAnalyticsService {
  static double calculateDensity({
    required int totalFamilyMembers,
    required int numberOfBedrooms,
  });
  // Formula: max(members, 1) / max(bedrooms, 1)

  static bool isOvercrowded({
    required int totalFamilyMembers,
    required int numberOfBedrooms,
  });
  // Regra: density > 3.0
}
```

---

## 2. FinancialAnalyticsService

**Arquivo:** `domain/analytics/financial_analytics_service.dart`

### 2.1 FinancialIndicators

```dart
final class FinancialIndicators with Equatable {
  final double totalWorkIncome;
  final double perCapitaWorkIncome;
  final double totalGlobalIncome;
  final double perCapitaGlobalIncome;
}
```

### 2.2 Servico

```dart
abstract final class FinancialAnalyticsService {
  static FinancialIndicators calculate({
    required List<WorkIncomeVO> workIncomes,
    required List<SocialBenefit> socialBenefits,
    required int memberCount,
  });
}
```

**Logica:**
1. `totalWorkIncome` = soma de `workIncomes[].monthlyAmount`
2. `totalBenefits` = soma de `socialBenefits[].amount`
3. `divisor = max(memberCount, 1)`
4. `perCapitaWorkIncome = totalWorkIncome / divisor`
5. `totalGlobalIncome = totalWorkIncome + totalBenefits`
6. `perCapitaGlobalIncome = totalGlobalIncome / divisor`

---

## 3. FamilyAnalytics

**Arquivo:** `domain/analytics/family_analytics.dart`

### 3.1 AgeRange

| Valor | Label |
|-------|-------|
| `range0to6` | `0-6 anos` |
| `range7to14` | `7-14 anos` |
| `range15to17` | `15-17 anos` |
| `range18to29` | `18-29 anos` |
| `range30to59` | `30-59 anos` |
| `range60to64` | `60-64 anos` |
| `range65to69` | `65-69 anos` |
| `range70Plus` | `70+ anos` |

### 3.2 AgeProfile

```dart
final class AgeProfile with Equatable {
  final Map<AgeRange, int> distribution;  // unmodifiable
  int count(AgeRange range);              // distribution[range] ?? 0
  int get totalMembers;                   // soma de todos valores
}
```

### 3.3 Servico

```dart
abstract final class FamilyAnalytics {
  static AgeProfile calculateAgeProfile({
    required List<FamilyMember> members,
    required TimeStamp at,
  });
}
```

**Regras de classificacao (usa `member.birthDate.yearsAt(referenceDate: at)`):**

| Idade | Faixa |
|-------|-------|
| <= 6 | `range0to6` |
| <= 14 | `range7to14` |
| <= 17 | `range15to17` |
| <= 29 | `range18to29` |
| <= 59 | `range30to59` |
| <= 64 | `range60to64` |
| <= 69 | `range65to69` |
| >= 70 | `range70Plus` |

---

## 4. EducationAnalyticsService

**Arquivo:** `domain/analytics/education_analytics_service.dart`

### 4.1 Enums

```dart
enum VulnerabilityType {
  notInSchool,  // 'Fora da escola'
  illiteracy,   // 'Analfabetismo'
}

enum EduAgeRange {
  range0to5,    // '0-5 anos'
  range6to14,   // '6-14 anos'
  range15to17,  // '15-17 anos'
  range10to17,  // '10-17 anos'
  range18to59,  // '18-59 anos'
  range60Plus,  // '60+ anos'
}
```

### 4.2 EducationalMember

```dart
final class EducationalMember with Equatable {
  final PersonId personId;
  final TimeStamp birthDate;
  final bool attendsSchool;
  final bool canReadWrite;
}
```

### 4.3 VulnerabilityReport

```dart
final class VulnerabilityReport with Equatable {
  final Map<String, int> counts;  // chave: "${type.name}_${range.name}"
  int count(VulnerabilityType type, EduAgeRange range);
}
```

### 4.4 Servico

```dart
abstract final class EducationAnalyticsService {
  static VulnerabilityReport calculateVulnerabilities({
    required List<EducationalMember> members,
    required TimeStamp at,
  });
}
```

**Logica por membro:**

| Condicao | Idade | Chave |
|----------|-------|-------|
| `!attendsSchool` | <= 5 | `notInSchool_range0to5` |
| `!attendsSchool` | 6-14 | `notInSchool_range6to14` |
| `!attendsSchool` | 15-17 | `notInSchool_range15to17` |
| `!canReadWrite` | 10-17 | `illiteracy_range10to17` |
| `!canReadWrite` | 18-59 | `illiteracy_range18to59` |
| `!canReadWrite` | >= 60 | `illiteracy_range60Plus` |
