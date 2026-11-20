---
name: getx-feature-development
description: Implement Flutter features using GetX controllers, bindings, routing, and Clean Architecture use cases.
---

# GetX Feature Development

## Workflow

1. Understand feature requirements.
2. Identify entities and use cases.
3. Create repository contracts and implementations.
4. Create the GetX controller.
5. Connect use cases through dependency injection.
6. Create feature bindings.
7. Create screens.
8. Register named routes.
9. Implement loading, success, and error states.
10. Test the complete feature flow.

## Rules

- Use GetxController for feature state.
- Use Bindings for dependency injection.
- Use GetPage for named routes.
- Avoid business logic in controllers.
- Controllers call use cases.
- Use reactive variables only when required.
- Avoid unnecessary global dependencies.
- Dispose resources when needed.
- Do not mix other state management libraries.

## Output

A complete feature with working navigation, state management, dependency injection, and tests.
