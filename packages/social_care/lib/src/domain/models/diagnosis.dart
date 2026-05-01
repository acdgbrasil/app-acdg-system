import 'package:core/core.dart';

/// A clinical diagnosis recorded against a patient (CID/ICD).
class Diagnosis with Equatable {
  const Diagnosis({
    required this.icdCode,
    required this.description,
    required this.date,
  });

  final String icdCode;
  final String description;
  final String date;

  Diagnosis copyWith({String? icdCode, String? description, String? date}) {
    return Diagnosis(
      icdCode: icdCode ?? this.icdCode,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }

  @override
  List<Object?> get props => [icdCode, description, date];
}
