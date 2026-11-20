---
trigger: always_on
description: Enforce secure PIN handling and safe application behavior.
---

# Security Rules

1. Never store PIN values as plaintext.
2. Never hardcode a default PIN.
3. Never log PIN values or sensitive information.
4. Use cryptographically secure random salts.
5. Use PBKDF2 with an appropriate work factor for PIN hashing.
6. Store sensitive data using secure platform storage.
7. Never expose secure storage implementation to Presentation.
8. Validate PIN length and input.
9. Implement persistent failed-attempt tracking and temporary lockout.
10. Never bypass PIN verification through direct route navigation.
11. Protect sensitive operations with proper verification.
12. Never claim local PIN protection guarantees complete device security.
13. Never invent remote authentication or PIN recovery functionality.
14. Avoid exposing secrets in exceptions or debug output.
15. Never commit secrets or credentials to version control.
