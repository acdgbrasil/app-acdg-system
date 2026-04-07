---
title: "Use design system tokens, never raw values"
scope: "file"
path: ["**/view/**/*.dart", "**/views/**/*.dart", "**/pages/**/*.dart", "**/atoms/**/*.dart", "**/molecules/**/*.dart", "**/organisms/**/*.dart", "**/templates/**/*.dart"]
severity_min: "medium"
languages: ["dart"]
buckets: ["style-conventions"]
enabled: true
---

## Instructions

All UI code must use design system tokens from `packages/design_system/`. Never use raw hex colors, hardcoded font sizes, or magic spacing numbers.

Flag:
- `Color(0xFF...)` or `Colors.xxx` (use semantic token from design system)
- Hardcoded `fontSize:` values (use typography tokens)
- Hardcoded `EdgeInsets` padding/margin values (use spacing tokens)
- Hardcoded `BorderRadius` values (use radius tokens)

Allowed:
- `Colors.transparent` and `Colors.white`/`Colors.black` when used for overlays
- Design system token files themselves
- Test files

## Examples

### Bad example
```dart
Container(
  color: Color(0xFF0477BF),
  padding: EdgeInsets.all(16),
  child: Text('Hello', style: TextStyle(fontSize: 14)),
)
```

### Good example
```dart
Container(
  color: AcdgColors.primary,
  padding: EdgeInsets.all(AcdgSpacing.md),
  child: Text('Hello', style: AcdgTypography.bodyMedium),
)
```
