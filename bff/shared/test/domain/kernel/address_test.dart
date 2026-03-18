import 'package:core/core.dart';
import 'package:shared/src/domain/kernel/address.dart';
import 'package:shared/src/domain/kernel/cep.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('Address - Validações', () {
    test('Deve criar endereço válido sem CEP', () {
      final result = Address.create(
        state: '  sp  ',
        city: '  São   Paulo  ',
        street: 'Rua Teste',
        residenceLocation: ResidenceLocation.urbano,
        isShelter: false,
      );

      expect(result.isSuccess, isTrue);
      final addr = result.valueOrNull!;
      expect(addr.state, 'SP');
      expect(addr.city, 'São Paulo');
      expect(addr.cep, isNull);
    });

    test('Deve rejeitar estado inválido', () {
      final result = Address.create(
        state: 'XX',
        city: 'São Paulo',
        residenceLocation: ResidenceLocation.urbano,
        isShelter: false,
      );

      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'ADR-003');
    });

    test('Deve rejeitar cidade vazia', () {
      final result = Address.create(
        state: 'SP',
        city: '   ',
        residenceLocation: ResidenceLocation.urbano,
        isShelter: false,
      );

      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'ADR-004');
    });
  });
}
