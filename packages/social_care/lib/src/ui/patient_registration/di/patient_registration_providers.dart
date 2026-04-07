import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewModel/patient_registration_view_model.dart';

/// Riverpod provider for [PatientRegistrationViewModel].
///
/// Must be overridden in the shell's [ProviderScope] with the actual
/// implementation that wires the use case and repository.
final patientRegistrationViewModelProvider =
    Provider.autoDispose<PatientRegistrationViewModel>((ref) {
      throw UnimplementedError(
        'patientRegistrationViewModelProvider must be overridden in ProviderScope',
      );
    });
