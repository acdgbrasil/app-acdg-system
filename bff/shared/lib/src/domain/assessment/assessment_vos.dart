import 'package:core/core.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';
import '../kernel/ids.dart';

// =============================================================================
// HOUSING CONDITION
// =============================================================================

enum ConditionType { owned, rented, ceded, squatted }
enum WallMaterial { masonry, finishedWood, makeshiftMaterials }
enum WaterSupply { publicNetwork, wellOrSpring, rainwaterHarvest, waterTruck, other }
enum ElectricityAccess { meteredConnection, irregularConnection, noAccess }
enum SewageDisposal { publicSewer, septicTank, rudimentaryPit, openSewage, noBathroom }
enum WasteCollection { directCollection, indirectCollection, noCollection }
enum AccessibilityLevel { fullyAccessible, partiallyAccessible, notAccessible }

final class HousingCondition with Equatable {
  const HousingCondition._({
    required this.type,
    required this.wallMaterial,
    required this.numberOfRooms,
    required this.numberOfBedrooms,
    required this.numberOfBathrooms,
    required this.waterSupply,
    required this.hasPipedWater,
    required this.electricityAccess,
    required this.sewageDisposal,
    required this.wasteCollection,
    required this.accessibilityLevel,
    required this.isInGeographicRiskArea,
    required this.hasDifficultAccess,
    required this.isInSocialConflictArea,
    required this.hasDiagnosticObservations,
  });

  final ConditionType type;
  final WallMaterial wallMaterial;
  final int numberOfRooms;
  final int numberOfBedrooms;
  final int numberOfBathrooms;
  final WaterSupply waterSupply;
  final bool hasPipedWater;
  final ElectricityAccess electricityAccess;
  final SewageDisposal sewageDisposal;
  final WasteCollection wasteCollection;
  final AccessibilityLevel accessibilityLevel;
  final bool isInGeographicRiskArea;
  final bool hasDifficultAccess;
  final bool isInSocialConflictArea;
  final bool hasDiagnosticObservations;

  @override
  List<Object?> get props => [
        type, wallMaterial, numberOfRooms, numberOfBedrooms, numberOfBathrooms,
        waterSupply, hasPipedWater, electricityAccess, sewageDisposal,
        wasteCollection, accessibilityLevel, isInGeographicRiskArea,
        hasDifficultAccess, isInSocialConflictArea, hasDiagnosticObservations,
      ];

  static Result<HousingCondition> create({
    required ConditionType type,
    required WallMaterial wallMaterial,
    required int numberOfRooms,
    required int numberOfBedrooms,
    required int numberOfBathrooms,
    required WaterSupply waterSupply,
    required bool hasPipedWater,
    required ElectricityAccess electricityAccess,
    required SewageDisposal sewageDisposal,
    required WasteCollection wasteCollection,
    required AccessibilityLevel accessibilityLevel,
    required bool isInGeographicRiskArea,
    required bool hasDifficultAccess,
    required bool isInSocialConflictArea,
    required bool hasDiagnosticObservations,
  }) {
    if (numberOfRooms < 0) return Failure(_buildError('HC-001', 'Número de cômodos não pode ser negativo'));
    if (numberOfBedrooms < 0) return Failure(_buildError('HC-002', 'Número de quartos não pode ser negativo'));
    if (numberOfBathrooms < 0) return Failure(_buildError('HC-003', 'Número de banheiros não pode ser negativo'));
    if (numberOfBedrooms > numberOfRooms) {
      return Failure(_buildError('HC-004', 'Número de quartos não pode exceder o número total de cômodos'));
    }

    return Success(HousingCondition._(
      type: type,
      wallMaterial: wallMaterial,
      numberOfRooms: numberOfRooms,
      numberOfBedrooms: numberOfBedrooms,
      numberOfBathrooms: numberOfBathrooms,
      waterSupply: waterSupply,
      hasPipedWater: hasPipedWater,
      electricityAccess: electricityAccess,
      sewageDisposal: sewageDisposal,
      wasteCollection: wasteCollection,
      accessibilityLevel: accessibilityLevel,
      isInGeographicRiskArea: isInGeographicRiskArea,
      hasDifficultAccess: hasDifficultAccess,
      isInSocialConflictArea: isInSocialConflictArea,
      hasDiagnosticObservations: hasDiagnosticObservations,
    ));
  }

  HousingCondition copyWith({
    ConditionType? type,
    WallMaterial? wallMaterial,
    int? numberOfRooms,
    int? numberOfBedrooms,
    int? numberOfBathrooms,
    WaterSupply? waterSupply,
    bool? hasPipedWater,
    ElectricityAccess? electricityAccess,
    SewageDisposal? sewageDisposal,
    WasteCollection? wasteCollection,
    AccessibilityLevel? accessibilityLevel,
    bool? isInGeographicRiskArea,
    bool? hasDifficultAccess,
    bool? isInSocialConflictArea,
    bool? hasDiagnosticObservations,
  }) {
    return HousingCondition._(
      type: type ?? this.type,
      wallMaterial: wallMaterial ?? this.wallMaterial,
      numberOfRooms: numberOfRooms ?? this.numberOfRooms,
      numberOfBedrooms: numberOfBedrooms ?? this.numberOfBedrooms,
      numberOfBathrooms: numberOfBathrooms ?? this.numberOfBathrooms,
      waterSupply: waterSupply ?? this.waterSupply,
      hasPipedWater: hasPipedWater ?? this.hasPipedWater,
      electricityAccess: electricityAccess ?? this.electricityAccess,
      sewageDisposal: sewageDisposal ?? this.sewageDisposal,
      wasteCollection: wasteCollection ?? this.wasteCollection,
      accessibilityLevel: accessibilityLevel ?? this.accessibilityLevel,
      isInGeographicRiskArea: isInGeographicRiskArea ?? this.isInGeographicRiskArea,
      hasDifficultAccess: hasDifficultAccess ?? this.hasDifficultAccess,
      isInSocialConflictArea: isInSocialConflictArea ?? this.isInSocialConflictArea,
      hasDiagnosticObservations: hasDiagnosticObservations ?? this.hasDiagnosticObservations,
    );
  }

