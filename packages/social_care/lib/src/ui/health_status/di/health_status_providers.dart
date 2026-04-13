import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/health_status_view_model.dart';

/// Riverpod provider for [HealthStatusViewModel], scoped by patientId.
///
/// Must be overridden in the shell's [ProviderScope] with the actual
/// implementation that wires the use cases and repository.
final healthStatusViewModelProvider = Provider.autoDispose
    .family<HealthStatusViewModel, String>((ref, patientId) {
      throw UnimplementedError(
        'healthStatusViewModelProvider must be overridden in ProviderScope',
      );
    });
