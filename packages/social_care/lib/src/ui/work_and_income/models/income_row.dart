/// Mutable form state for an individual income entry.
class IncomeRow {
  String? memberId;
  String? occupationId;
  bool hasWorkCard;
  double monthlyAmount;

  IncomeRow({
    this.memberId,
    this.occupationId,
    this.hasWorkCard = false,
    this.monthlyAmount = 0,
  });
}
