import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/session_store.dart';
import 'handler_utils.dart';

/// Factory that creates a [SocialCareContract] for a given [Session].
typedef LookupContractFactory = SocialCareContract Function(Session session);

/// Handles lookup table endpoints.
///
/// Routes:
/// - `GET /lookups/<tableName>` — fetch lookup table entries
class LookupHandler {
  LookupHandler({required LookupContractFactory contractFactory})
    : _contractFactory = contractFactory;

  final LookupContractFactory _contractFactory;

  Router get router {
    final r = Router();
    r.get('/lookups/<tableName>', _getLookupTable);
    return r;
  }

  Future<Response> _getLookupTable(Request request, String tableName) async {
    print('[BFF:Lookup] GET /lookups/$tableName — ENTER');
    final session = getSession(request);
    final tokenSnippet = session.accessToken.isEmpty
        ? 'EMPTY'
        : '${session.accessToken.substring(0, 15)}...';
    print(
      '[BFF:Lookup] GET /lookups/$tableName — '
      'userId=${session.userId}, token=$tokenSnippet, expired=${session.isExpired()}',
    );
    final contract = _contractFactory(session);
    final result = await contract.getLookupTable(tableName);
    print(
      '[BFF:Lookup] GET /lookups/$tableName — '
      'result=${result.isSuccess ? "SUCCESS" : "FAIL"}',
    );

    return switch (result) {
      Success(:final value) => jsonOk({
        'data': value.data,
        'meta': {'timestamp': value.meta.timestamp},
      }),
      Failure(:final error) => backendError(error),
    };
  }
}
