/// Mutable UI model for a deficiency row.
class DeficiencyRow {
  String? memberId;
  String? deficiencyTypeId;
  bool needsConstantCare;
  String responsibleCaregiverName;

  DeficiencyRow({
    this.memberId,
    this.deficiencyTypeId,
    this.needsConstantCare = false,
    this.responsibleCaregiverName = '',
  });

  DeficiencyRow copy() => DeficiencyRow(
    memberId: memberId,
    deficiencyTypeId: deficiencyTypeId,
    needsConstantCare: needsConstantCare,
    responsibleCaregiverName: responsibleCaregiverName,
  );
}
