import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/social_identity_view_model.dart';

final socialIdentityViewModelProvider = Provider.autoDispose
    .family<SocialIdentityViewModel, String>((ref, patientId) {
      throw UnimplementedError(
        'socialIdentityViewModelProvider must be overridden in ProviderScope',
      );
    });
