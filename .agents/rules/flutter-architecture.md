---
trigger: always_on
description: Enforce Clean Architecture and feature-first structure.
---

# Flutter Architecture Rules

1. Always use feature-first Clean Architecture.
2. Every feature must contain Presentation, Domain, and Data layers.
3. Domain must never depend on Flutter, GetX, or Data implementations.
4. Controllers must communicate with use cases, never directly with data sources.
5. Repository interfaces belong to Domain.
6. Repository implementations belong to Data.
7. Use GetX Bindings for dependency injection.
8. Keep every class focused on one responsibility.
9. Shared functionality belongs in Core.
10. Never place business logic inside UI widgets.
11. Avoid circular dependencies.
12. Avoid unnecessary abstractions and overengineering.
13. Preserve the existing folder structure.
14. Never move business-specific logic into Core.
15. Keep features independent and maintainable.
