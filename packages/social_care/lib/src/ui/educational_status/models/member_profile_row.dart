/// Mutable form state for a member educational profile entry.
class MemberProfileRow {
  String? memberId;
  bool canReadWrite;
  bool attendsSchool;
  String? educationLevelId;

  MemberProfileRow({
    this.memberId,
    this.canReadWrite = false,
    this.attendsSchool = false,
    this.educationLevelId,
  });
}
