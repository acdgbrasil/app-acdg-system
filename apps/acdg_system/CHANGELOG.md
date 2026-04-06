## 0.1.1

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

