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
    final session = getSession(request);
    final contract = _contractFactory(session);
    final result = await contract.getLookupTable(tableName);

    return switch (result) {
      Success(:final value) => jsonOk(
        value
            .map(
              (item) => {
                'id': item.id,
                'codigo': item.codigo,
                'descricao': item.descricao,
              },
            )
            .toList(),
      ),
      Failure(:final error) => jsonError(500, error.toString()),
    };
  }
}
