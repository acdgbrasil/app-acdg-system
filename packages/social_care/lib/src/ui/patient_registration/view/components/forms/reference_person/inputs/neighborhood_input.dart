import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class NeighborhoodInput extends StatelessWidget {
  final String? errorText;
  final TextEditingController neighborhoodController;

  const NeighborhoodInput({super.key, this.errorText, required this.neighborhoodController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: neighborhoodController,
      builder: (context, child) {
        return TextFormField(
          controller: neighborhoodController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            label: const Text(
              ReferencePersonLn10.neighborhoodLabel,
              style: TextStyle(color: Colors.black),
            ),
            hintText: ReferencePersonLn10.neighborhoodPlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
