import 'package:flutter/foundation.dart';
import 'package:social_care/src/ui/home/models/ficha_status.dart';
import 'package:social_care/src/ui/home/models/patient_detail.dart';

class DetailPanelState {
  final selectedPatientId = ValueNotifier<String?>(null);
  final panelVisible = ValueNotifier<bool>(false);
  final panelView = ValueNotifier<String>('dados');
  final patientDetail = ValueNotifier<PatientDetail?>(null);
  final fichas = ValueNotifier<List<FichaStatus>>([]);

  void selectPatient(String id) {
    if (selectedPatientId.value == id) {
      closePanel();
      return;
    }
    selectedPatientId.value = id;
    panelView.value = 'dados';
    panelVisible.value = true;
  }

  void closePanel() {
    panelVisible.value = false;
    // Delay clearing data so slide-out animation completes
    Future.delayed(const Duration(milliseconds: 350), () {
      selectedPatientId.value = null;
      patientDetail.value = null;
      fichas.value = [];
      panelView.value = 'dados';
    });
  }

  void showFichas() => panelView.value = 'fichas';
  void showDados() => panelView.value = 'dados';

  void dispose() {
    selectedPatientId.dispose();
    panelVisible.dispose();
    panelView.dispose();
    patientDetail.dispose();
    fichas.dispose();
  }
}
