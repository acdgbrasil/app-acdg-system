import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/community_support_view_model.dart';

final communitySupportViewModelProvider = Provider.autoDispose
    .family<CommunitySupportViewModel, String>((ref, patientId) {
      throw UnimplementedError(
        'communitySupportViewModelProvider must be overridden in ProviderScope',
      );
    });
