# Flutter Official AI Rules (from flutter/flutter repo)

> Source: https://github.com/flutter/flutter/blob/main/docs/rules/rules.md

---

## Interaction Guidelines
- Assume user is familiar with programming but may be new to Dart
- Provide explanations for Dart-specific features (null safety, futures, streams)
- Ask for clarification on intended functionality and target platform
- Explain benefits of suggested dependencies from pub.dev
- Use `dart_format` for consistent formatting
- Use `dart_fix` for automatic fixes
- Use `analyze_files` for linting

## Flutter Style Guide
- **SOLID Principles** throughout the codebase
- **Concise and declarative** — prefer functional and declarative patterns
- **Composition over inheritance** for complex widgets and logic
- **Immutability** — prefer immutable data structures. StatelessWidgets must be immutable
- **State Management** — separate ephemeral state and app state
- **Widgets are for UI** — compose complex UIs from smaller, reusable widgets
- **Navigation** — use `go_router` for routing

## Code Quality
- Avoid abbreviations — use meaningful, consistent, descriptive names
- Lines should be 80 characters or fewer
- `PascalCase` for classes, `camelCase` for members/variables/functions/enums, `snake_case` for files
- Keep functions short — less than 20 lines, single purpose
- Write code with testing in mind — use injectable dependencies
- Use `logging` package instead of `print`

## Dart Best Practices
- Follow Effective Dart guidelines
- API documentation on all public APIs
- Use `async`/`await` for async operations, `Stream`s for async event sequences
- Sound null safety — avoid `!` unless guaranteed non-null
- Use pattern matching where it simplifies code
- Use records for multiple return values
- Prefer exhaustive `switch` statements/expressions
- Arrow syntax for simple one-line functions

## Flutter Best Practices
- Use **private Widget classes** instead of helper methods returning Widget
- Break down large `build()` methods into smaller private Widget classes
- Use `ListView.builder` or `SliverList` for long lists (lazy-loaded)
- Use `compute()` for expensive calculations in separate isolates
- Use `const` constructors whenever possible to reduce rebuilds
- Never perform expensive operations in `build()` methods

## Application Architecture
- **Separation of Concerns** — MVC/MVVM with Model, View, ViewModel/Controller roles
- **Logical Layers:** Presentation, Domain, Data, Core
- **Feature-based organization** for larger projects

## State Management
- Prefer Flutter's built-in state management
- `ValueNotifier` + `ValueListenableBuilder` for simple local state
- `ChangeNotifier` for complex or shared state
- `ListenableBuilder` to listen to ChangeNotifier changes
- MVVM for robust solutions
- Manual constructor dependency injection
- `provider` for DI when needed

## Data Flow
- Define data classes for application data
- Abstract data sources using Repositories/Services for testability

## Routing (GoRouter)
- Declarative navigation, deep linking, web support
- Authentication redirects via `redirect` property
- `Navigator` for short-lived screens (dialogs, temporary views)

## Testing
- `package:test` for unit tests
- `package:flutter_test` for widget tests
- `package:integration_test` for integration tests
- Prefer `package:checks` for assertions
- Arrange-Act-Assert (Given-When-Then) pattern
- Prefer fakes/stubs over mocks
- Aim for high test coverage

## Visual Design & Theming
- Centralized `ThemeData` for consistent styles
- Light and dark themes (`ThemeMode.light`, `.dark`, `.system`)
- `ColorScheme.fromSeed()` for harmonious palettes
- `ThemeExtension` for custom design tokens
- `WidgetStateProperty` for state-dependent styles
- WCAG contrast ratios: 4.5:1 normal text, 3:1 large text
- 60-30-10 color rule

## Layout Best Practices
- `Expanded` to fill remaining space, `Flexible` to shrink-to-fit
- `Wrap` when widgets would overflow Row/Column
- `SingleChildScrollView` for fixed-size content larger than viewport
- `ListView.builder` / `GridView.builder` for long lists
- `LayoutBuilder` for responsive layouts
- `Stack` + `Positioned`/`Align` for layered widgets

## Accessibility
- Color contrast 4.5:1 minimum
- Dynamic text scaling support
- `Semantics` widget for descriptive labels
- Test with TalkBack/VoiceOver

## Documentation
- `///` for doc comments
- Start with single-sentence summary
- Document why, not what
- No trailing comments
- Backticks for code in docs
- Doc comments before annotations
