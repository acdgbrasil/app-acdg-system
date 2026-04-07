import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewModel/home_view_model.dart';

/// Riverpod provider for [HomeViewModel].
///
/// Must be overridden in the shell's [ProviderScope] with the actual
/// implementation that wires the use cases.
final homeViewModelProvider = Provider.autoDispose<HomeViewModel>((ref) {
  throw UnimplementedError(
    'homeViewModelProvider must be overridden in ProviderScope',
  );
});
