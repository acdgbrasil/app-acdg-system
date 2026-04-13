import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/socio_economic_view_model.dart';

final socioEconomicViewModelProvider = Provider.autoDispose
    .family<SocioEconomicViewModel, String>((ref, patientId) {
      throw UnimplementedError(
        'socioEconomicViewModelProvider must be overridden in ProviderScope',
      );
    });
