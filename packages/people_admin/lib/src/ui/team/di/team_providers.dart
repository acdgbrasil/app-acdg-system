import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/people_list_view_model.dart';
import '../view_models/person_detail_view_model.dart';

/// Note: Provider scoping here uses 'autoDispose' depending on if we want state
/// to live beyond the shell's lifecycle. We stick to typical Riverpod for DI 
/// injection down to the UI layers.

final peopleListViewModelProvider = Provider.autoDispose<PeopleListViewModel>((ref) {
  throw UnimplementedError('peopleListViewModelProvider must be overridden');
});

final personDetailViewModelProvider = Provider.autoDispose<PersonDetailViewModel>((ref) {
  throw UnimplementedError('personDetailViewModelProvider must be overridden');
});
