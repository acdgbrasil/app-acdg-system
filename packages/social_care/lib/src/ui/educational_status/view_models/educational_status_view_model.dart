import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/commands/assessment_intents.dart';
import '../../../logic/use_case/assessment/update_educational_status_use_case.dart';
import '../../../logic/use_case/registry/get_patient_use_case.dart';
import '../../../logic/use_case/shared/get_lookup_table_use_case.dart';
import '../../shared/models/member_option.dart';
import '../models/member_profile_row.dart';
import '../models/program_occurrence_row.dart';

class EducationalStatusViewModel extends BaseViewModel {
  EducationalStatusViewModel({
    required this.patientId,
    required GetPatientUseCase getPatientUseCase,
    required UpdateEducationalStatusUseCase updateEducationalStatusUseCase,
    required GetLookupTableUseCase getLookupTableUseCase,
  }) : _getPatientUseCase = getPatientUseCase,
       _updateEducationalStatusUseCase = updateEducationalStatusUseCase,
       _getLookupTableUseCase = getLookupTableUseCase {
    loadCommand = Command0<void>(_load);
    saveCommand = Command0<void>(_save);
    _loadLookups();
    print('🏗️ Created with patientId=$patientId');
  }


  final String patientId;
  final GetPatientUseCase _getPatientUseCase;
  final UpdateEducationalStatusUseCase _updateEducationalStatusUseCase;
  final GetLookupTableUseCase _getLookupTableUseCase;

  late final Command0<void> loadCommand;
  late final Command0<void> saveCommand;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String _patientName = '';
  String get patientName => _patientName;

  List<LookupItem> _educationLevelLookup = [];
  List<LookupItem> get educationLevelLookup => _educationLevelLookup;
  List<LookupItem> _effectLookup = [];
  List<LookupItem> get effectLookup => _effectLookup;

  List<MemberOption> _familyMembers = [];
  List<MemberOption> get familyMembers => _familyMembers;

  List<MemberProfileRow> _memberProfiles = [];
  List<MemberProfileRow> get memberProfiles => _memberProfiles;
  List<ProgramOccurrenceRow> _programOccurrences = [];
  List<ProgramOccurrenceRow> get programOccurrences => _programOccurrences;

  int _origProfileCount = 0;
  int _origOccurrenceCount = 0;
  bool _hasLoadedData = false;

  bool get hasData => _hasLoadedData;
  bool get canSave => _isDirty;
  bool get _isDirty =>
      _memberProfiles.length != _origProfileCount ||
      _programOccurrences.length != _origOccurrenceCount;

  void addProfile() {
    _memberProfiles = [..._memberProfiles, MemberProfileRow()];
    notifyListeners();
  }

  void removeProfile(int i) {
    _memberProfiles = List.of(_memberProfiles)..removeAt(i);
    notifyListeners();
  }

  void updateProfileMember(int i, String v) {
    _memberProfiles[i].memberId = v;
    notifyListeners();
  }

  void toggleProfileCanReadWrite(int i) {
    _memberProfiles[i].canReadWrite = !_memberProfiles[i].canReadWrite;
    notifyListeners();
  }

  void toggleProfileAttendsSchool(int i) {
    _memberProfiles[i].attendsSchool = !_memberProfiles[i].attendsSchool;
    notifyListeners();
  }

  void updateProfileEducationLevel(int i, String v) {
    _memberProfiles[i].educationLevelId = v;
    notifyListeners();
  }

  void addOccurrence() {
    _programOccurrences = [..._programOccurrences, ProgramOccurrenceRow()];
    notifyListeners();
  }

  void removeOccurrence(int i) {
    _programOccurrences = List.of(_programOccurrences)..removeAt(i);
    notifyListeners();
  }

  void updateOccurrenceMember(int i, String v) {
    _programOccurrences[i].memberId = v;
    notifyListeners();
  }

  void updateOccurrenceDate(int i, String v) {
    _programOccurrences[i].date = v;
    notifyListeners();
  }

  void updateOccurrenceEffect(int i, String v) {
    _programOccurrences[i].effectId = v;
    notifyListeners();
  }

  void toggleOccurrenceSuspension(int i) {
    _programOccurrences[i].isSuspensionRequested =
        !_programOccurrences[i].isSuspensionRequested;
    notifyListeners();
  }

  Future<void> _loadLookups() async {
    print('📋 Loading lookups...');
    final r1 = await _getLookupTableUseCase.execute(
      'dominio_nivel_escolaridade',
    );
    switch (r1) {
      case Success(:final value):
        _educationLevelLookup = value;
        print(
          '📋 Lookup loaded: dominio_nivel_escolaridade (${value.length} items)',
        );
      case Failure(:final error):
        print('📋 Lookup FAILED: dominio_nivel_escolaridade ${error}');
    }
    final r2 = await _getLookupTableUseCase.execute('dominio_efeito_programa');
    switch (r2) {
      case Success(:final value):
        _effectLookup = value;
        print(
          '📋 Lookup loaded: dominio_efeito_programa (${value.length} items)',
        );
      case Failure(:final error):
        print('📋 Lookup FAILED: dominio_efeito_programa ${error}');
    }
    notifyListeners();
  }

