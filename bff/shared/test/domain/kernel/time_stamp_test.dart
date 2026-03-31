import 'package:core/core.dart';
import 'package:shared/src/domain/kernel/time_stamp.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('TimeStamp - Validações', () {
    test('Deve criar TimeStamp válido a partir de Date', () {
      final dt = DateTime(2025, 1, 1).toUtc();
      final result = TimeStamp.fromDate(dt);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.date, dt);
    });

    test('Deve rejeitar Date nulo', () {
      final result = TimeStamp.fromDate(null);
      expect(result.isFailure, isTrue);
      final error = (result as Failure).error as AppError;
      expect(error.code, 'TS-001');
      expect(error.kind, 'invalidDate');
    });

    test('Deve criar a partir de ISO string e manter formato', () {
      final iso = '2026-03-12T10:30:00.000Z';
      final result = TimeStamp.fromIso(iso);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.toISOString(), iso);
    });

    test('Deve rejeitar ISO string inválida', () {
      final result = TimeStamp.fromIso('not-a-date');
      expect(result.isFailure, isTrue);
      final error = (result as Failure).error as AppError;
      expect(error.code, 'TS-001');
    });

    test('isSameDay compara dias corretamente em UTC', () {
      final t1 = TimeStamp.fromIso('2026-03-12T10:30:00.000Z').valueOrNull!;
      final t2 = TimeStamp.fromIso('2026-03-12T23:59:59.000Z').valueOrNull!;
      final t3 = TimeStamp.fromIso('2026-03-13T00:00:00.000Z').valueOrNull!;

      expect(t1.isSameDay(t2), isTrue);
      expect(t1.isSameDay(t3), isFalse);
    });

    test('yearsAt calcula idade corretamente considerando meses/dias', () {
      final birth = TimeStamp.fromIso('2000-05-15T00:00:00.000Z').valueOrNull!;

      final beforeBirthday = TimeStamp.fromIso(
        '2020-05-14T00:00:00.000Z',
      ).valueOrNull!;
      expect(birth.yearsAt(referenceDate: beforeBirthday), 19);

      final onBirthday = TimeStamp.fromIso(
        '2020-05-15T00:00:00.000Z',
      ).valueOrNull!;
      expect(birth.yearsAt(referenceDate: onBirthday), 20);

      final afterBirthday = TimeStamp.fromIso(
        '2020-06-10T00:00:00.000Z',
      ).valueOrNull!;
      expect(birth.yearsAt(referenceDate: afterBirthday), 20);
    });

    test('Implementa Comparable', () {
      final t1 = TimeStamp.fromIso('2025-01-01T00:00:00.000Z').valueOrNull!;
      final t2 = TimeStamp.fromIso('2026-01-01T00:00:00.000Z').valueOrNull!;
      expect(t1.compareTo(t2) < 0, isTrue);
      expect(t2.compareTo(t1) > 0, isTrue);
      expect(t1.compareTo(t1) == 0, isTrue);
    });
  });
}
