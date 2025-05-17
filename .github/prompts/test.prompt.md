---
mode: 'agent'
description: 'Run the test suite'
---

FIRST:

- Run the unit tests in #file:../../DroppedTests
- Ensure all test pass successful
- If tests fail, review the error messages and fix the issues in the codebase
- If tests pass, proceed to the next step

THEN:

- Run the integration tests in #file:../../DroppedUITests
- Ensure all test pass successful
- If tests fail, review the error messages and fix the issues in the codebase
- If tests pass, proceed to the next step

FINALLY:

- Report back to the user with the results of the test suite