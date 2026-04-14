/// Represents a selectable family member in dropdown menus.
///
/// Used across multiple assessment features to populate member
/// selection dropdowns with a human-readable label.
class MemberOption {
  final String id;
  final String label;
  final String? sex;

  const MemberOption({required this.id, required this.label, this.sex});
}
