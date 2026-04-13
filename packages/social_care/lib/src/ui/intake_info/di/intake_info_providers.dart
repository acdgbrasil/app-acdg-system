import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/intake_info_view_model.dart';

/// Riverpod provider for [IntakeInfoViewModel], scoped by patientId.
///
/// Must be overridden in the shell's [ProviderScope] with the actual
/// implementation that wires the use cases and repository.
final intakeInfoViewModelProvider = Provider.autoDispose
    .family<IntakeInfoViewModel, String>((ref, patientId) {
      throw UnimplementedError(
        'intakeInfoViewModelProvider must be overridden in ProviderScope',
      );
    });
