/// Social Care BFF — typed proxy to the social-care API.
///
/// Provides [SocialCareContract] as the abstract interface consumed by
/// Flutter micro-apps, and [InProcessBff] as the concrete implementation
/// for desktop (in-process) usage.
library;

export 'src/api_client/social_care_api_client.dart';
export 'src/contract/dto/requests/assessment_requests.dart';
export 'src/contract/dto/requests/care_requests.dart';
export 'src/contract/dto/requests/protection_requests.dart';
export 'src/contract/dto/requests/registry_requests.dart';
export 'src/contract/dto/responses/assessment_responses.dart';
export 'src/contract/dto/responses/care_responses.dart';
export 'src/contract/dto/responses/common_responses.dart';
export 'src/contract/dto/responses/protection_responses.dart';
export 'src/contract/dto/responses/registry_responses.dart';
export 'src/contract/social_care_contract.dart';
export 'src/impl/in_process_bff.dart';
export 'src/models/value_objects/cep.dart';
export 'src/models/value_objects/cpf.dart';
export 'src/models/value_objects/nis.dart';
