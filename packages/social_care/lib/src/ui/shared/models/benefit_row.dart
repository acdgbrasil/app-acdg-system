/// Mutable form state for a social benefit entry.
///
/// Used in work-and-income and socio-economic assessment forms
/// to capture benefit details before domain conversion.
class BenefitRow {
  String benefitName;
  double amount;
  String? beneficiaryId;
  String? benefitTypeId;

  BenefitRow({
    this.benefitName = '',
    this.amount = 0,
    this.beneficiaryId,
    this.benefitTypeId,
  });
}