  Future<Result<void>> _load() async {
    print('⬇️ _load START for patient=$patientId');
    final result = await _getPatientUseCase.execute(patientId);
    switch (result) {
      case Success(:final value):
        final pd = value.personalData;
        _patientName = '${pd?.firstName ?? ''} ${pd?.lastName ?? ''}'.trim();
        final members = <MemberOption>[
          MemberOption(
            id: value.personId.value,
            label: _patientName.isNotEmpty
                ? _patientName
                : 'Pessoa de referencia',
          ),
        ];
        for (final m in value.familyMembers) {
          members.add(
            MemberOption(id: m.personId.value, label: m.fullName ?? 'Membro'),
          );
        }
        _familyMembers = members;

        final es = value.educationalStatus;
        if (es != null) {
          _memberProfiles = es.memberProfiles
              .map(
                (p) => MemberProfileRow(
                  memberId: p.memberId.value,
                  canReadWrite: p.canReadWrite,
                  attendsSchool: p.attendsSchool,
                  educationLevelId: p.educationLevelId.value.toUpperCase(),
                ),
              )
              .toList();
          _programOccurrences = es.programOccurrences
              .map(
                (o) => ProgramOccurrenceRow(
                  memberId: o.memberId.value,
                  date: o.date.date.toIso8601String().substring(0, 10),
                  effectId: o.effectId.value.toUpperCase(),
                  isSuspensionRequested: o.isSuspensionRequested,
                ),
              )
              .toList();
          _origProfileCount = _memberProfiles.length;
          _origOccurrenceCount = _programOccurrences.length;
        }
        _hasLoadedData = true;
        print(
          '⬇️ _load SUCCESS — hasData=$_hasLoadedData, patientName=$_patientName',
        );
      case Failure(:final error):
        print('⬇️ _load FAILED ${error}');
        _errorMessage = 'Falha ao carregar paciente';
    }
    notifyListeners();
    print('🔔 notifyListeners() called after _load');
    return const Success(null);
  }

  Future<Result<void>> _save() async {
    print('⬆️ _save START — canSave=$canSave');
    if (!canSave) {
      print('⬆️ _save SKIPPED — canSave is false');
      return const Success(null);
    }
    final PatientId patId;
    switch (PatientId.create(patientId)) {
      case Success(:final value):
        patId = value;
      case Failure(:final error):
        return Failure(error);
    }

    final profiles = <MemberEducationalProfile>[];
    for (final p in _memberProfiles) {
      if (p.memberId == null || p.educationLevelId == null) continue;
      final PersonId mid;
      switch (PersonId.create(p.memberId!)) {
        case Success(:final value):
          mid = value;
        case Failure(:final error):
          return Failure(error);
      }
      final LookupId lid;
      switch (LookupId.create(p.educationLevelId!)) {
        case Success(:final value):
          lid = value;
        case Failure(:final error):
          return Failure(error);
      }
      profiles.add(
        MemberEducationalProfile(
          memberId: mid,
          canReadWrite: p.canReadWrite,
          attendsSchool: p.attendsSchool,
          educationLevelId: lid,
        ),
      );
    }

    final occurrences = <ProgramOccurrence>[];
    for (final o in _programOccurrences) {
      if (o.memberId == null || o.effectId == null || o.date.isEmpty) continue;
      final PersonId mid;
      switch (PersonId.create(o.memberId!)) {
        case Success(:final value):
          mid = value;
        case Failure(:final error):
          return Failure(error);
      }
      final LookupId eid;
      switch (LookupId.create(o.effectId!)) {
        case Success(:final value):
          eid = value;
        case Failure(:final error):
          return Failure(error);
      }
      final TimeStamp ts;
      switch (TimeStamp.fromIso(o.date)) {
        case Success(:final value):
          ts = value;
        case Failure(:final error):
          return Failure(error);
      }
      occurrences.add(
        ProgramOccurrence(
          memberId: mid,
          date: ts,
          effectId: eid,
          isSuspensionRequested: o.isSuspensionRequested,
        ),
      );
    }

    final intent = UpdateEducationalStatusIntent(
      patientId: patId,
      memberProfiles: profiles,
      programOccurrences: occurrences,
    );
    final result = await _updateEducationalStatusUseCase.execute(intent);
    if (result.isSuccess) {
      print('⬆️ _save SUCCESS');
      _origProfileCount = _memberProfiles.length;
      _origOccurrenceCount = _programOccurrences.length;
      notifyListeners();
    } else {
      print('⬆️ _save FAILED ${'see error above'}');
    }
    return result;
  }

  @override
  void onDispose() {
    print('🗑️ Disposing');
    loadCommand.dispose();
    saveCommand.dispose();
  }
}
