import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('FakePeopleBff', () {
    test('implements PeopleContract', () {
      final PeopleContract fake = FakePeopleBff();
      expect(fake, isA<PeopleContract>());
    });

    test('registerPerson + getPerson: state preserved', () async {
      final fake = FakePeopleBff();
      const request = RegisterPersonRequest(
        fullName: 'Maria Silva',
        birthDate: '1990-01-01',
      );

      final createResult = await fake.registerPerson(request);
      expect(createResult, isA<Success<StandardIdResponse>>());

      final createdId = switch (createResult) {
        Success(:final value) => value.data.id,
        Failure() => '',
      };
      expect(createdId, isNotEmpty);

      final getResult = await fake.getPerson(createdId);
      expect(getResult, isA<Success<PersonResponse>>());
      switch (getResult) {
        case Success(:final value):
          expect(value.id, equals(createdId));
          expect(value.fullName, equals('Maria Silva'));
        case Failure():
          fail('getPerson should return the person registered earlier');
      }
    });
  });
}
