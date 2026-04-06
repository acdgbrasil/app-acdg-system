import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_section_title.dart';

class ReferralDetailsForm extends StatelessWidget {
  final TextEditingController originNameController;
  final TextEditingController originContactController;

  const ReferralDetailsForm({
    super.key,
    required this.originNameController,
    required this.originContactController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RegistrationSectionTitle(
          ReferencePersonLn10.sectionReferralDetails,
        ),
        TextField(
          controller: originNameController,
          decoration: const InputDecoration(
            labelText: ReferencePersonLn10.originNameLabel,
            hintText: ReferencePersonLn10.originNamePlaceholder,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: originContactController,
          decoration: const InputDecoration(
            labelText: ReferencePersonLn10.originContactLabel,
            hintText: ReferencePersonLn10.originContactPlaceholder,
          ),
        ),
      ],
    );
  }
}
