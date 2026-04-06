# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2026-04-06

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`acdg_system` - `v0.1.1`](#acdg_system---v011)
 - [`auth` - `v0.1.1`](#auth---v011)
 - [`core` - `v0.1.1`](#core---v011)
 - [`design_system` - `v0.1.1`](#design_system---v011)
 - [`network` - `v0.1.1`](#network---v011)
 - [`persistence` - `v0.2.1`](#persistence---v021)
 - [`shared` - `v1.1.0`](#shared---v110)
 - [`social_care` - `v0.1.1`](#social_care---v011)
 - [`social_care_desktop` - `v1.1.0`](#social_care_desktop---v110)
 - [`social_care_web` - `v1.1.0`](#social_care_web---v110)

---

#### `acdg_system` - `v0.1.1`

 - **REFACTOR**(social_care): migrate to Riverpod, enforce SRP, and remove hardcoded colors. ([b62aa9ce](https://github.com/acdgbrasil/acdg/commit/b62aa9ce182fd50b55805a062442799208568e66))
 - **REFACTOR**(persistence,core): migrate from Isar to Drift (SQLite) and implement reactive sync. ([ea27c671](https://github.com/acdgbrasil/acdg/commit/ea27c671dbf9ab1a582cc348b8b128166fac3df0))
 - **REFACTOR**(plan): restructure implementation plan into master/sub-plans. ([6b5fc404](https://github.com/acdgbrasil/acdg/commit/6b5fc4046a6ae94a67733d4c147d9360ff38346f))
 - **FIX**: remove package:web dependency from auth to allow desktop tests to pass without js_interop errors. ([e7e57c6e](https://github.com/acdgbrasil/acdg/commit/e7e57c6e0c779c3cf336d7cdce9942607d4926e7))
 - **FIX**: remove persistence transitive dependency from shared package. ([df267ed6](https://github.com/acdgbrasil/acdg/commit/df267ed69957884bfe71ade8d9c94e462725da37))
 - **FIX**: family composition bugs and UX improvements. ([642a130c](https://github.com/acdgbrasil/acdg/commit/642a130c92436d990b23f2935de6914cab002cd5))
 - **FIX**: auth bootstrap deadlock and sync indicator visibility. ([1cdc95ed](https://github.com/acdgbrasil/acdg/commit/1cdc95ed179fbe7dd9cbac6cc26f6896782f2a51))
 - **FEAT**: 🔄 refactor storage logic and implement offline-first sync engine. ([55713c15](https://github.com/acdgbrasil/acdg/commit/55713c15d9553a7c1dcfd7410f6fbc655207c49e))
 - **FEAT**: configure Windows MSIX build pipeline and app dependencies. ([83834bc5](https://github.com/acdgbrasil/acdg/commit/83834bc511fe5be27f6d647367bb4b1bc84b3b13))
 - **FEAT**(offline): setup isar native libs and enhance integration tests. ([5cc9901b](https://github.com/acdgbrasil/acdg/commit/5cc9901b3389d4d61ae68bd5fc1d66d2945e680c))
 - **FEAT**(social-care): implement complete offline engine with local-first strategy. ([1bae9821](https://github.com/acdgbrasil/acdg/commit/1bae98218281f4befb5f6ae1c8c53ef2a42408e5))
 - **FEAT**(staging): implement and validate Social Identity update. ([911c5696](https://github.com/acdgbrasil/acdg/commit/911c5696dfc134e739b25ee3f7cc40aef0a27584))
 - **FEAT**(staging): implement and validate full Registry lifecycle (Family/Caregiver). ([03b9e2c4](https://github.com/acdgbrasil/acdg/commit/03b9e2c457bda0bc233c067ae6aaac82dada3783))
 - **FEAT**(staging): finalize end-to-end integration with HML environment. ([7fd7cbf0](https://github.com/acdgbrasil/acdg/commit/7fd7cbf02beb0460e934b9f55bb34047ff3c9e5d))
 - **FEAT**(integration): establish staging integration tests and OIDC guide. ([0f22ed1f](https://github.com/acdgbrasil/acdg/commit/0f22ed1f69d0a03a10a21a532f523bfef918986f))
 - **FEAT**(core): internalize equatable engine and add command pattern. ([18f688a7](https://github.com/acdgbrasil/acdg/commit/18f688a7288a6c1ce8382c1f14ab69e946a24ae1))

#### `auth` - `v0.1.1`

 - **FIX**: remove package:web dependency from auth to allow desktop tests to pass without js_interop errors. ([e7e57c6e](https://github.com/acdgbrasil/acdg/commit/e7e57c6e0c779c3cf336d7cdce9942607d4926e7))
 - **FIX**: family composition bugs and UX improvements. ([642a130c](https://github.com/acdgbrasil/acdg/commit/642a130c92436d990b23f2935de6914cab002cd5))
 - **FIX**: auth bootstrap deadlock and sync indicator visibility. ([1cdc95ed](https://github.com/acdgbrasil/acdg/commit/1cdc95ed179fbe7dd9cbac6cc26f6896782f2a51))
 - **FEAT**(auth): implement OIDC service and refactor auth models. ([b70f510e](https://github.com/acdgbrasil/acdg/commit/b70f510e4a03a5b22b71d31adc81f1ad2d691e8a))
 - **FEAT**(social-care): implement complete offline engine with local-first strategy. ([1bae9821](https://github.com/acdgbrasil/acdg/commit/1bae98218281f4befb5f6ae1c8c53ef2a42408e5))
 - **FEAT**(core): internalize equatable engine and add command pattern. ([18f688a7](https://github.com/acdgbrasil/acdg/commit/18f688a7288a6c1ce8382c1f14ab69e946a24ae1))

#### `core` - `v0.1.1`

 - **REFACTOR**(persistence,core): migrate from Isar to Drift (SQLite) and implement reactive sync. ([ea27c671](https://github.com/acdgbrasil/acdg/commit/ea27c671dbf9ab1a582cc348b8b128166fac3df0))
 - **REFACTOR**(core): implement structured logging, UUID utils, and improved Result type. ([4babb010](https://github.com/acdgbrasil/acdg/commit/4babb0105a81c7bf7e3979f92a6da8f8393adbc8))
 - **REFACTOR**(plan): restructure implementation plan into master/sub-plans. ([6b5fc404](https://github.com/acdgbrasil/acdg/commit/6b5fc4046a6ae94a67733d4c147d9360ff38346f))
 - **FIX**: remove persistence transitive dependency from shared package. ([df267ed6](https://github.com/acdgbrasil/acdg/commit/df267ed69957884bfe71ade8d9c94e462725da37))
 - **FEAT**(social-care): implement complete offline engine with local-first strategy. ([1bae9821](https://github.com/acdgbrasil/acdg/commit/1bae98218281f4befb5f6ae1c8c53ef2a42408e5))
 - **FEAT**(staging): finalize end-to-end integration with HML environment. ([7fd7cbf0](https://github.com/acdgbrasil/acdg/commit/7fd7cbf02beb0460e934b9f55bb34047ff3c9e5d))
 - **FEAT**(integration): establish staging integration tests and OIDC guide. ([0f22ed1f](https://github.com/acdgbrasil/acdg/commit/0f22ed1f69d0a03a10a21a532f523bfef918986f))
 - **FEAT**(core): internalize equatable engine and add command pattern. ([18f688a7](https://github.com/acdgbrasil/acdg/commit/18f688a7288a6c1ce8382c1f14ab69e946a24ae1))
 - **FEAT**: add Shell + Auth with Zitadel OIDC PKCE (Fase 2). ([f4c59c69](https://github.com/acdgbrasil/acdg/commit/f4c59c69a2aa54073fe23949293596af23067a72))

#### `design_system` - `v0.1.1`

 - **REFACTOR**(social_care): migrate to Riverpod, enforce SRP, and remove hardcoded colors. ([b62aa9ce](https://github.com/acdgbrasil/acdg/commit/b62aa9ce182fd50b55805a062442799208568e66))
 - **REFACTOR**(social_care): implement full PatientDetail MVVM flow with atomic widgets. ([c458f8b9](https://github.com/acdgbrasil/acdg/commit/c458f8b92efdb5d1bda3ac87772e2a4c8e30229d))
 - **FIX**: auth bootstrap deadlock and sync indicator visibility. ([1cdc95ed](https://github.com/acdgbrasil/acdg/commit/1cdc95ed179fbe7dd9cbac6cc26f6896782f2a51))
 - **FEAT**(core): internalize equatable engine and add command pattern. ([18f688a7](https://github.com/acdgbrasil/acdg/commit/18f688a7288a6c1ce8382c1f14ab69e946a24ae1))
 - **FEAT**: add Shell + Auth with Zitadel OIDC PKCE (Fase 2). ([f4c59c69](https://github.com/acdgbrasil/acdg/commit/f4c59c69a2aa54073fe23949293596af23067a72))

#### `network` - `v0.1.1`

 - **REFACTOR**(core): implement structured logging, UUID utils, and improved Result type. ([4babb010](https://github.com/acdgbrasil/acdg/commit/4babb0105a81c7bf7e3979f92a6da8f8393adbc8))
 - **REFACTOR**(plan): restructure implementation plan into master/sub-plans. ([6b5fc404](https://github.com/acdgbrasil/acdg/commit/6b5fc4046a6ae94a67733d4c147d9360ff38346f))
 - **FEAT**(social-care): implement complete offline engine with local-first strategy. ([1bae9821](https://github.com/acdgbrasil/acdg/commit/1bae98218281f4befb5f6ae1c8c53ef2a42408e5))
 - **FEAT**(integration): establish staging integration tests and OIDC guide. ([0f22ed1f](https://github.com/acdgbrasil/acdg/commit/0f22ed1f69d0a03a10a21a532f523bfef918986f))
 - **FEAT**(core): internalize equatable engine and add command pattern. ([18f688a7](https://github.com/acdgbrasil/acdg/commit/18f688a7288a6c1ce8382c1f14ab69e946a24ae1))

#### `persistence` - `v0.2.1`

 - **REFACTOR**(persistence,core): migrate from Isar to Drift (SQLite) and implement reactive sync. ([ea27c671](https://github.com/acdgbrasil/acdg/commit/ea27c671dbf9ab1a582cc348b8b128166fac3df0))
 - **REFACTOR**(core): implement structured logging, UUID utils, and improved Result type. ([4babb010](https://github.com/acdgbrasil/acdg/commit/4babb0105a81c7bf7e3979f92a6da8f8393adbc8))
 - **FEAT**(social-care): implement complete offline engine with local-first strategy. ([1bae9821](https://github.com/acdgbrasil/acdg/commit/1bae98218281f4befb5f6ae1c8c53ef2a42408e5))

#### `shared` - `v1.1.0`

 - **REFACTOR**(social_care): migrate to Riverpod, enforce SRP, and remove hardcoded colors. ([b62aa9ce](https://github.com/acdgbrasil/acdg/commit/b62aa9ce182fd50b55805a062442799208568e66))
 - **REFACTOR**(shared): update analytics services with proper domain logic. ([892243f8](https://github.com/acdgbrasil/acdg/commit/892243f83e5a941bcb1bc69ee55c2db884e97f50))
 - **FIX**: family composition bugs and UX improvements. ([642a130c](https://github.com/acdgbrasil/acdg/commit/642a130c92436d990b23f2935de6914cab002cd5))
 - **FIX**: auth bootstrap deadlock and sync indicator visibility. ([1cdc95ed](https://github.com/acdgbrasil/acdg/commit/1cdc95ed179fbe7dd9cbac6cc26f6896782f2a51))
 - **FIX**(shared): correct PatientMapper serialization, missing fields (CNS, IDs) and violationTypeId mapping. ([157adbc8](https://github.com/acdgbrasil/acdg/commit/157adbc8d98fda2c26c43c2c5eb66e9378bd7f93))
 - **FIX**(shared): correct enum mapping casing and Portuguese strings regression. ([ff8fed68](https://github.com/acdgbrasil/acdg/commit/ff8fed686616867edca299096b9ae9633ff81bab))
 - **FEAT**: 🔄 refactor storage logic and implement offline-first sync engine. ([55713c15](https://github.com/acdgbrasil/acdg/commit/55713c15d9553a7c1dcfd7410f6fbc655207c49e))
 - **FEAT**(shared): update kernel VOs and social care contracts with full mapping support. ([a097138f](https://github.com/acdgbrasil/acdg/commit/a097138fde6eeea23422121c81d7783facd19505))
 - **FEAT**(social-care): implement complete offline engine with local-first strategy. ([1bae9821](https://github.com/acdgbrasil/acdg/commit/1bae98218281f4befb5f6ae1c8c53ef2a42408e5))
 - **FEAT**(staging): implement and validate full Registry lifecycle (Family/Caregiver). ([03b9e2c4](https://github.com/acdgbrasil/acdg/commit/03b9e2c457bda0bc233c067ae6aaac82dada3783))
 - **FEAT**(staging): finalize end-to-end integration with HML environment. ([7fd7cbf0](https://github.com/acdgbrasil/acdg/commit/7fd7cbf02beb0460e934b9f55bb34047ff3c9e5d))
 - **FEAT**(bff): implement shared kernel with VOs, models and contract. ([ceb7023a](https://github.com/acdgbrasil/acdg/commit/ceb7023a25ee7377eadd9c3d11e159138e1c71d8))

#### `social_care` - `v0.1.1`

 - **REFACTOR**(social_care): migrate to Riverpod, enforce SRP, and remove hardcoded colors. ([b62aa9ce](https://github.com/acdgbrasil/acdg/commit/b62aa9ce182fd50b55805a062442799208568e66))
 - **REFACTOR**(social_care): simplify HomeViewModel and remove UI domain leaks. ([360fad02](https://github.com/acdgbrasil/acdg/commit/360fad02dad627fb2fa02442b955f1ef17affef9))
 - **REFACTOR**(social_care): update GetPatientUseCase to handle string input and result bundle. ([a81b73ca](https://github.com/acdgbrasil/acdg/commit/a81b73ca98ee8fed8e890316f6cc6fbc38ac0e06))
 - **REFACTOR**(social_care): update repository and implement domain-to-UI mapping. ([ff16f886](https://github.com/acdgbrasil/acdg/commit/ff16f886049213669f0503ffcc747a0932823d98))
 - **REFACTOR**(social_care): decouple PatientDetail and FichaStatus from domain. ([f2bce450](https://github.com/acdgbrasil/acdg/commit/f2bce450195432f460ee2142762f0b8155bd6c82))
 - **REFACTOR**(social_care): implement full PatientDetail MVVM flow with atomic widgets. ([c458f8b9](https://github.com/acdgbrasil/acdg/commit/c458f8b92efdb5d1bda3ac87772e2a4c8e30229d))
 - **REFACTOR**(social_care): refactor repositories and implement PatientService for remote BFF. ([bf9277e3](https://github.com/acdgbrasil/acdg/commit/bf9277e3685e9578836c04c06422719e1249621c))
 - **FIX**: family composition bugs and UX improvements. ([642a130c](https://github.com/acdgbrasil/acdg/commit/642a130c92436d990b23f2935de6914cab002cd5))
 - **FIX**(social_care): resolve mapping bugs and age calculation found in code review. ([ea8897e6](https://github.com/acdgbrasil/acdg/commit/ea8897e69d3e9b9b73b651a89182fe993eb3f20e))
 - **FIX**(shared): correct PatientMapper serialization, missing fields (CNS, IDs) and violationTypeId mapping. ([157adbc8](https://github.com/acdgbrasil/acdg/commit/157adbc8d98fda2c26c43c2c5eb66e9378bd7f93))
 - **FEAT**: ✨ refactor patient registration flow and improve family composition UI. ([cd59e276](https://github.com/acdgbrasil/acdg/commit/cd59e2766d7a29ddc5fd48749fec0fa315832087))
 - **FEAT**(social_care): add getPatient to PatientService and update api models. ([0924792b](https://github.com/acdgbrasil/acdg/commit/0924792b25cfe1bbcbcfca63dc63129cedb2b303))
 - **FEAT**(social_care): init modular architecture for Phase 5 (UI ↔ UseCase ↔ BFF ↔ INFRA). ([6dc90fc9](https://github.com/acdgbrasil/acdg/commit/6dc90fc90084d34470f0b83d9741097955be24f0))

#### `social_care_desktop` - `v1.1.0`

 - **REFACTOR**(social_care): migrate to Riverpod, enforce SRP, and remove hardcoded colors. ([b62aa9ce](https://github.com/acdgbrasil/acdg/commit/b62aa9ce182fd50b55805a062442799208568e66))
 - **REFACTOR**(persistence,core): migrate from Isar to Drift (SQLite) and implement reactive sync. ([ea27c671](https://github.com/acdgbrasil/acdg/commit/ea27c671dbf9ab1a582cc348b8b128166fac3df0))
 - **FIX**: remove persistence transitive dependency from shared package. ([df267ed6](https://github.com/acdgbrasil/acdg/commit/df267ed69957884bfe71ade8d9c94e462725da37))
 - **FIX**: family composition bugs and UX improvements. ([642a130c](https://github.com/acdgbrasil/acdg/commit/642a130c92436d990b23f2935de6914cab002cd5))
 - **FIX**: auth bootstrap deadlock and sync indicator visibility. ([1cdc95ed](https://github.com/acdgbrasil/acdg/commit/1cdc95ed179fbe7dd9cbac6cc26f6896782f2a51))
 - **FIX**(bff): resolve critical offline-first cache bugs and improve sync reliability. ([7844c6bf](https://github.com/acdgbrasil/acdg/commit/7844c6bfe8909928f074332760da7a9e31014ea7))
 - **FEAT**: 🔄 refactor storage logic and implement offline-first sync engine. ([55713c15](https://github.com/acdgbrasil/acdg/commit/55713c15d9553a7c1dcfd7410f6fbc655207c49e))
 - **FEAT**(social-care): implement complete offline engine with local-first strategy. ([1bae9821](https://github.com/acdgbrasil/acdg/commit/1bae98218281f4befb5f6ae1c8c53ef2a42408e5))
 - **FEAT**(staging): implement and validate Social Identity update. ([911c5696](https://github.com/acdgbrasil/acdg/commit/911c5696dfc134e739b25ee3f7cc40aef0a27584))
 - **FEAT**(staging): implement and validate full Registry lifecycle (Family/Caregiver). ([03b9e2c4](https://github.com/acdgbrasil/acdg/commit/03b9e2c457bda0bc233c067ae6aaac82dada3783))
 - **FEAT**(staging): finalize end-to-end integration with HML environment. ([7fd7cbf0](https://github.com/acdgbrasil/acdg/commit/7fd7cbf02beb0460e934b9f55bb34047ff3c9e5d))
 - **FEAT**(bff): implement shared kernel with VOs, models and contract. ([ceb7023a](https://github.com/acdgbrasil/acdg/commit/ceb7023a25ee7377eadd9c3d11e159138e1c71d8))

#### `social_care_web` - `v1.1.0`

 - **FEAT**(bff): implement shared kernel with VOs, models and contract. ([ceb7023a](https://github.com/acdgbrasil/acdg/commit/ceb7023a25ee7377eadd9c3d11e159138e1c71d8))

