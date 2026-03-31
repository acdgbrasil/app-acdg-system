import 'package:flutter/widgets.dart';
import 'package:social_care/src/ui/home/models/patient_summary.dart';

class HomeFormState {
  final searchQuery = TextEditingController();
  final families = ValueNotifier<List<PatientSummary>>([]);

  List<PatientSummary> get filteredFamilies {
    final q = searchQuery.text.toLowerCase().trim();
    if (q.isEmpty) return families.value;
    return families.value.where((f) {
      return f.lastName.toLowerCase().contains(q) ||
          f.firstName.toLowerCase().contains(q) ||
          f.fullName.toLowerCase().contains(q);
    }).toList();
  }

  int get totalCount => families.value.length;

  void dispose() {
    searchQuery.dispose();
    families.dispose();
  }
}
