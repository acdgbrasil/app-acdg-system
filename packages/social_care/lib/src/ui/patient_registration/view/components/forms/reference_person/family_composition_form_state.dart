import 'package:flutter/widgets.dart';

import '../../../../models/family_member_snapshot.dart';
import 'family_member_entry.dart';

export '../../../../models/family_member_snapshot.dart';
export 'family_member_entry.dart';

/// Form state for Step 4 — Family Composition.
///
/// Manages the list of family member snapshots and provides
/// factory methods for creating entries (new or from existing snapshot).
class FamilyCompositionFormState {
  final members = ValueNotifier<List<FamilyMemberSnapshot>>([]);

  /// Creates a blank entry for adding a new member.
  FamilyMemberEntry createEntry() => FamilyMemberEntry();

  /// Creates a pre-populated entry from an existing snapshot (for editing).
  FamilyMemberEntry createEntryFromSnapshot(FamilyMemberSnapshot snapshot) =>
      FamilyMemberEntry.fromSnapshot(snapshot);

  void addMember(FamilyMemberSnapshot member) {
    members.value = [...members.value, member];
  }

  void updateMember(int index, FamilyMemberSnapshot member) {
    if (index < 0 || index >= members.value.length) return;
    members.value = [
      for (var i = 0; i < members.value.length; i++)
        if (i == index) member else members.value[i],
    ];
  }

  void removeMember(int index) {
    if (index < 0 || index >= members.value.length) return;
    members.value = [
      for (var i = 0; i < members.value.length; i++)
        if (i != index) members.value[i],
    ];
  }

  /// Whether any existing member is already marked as primary caregiver.
  bool get hasPrimaryCaregiver => members.value.any((m) => m.isCaregiver);

  // Family members are optional — reference person is always included by the ViewModel.
  bool get isValidForNextStep => true;

  List<String> get validationErrors => const [];

  void dispose() {
    members.dispose();
  }
}
