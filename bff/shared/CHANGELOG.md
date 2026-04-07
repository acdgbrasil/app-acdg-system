## 1.2.0

 - **REFACTOR**: 🏗️  extract core_contracts package — BFF AOT compilation (2.3GB → 55MB image). ([8051b13e](https://github.com/acdgbrasil/acdg/commit/8051b13e26cfc0ad3afa771cf7be5366600f84a3))
 - **REFACTOR**(social_care): migrate to Riverpod, enforce SRP, and remove hardcoded colors. ([b62aa9ce](https://github.com/acdgbrasil/acdg/commit/b62aa9ce182fd50b55805a062442799208568e66))
 - **REFACTOR**(shared): update analytics services with proper domain logic. ([892243f8](https://github.com/acdgbrasil/acdg/commit/892243f83e5a941bcb1bc69ee55c2db884e97f50))
 - **FIX**: family composition bugs and UX improvements. ([642a130c](https://github.com/acdgbrasil/acdg/commit/642a130c92436d990b23f2935de6914cab002cd5))
 - **FIX**: auth bootstrap deadlock and sync indicator visibility. ([1cdc95ed](https://github.com/acdgbrasil/acdg/commit/1cdc95ed179fbe7dd9cbac6cc26f6896782f2a51))
 - **FIX**(shared): correct PatientMapper serialization, missing fields (CNS, IDs) and violationTypeId mapping. ([157adbc8](https://github.com/acdgbrasil/acdg/commit/157adbc8d98fda2c26c43c2c5eb66e9378bd7f93))
 - **FIX**(shared): correct enum mapping casing and Portuguese strings regression. ([ff8fed68](https://github.com/acdgbrasil/acdg/commit/ff8fed686616867edca299096b9ae9633ff81bab))
 - **FEAT**: 🚀 complete social care missions (People Context, Sentry, UI Extraction). ([90878c35](https://github.com/acdgbrasil/acdg/commit/90878c354bd621af83d34f5847e8cec6fc88bad9))
 - **FEAT**: 🔗 propagate fullName through addFamilyMember chain for people-context registration. ([1f2387d0](https://github.com/acdgbrasil/acdg/commit/1f2387d01cec3244ccebbe2957860b7531a61c53))
 - **FEAT**: 🔄 refactor storage logic and implement offline-first sync engine. ([55713c15](https://github.com/acdgbrasil/acdg/commit/55713c15d9553a7c1dcfd7410f6fbc655207c49e))
 - **FEAT**(shared): update kernel VOs and social care contracts with full mapping support. ([a097138f](https://github.com/acdgbrasil/acdg/commit/a097138fde6eeea23422121c81d7783facd19505))
 - **FEAT**(social-care): implement complete offline engine with local-first strategy. ([1bae9821](https://github.com/acdgbrasil/acdg/commit/1bae98218281f4befb5f6ae1c8c53ef2a42408e5))
 - **FEAT**(staging): implement and validate full Registry lifecycle (Family/Caregiver). ([03b9e2c4](https://github.com/acdgbrasil/acdg/commit/03b9e2c457bda0bc233c067ae6aaac82dada3783))
 - **FEAT**(staging): finalize end-to-end integration with HML environment. ([7fd7cbf0](https://github.com/acdgbrasil/acdg/commit/7fd7cbf02beb0460e934b9f55bb34047ff3c9e5d))
 - **FEAT**(bff): implement shared kernel with VOs, models and contract. ([ceb7023a](https://github.com/acdgbrasil/acdg/commit/ceb7023a25ee7377eadd9c3d11e159138e1c71d8))

## 1.1.0

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

## 1.0.0

- Initial version.
