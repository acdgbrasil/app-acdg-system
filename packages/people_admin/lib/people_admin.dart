/// People Admin module — team management for the ACDG ecosystem.
library;

// Data — Repositories
export 'src/data/repositories/bff_people_repository.dart';
export 'src/data/repositories/bff_role_repository.dart';
export 'src/data/repositories/people_repository.dart';
export 'src/data/repositories/role_repository.dart';
// Data — Services
export 'src/data/services/people_admin_client.dart';
// Domain — Errors
export 'src/domain/errors/team_errors.dart';
// Domain — Models
export 'src/domain/models/paginated_result.dart';
export 'src/domain/models/person.dart';
export 'src/domain/models/register_worker_intent.dart';
export 'src/domain/models/system_role.dart';
export 'src/domain/models/team_member.dart';
// Logic — Use Cases
export 'src/logic/use_case/get_person_use_case.dart';
export 'src/logic/use_case/manage_roles_use_case.dart';
export 'src/logic/use_case/reset_password_use_case.dart';
export 'src/logic/use_case/register_worker_use_case.dart';
export 'src/logic/use_case/search_people_use_case.dart';
export 'src/logic/use_case/toggle_person_status_use_case.dart';
// UI — DI
export 'src/ui/team/di/team_providers.dart';
// UI — Pages
export 'src/ui/team/view/page/people_admin_shell.dart';
// UI — ViewModels
export 'src/ui/team/view_models/people_list_view_model.dart';
export 'src/ui/team/view_models/person_detail_view_model.dart';
