---
name: tdd
description: Strict test-driven development (red, green, refactor) for any project and language. Use before writing or changing production code - new feature, bug fix, refactor, file move - and whenever a project's instructions mention TDD. Covers what counts as a valid red, which kind of test fits which change, characterization tests before refactoring untested code, and how to report test results honestly.
---

# TDD

One behavior at a time, in a short loop. Never write production code without a failing test that asks for it.

## 1. Learn the project's test setup first

Before the first test, find out how this project tests. In order:

1. Project instructions (`CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`): look for a **test map** - a section that says which kind of test goes where, with which helpers and which command. If it exists, it overrides the defaults below.
2. Test scripts (`package.json`, `Makefile`, `pyproject.toml`, `composer.json`, `Cargo.toml`...).
3. Two or three existing tests close to the code you will change: copy their file location, naming, helpers, language of test names and assertion style.

Do not add a test framework, helper library or new test folder layout without asking.

If the project has no test map, offer to write one into its instructions at the end of the task (see section 7).

## 2. The cycle

**Red.** Write one test for the next small behavior. Run it. Read the failure.

A red is valid only if it fails **on an assertion about the behavior**: wrong value, missing element, error not raised, row visible when it should not be. These are not valid reds, fix them and run again:

- module or file not found, undefined export, import error
- syntax or type error in the test itself
- missing fixture, env var, database, network
- a test that passes immediately (it tests nothing new, or the behavior already exists - say so)

For a brand new module, create the empty export first (function that throws "not implemented", or returns a neutral value) so the red lands on the assertion.

**Green.** Write the simplest code that makes this test pass. No extra branch, option or abstraction the test does not ask for. Run the test: it passes. Run the neighbors (same file or folder): they still pass.

**Refactor.** Clean names, duplication and structure in code **and** tests, with everything green. Run again after each step. No new behavior here.

Then the next behavior. Stop when the requested behavior is fully covered, not before.

## 3. Pick the right kind of test

Test at the lowest level that can prove the behavior:

| Change | Test | Notes |
|---|---|---|
| Pure rule, calculation, validation, state machine | Unit test next to the code | Fast, no I/O, most tests live here |
| Component or screen | Render test, user-centric queries (role, label, text) | Assert what the user sees and can do; add an accessibility check if the project has one |
| Database rule: constraint, trigger, permission, row-level security | Database test (pgTAP, SQL test, migration test) | Test as each role: owner, member, stranger |
| Server action, endpoint, use case with real I/O | Integration test against the test database or service | Real wiring, fake only what leaves the system (email, payment) |
| Full user journey | End-to-end, only if the project already has them | Few, slow, last |

A bug fix starts with a test that reproduces the bug and fails for the reported reason.

## 4. Refactor, move or rename

Behavior must not change, so the red step is different:

1. Check that tests cover the code you will touch. Run them: green.
2. If coverage is missing, first write **characterization tests** that pin the current behavior (including odd edge cases), and see them pass on the unchanged code.
3. Change the structure in small steps, running the tests after each step.

A "module not found" red after a move is expected, but it only proves the file moved. The characterization tests are what prove nothing broke.

## 5. Test quality

- Test names read as behavior: "rejects an expired invitation", not "test invite 2".
- One reason to fail per test. Arrange, act, assert.
- Assert on outputs and visible effects, not on private calls or internal state. Mock only boundaries.
- Deterministic: fixed dates, seeds and ids; no order dependency; clean up created data.
- Never weaken, skip or delete a failing test to get green. If a test is wrong, say why before changing it.

## 6. Before saying "done"

Run, from narrowest to widest:

1. the tests you wrote
2. the suite of the area you touched
3. typecheck and lint, if the project has them
4. the full suite the project defines as its gate

Report what ran and the counts. If a suite was not run (needs credentials, a database, too slow), say so and why. Never claim green for a command you did not run.

## 7. Test map template

When a project has no test map, propose this section for its instructions file, filled from what you found in step 1:

```markdown
## Tests (TDD)
Skill `tdd`. Map of this project:
| Change | Test file | Helpers | Command |
|---|---|---|---|
| Domain rule | `src/**/domain/*.test.ts` | - | `npm run test:run -- <path>` |
| Component | ... | ... | ... |
| Database / permissions | ... | ... | ... |
| Server action / integration | ... | ... | ... |
Gate before closing a task: `<command>`.
```