  static AppError _buildError(String code, String message) {
    return AppError(
      code: code, message: message, module: 'social-care/housing-condition', kind: 'domainValidation', http: 422,
      observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.warning),
    );
  }
}

// =============================================================================
// SOCIO ECONOMIC
// =============================================================================

final class SocialBenefit with Equatable {
  const SocialBenefit._({required this.benefitName, required this.amount, required this.beneficiaryId});
  
  final String benefitName;
  final double amount;
  final PersonId beneficiaryId;

  @override
  List<Object?> get props => [benefitName, amount, beneficiaryId];

  SocialBenefit copyWith({
    String? benefitName,
    double? amount,
    PersonId? beneficiaryId,
  }) {
    return SocialBenefit._(
      benefitName: benefitName ?? this.benefitName,
      amount: amount ?? this.amount,
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
    );
  }

  static Result<SocialBenefit> create({required String? benefitName, required double amount, required PersonId beneficiaryId}) {
    final bn = benefitName?.normalize();
    if (bn == null || bn.isEmpty) return Failure(_buildBenefitError('SB-001', 'Nome do benefício não pode ser vazio'));
    if (amount <= 0) return Failure(_buildBenefitError('SB-002', 'Valor do benefício deve ser maior que zero'));
    
    return Success(SocialBenefit._(benefitName: bn, amount: amount, beneficiaryId: beneficiaryId));
  }

  static AppError _buildBenefitError(String code, String message) {
    return AppError(code: code, message: message, module: 'social-care/social-benefit', kind: 'domainValidation', http: 422, observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.warning));
  }
}

final class SocialBenefitsCollection with Equatable {
  const SocialBenefitsCollection._(this.items);
  final List<SocialBenefit> items;
  
  bool get isEmpty => items.isEmpty;
  int get count => items.length;
  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.amount);

  @override
  List<Object?> get props => [items];

  static Result<SocialBenefitsCollection> create(List<SocialBenefit> items) {
    final names = items.map((e) => e.benefitName).toSet();
    if (names.length != items.length) {
      return Failure(
        AppError(code: 'SBC-002', message: 'Não é permitido benefício duplicado (mesmo nome)', module: 'social-care/social-benefits-collection', kind: 'domainValidation', http: 422, observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.warning))
      );
    }
    return Success(SocialBenefitsCollection._(List.unmodifiable(items)));
  }
}

final class SocioEconomicSituation with Equatable {
  const SocioEconomicSituation._({
    required this.totalFamilyIncome, required this.incomePerCapita, required this.receivesSocialBenefit, required this.socialBenefits, required this.mainSourceOfIncome, required this.hasUnemployed
  });

  final double totalFamilyIncome;
  final double incomePerCapita;
  final bool receivesSocialBenefit;
  final SocialBenefitsCollection socialBenefits;
  final String mainSourceOfIncome;
  final bool hasUnemployed;

  @override
  List<Object?> get props => [totalFamilyIncome, incomePerCapita, receivesSocialBenefit, socialBenefits, mainSourceOfIncome, hasUnemployed];

  static Result<SocioEconomicSituation> create({
    required double totalFamilyIncome, required double incomePerCapita, required bool receivesSocialBenefit, required SocialBenefitsCollection socialBenefits, required String? mainSourceOfIncome, required bool hasUnemployed
  }) {
    if (totalFamilyIncome < 0) return Failure(_buildSocioError('SES-003', 'Renda familiar total não pode ser negativa'));
    if (incomePerCapita < 0) return Failure(_buildSocioError('SES-004', 'Renda per capita não pode ser negativa'));
    if (incomePerCapita > totalFamilyIncome) return Failure(_buildSocioError('SES-006', 'Renda per capita não pode ser maior que a renda familiar total'));
    
    final source = mainSourceOfIncome?.normalizedTrim();
    if (source == null || source.isEmpty) return Failure(_buildSocioError('SES-005', 'Fonte principal de renda não pode ser vazia'));
    
    if (!receivesSocialBenefit && !socialBenefits.isEmpty) {
      return Failure(_buildSocioError('SES-001', 'Inconsistência: marcou que não recebe benefício, mas há benefícios cadastrados'));
    }
    if (receivesSocialBenefit && socialBenefits.isEmpty) {
      return Failure(_buildSocioError('SES-002', 'Inconsistência: marcou que recebe benefício, mas nenhum benefício foi informado'));
    }

    return Success(SocioEconomicSituation._(totalFamilyIncome: totalFamilyIncome, incomePerCapita: incomePerCapita, receivesSocialBenefit: receivesSocialBenefit, socialBenefits: socialBenefits, mainSourceOfIncome: source, hasUnemployed: hasUnemployed));
  }

  static AppError _buildSocioError(String code, String message) {
    return AppError(code: code, message: message, module: 'social-care/socio-economic', kind: 'domainValidation', http: 422, observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.warning));
  }
}
