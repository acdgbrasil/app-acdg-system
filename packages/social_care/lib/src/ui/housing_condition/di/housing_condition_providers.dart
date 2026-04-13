import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/housing_condition_view_model.dart';

/// Riverpod provider for [HousingConditionViewModel], scoped by patientId.
///
/// Must be overridden in the shell's [ProviderScope] with the actual
/// implementation that wires the use cases and repository.
final housingConditionViewModelProvider = Provider.autoDispose
    .family<HousingConditionViewModel, String>((ref, patientId) {
      throw UnimplementedError(
        'housingConditionViewModelProvider must be overridden in ProviderScope',
      );
    });
