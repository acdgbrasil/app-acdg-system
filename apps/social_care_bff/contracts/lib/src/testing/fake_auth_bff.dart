import 'package:core_contracts/core_contracts.dart';

import '../contract/dto/responses/auth/me_response.dart';
import '../contract/dto/shared/standard_response.dart';
import '../contract/sub_contracts/auth_contract.dart';

/// In-memory fake for [AuthContract] — used in tests and local simulation.
///
/// Mocks the OIDC lifecycle without talking to Zitadel. The fake keeps no
/// multi-collection state — only two configurable response values
/// ([redirectUrl], [currentMe]) that tests can override via the
/// constructor or [setMe].
class FakeAuthBff implements AuthContract {
  FakeAuthBff({
    this.redirectUrl = 'https://fake-idp.local/authorize?state=fake',
    MeResponse? me,
  }) : currentMe = me ??
            const MeResponse(
              userId: 'fake-user-id',
              email: 'fake@acdgbrasil.com.br',
              fullName: 'Fake User',
              roles: <String>['social_worker'],
            );

  final String redirectUrl;

  /// Current [MeResponse] returned by [me]. Mutable so tests can change
  /// the user mid-test via [setMe].
  MeResponse currentMe;

  /// Replaces the [MeResponse] returned by [AuthContract.me].
  void setMe(MeResponse next) {
    currentMe = next;
  }

  StandardResponse<T> _wrap<T>(T data) => StandardResponse(
    data: data,
    meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
  );

  @override
  Future<Result<String>> login() async => Success(redirectUrl);

  @override
  Future<Result<StandardResponse<void>>> callback({
    required String code,
    required String state,
  }) async => Success(_wrap(null));

  @override
  Future<Result<StandardResponse<void>>> logout() async => Success(_wrap(null));

  @override
  Future<Result<StandardResponse<void>>> refresh() async => Success(_wrap(null));

  @override
  Future<Result<StandardResponse<MeResponse>>> me() async =>
      Success(_wrap(currentMe));
}
