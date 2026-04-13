import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/educational_status_view_model.dart';

final educationalStatusViewModelProvider = Provider.autoDispose
    .family<EducationalStatusViewModel, String>((ref, patientId) {
      throw UnimplementedError(
        'educationalStatusViewModelProvider must be overridden in ProviderScope',
      );
    });
