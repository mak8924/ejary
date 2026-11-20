---
name: flutter-clean-architecture
description: Design, extend, and review Flutter projects using strict feature-first Clean Architecture. Use when creating features, layers, repositories, entities, or use cases.
---

# Flutter Clean Architecture Skill

## Workflow

1. Inspect the current project structure.
2. Identify the feature being implemented.
3. Create Presentation, Domain, and Data layers.
4. Define Domain entities.
5. Define repository contracts.
6. Create focused use cases.
7. Implement data sources.
8. Implement repository implementations.
9. Connect dependencies through GetX Bindings.
10. Verify dependency direction.

## Architecture Constraints

- Domain must not depend on Flutter or GetX.
- Presentation must not access Data sources directly.
- Data implements Domain repository contracts.
- Use cases represent individual business operations.
- Keep features independent.
- Shared components belong in Core.
- Avoid unnecessary abstractions.

## Deliverables

- Updated folder structure.
- Complete source files.
- Dependency registration.
- Explanation of architectural decisions.
- Successful analysis and relevant tests.
