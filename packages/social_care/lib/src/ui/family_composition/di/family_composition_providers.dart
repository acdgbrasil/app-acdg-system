import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/family_composition_view_model.dart';

/// Riverpod provider for [FamilyCompositionViewModel], scoped by patientId.
///
/// Must be overridden in the shell's [ProviderScope] with the actual
/// implementation that wires the use cases and repository.
final familyCompositionViewModelProvider = Provider.autoDispose
    .family<FamilyCompositionViewModel, String>(
  (ref, patientId) {
    throw UnimplementedError(
      'familyCompositionViewModelProvider must be overridden in ProviderScope',
    );
  },
);
