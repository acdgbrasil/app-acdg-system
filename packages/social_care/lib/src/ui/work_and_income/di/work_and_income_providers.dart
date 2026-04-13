import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/work_and_income_view_model.dart';

final workAndIncomeViewModelProvider = Provider.autoDispose
    .family<WorkAndIncomeViewModel, String>((ref, patientId) {
      throw UnimplementedError(
        'workAndIncomeViewModelProvider must be overridden in ProviderScope',
      );
    });
