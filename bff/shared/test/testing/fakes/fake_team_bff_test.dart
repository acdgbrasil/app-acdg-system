import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('FakeTeamBff', () {
    test('implements TeamContract', () {
      final TeamContract fake = FakeTeamBff();
      expect(fake, isA<TeamContract>());
    });

    test('registerWorker + listTeam: state preserved', () async {
      final fake = FakeTeamBff();
      const request = RegisterPersonWithLoginRequest(
        fullName: 'Ana Assistente',
        birthDate: '1985-05-20',
        email: 'ana@acdgbrasil.com.br',
      );

      final registerResult = await fake.registerWorker(request);
      expect(registerResult, isA<Success<StandardIdResponse>>());

      final listResult = await fake.listTeam();
      expect(
        listResult,
        isA<Success<StandardResponse<List<TeamMemberResponse>>>>(),
      );
      switch (listResult) {
        case Success(:final value):
          expect(value.data, hasLength(1));
          expect(value.data.first.fullName, equals('Ana Assistente'));
          expect(value.data.first.email, equals('ana@acdgbrasil.com.br'));
        case Failure():
          fail('listTeam should return the registered worker');
      }
    });
  });
}
