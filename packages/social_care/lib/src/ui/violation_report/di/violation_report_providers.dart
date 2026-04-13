import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/violation_report_view_model.dart';

final violationReportViewModelProvider = Provider.autoDispose
    .family<ViolationReportViewModel, String>((ref, patientId) {
      throw UnimplementedError(
        'violationReportViewModelProvider must be overridden in ProviderScope',
      );
    });
