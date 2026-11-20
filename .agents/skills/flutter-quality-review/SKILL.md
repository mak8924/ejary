---
name: flutter-quality-review
description: Review Flutter code for architecture violations, security issues, bugs, UI problems, and test coverage.
---

# Flutter Quality Review

## Review Workflow

1. Inspect modified files.
2. Check Clean Architecture boundaries.
3. Check GetX dependency injection.
4. Check state management.
5. Check null safety and error handling.
6. Review PIN security.
7. Check route protection.
8. Review Arabic and English localization.
9. Test Light and Dark themes.
10. Check responsive UI.
11. Run dart format.
12. Run flutter analyze.
13. Run flutter test.

## Completion Criteria

- No compilation errors.
- No unresolved imports.
- No broken routes.
- No missing dependencies.
- No plaintext PIN storage.
- No nonfunctional required buttons.
- Relevant tests pass.
- No critical architecture violations.

Provide a report of issues found and fixes applied.
