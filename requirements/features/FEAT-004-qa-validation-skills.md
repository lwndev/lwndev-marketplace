# Feature Requirements: QA Validation Skills (documenting-qa + executing-qa)

## Overview

Add two skills, a subagent, and stop hooks to the `lwndev-sdlc` plugin that provide a systematic QA validation gate after execution skills complete. Includes test plan generation, automated verification with a ralph loop pattern, and documentation reconciliation to keep requirements in sync with actual implementation.

## Feature ID

`FEAT-004`

## GitHub Issue

[#23](https://github.com/lwndev/lwndev-marketplace/issues/23)

## Priority

High - No systematic QA gate currently exists before merge; verification is limited to inline checks during execution, and implementation drift from requirements goes unreconciled

## User Story

As a developer using the SDLC plugin, I want a dedicated QA validation step after execution so that I can verify all acceptance criteria are met, test coverage is sufficient, and requirements documents reflect what was actually implemented before merging.

## Functional Requirements

### FR-1: `documenting-qa` Skill - Test Plan Generation

- Accept FEAT-XXX, CHORE-XXX, and BUG-XXX IDs as input
- Locate and read the correct requirements document by ID and type from `requirements/features/`, `requirements/chores/`, or `requirements/bugs/` (and `requirements/implementation/` for features)
- Load implementation plans for feature IDs when they exist
- Analyze acceptance criteria, functional requirements, and (for bugs) root causes
- Build a structured test plan covering:
  - Existing test verification (all tests pass)
  - New test analysis (are added tests meaningful and sufficient?)
  - Coverage gaps (new/changed functionality without tests)
  - Code path verification (logic matches acceptance criteria)

### FR-2: `documenting-qa` - Type-Specific Test Plan Logic

- **FEAT-XXX**: Review feature requirements doc + implementation plan; verify each functional requirement (FR-N) and acceptance criterion has a corresponding test plan entry
- **CHORE-XXX**: Review chore doc; verify acceptance criteria and that changes are scoped correctly
- **BUG-XXX**: Review bug doc; verify each root cause (RC-N) is addressed and tagged acceptance criteria are covered

### FR-3: `documenting-qa` - Ralph Loop for Plan Completeness

- Delegate plan completeness verification to the `qa-verifier` subagent
- `qa-verifier` compares the test plan against source documents: every AC, FR-N, RC-N, and phase deliverable must be covered
- If gaps found, add missing items to the test plan and re-verify
- Define a `Stop` hook (`type: "prompt"`) in SKILL.md frontmatter that blocks completion when the plan is incomplete:
  ```yaml
  hooks:
    Stop:
      - hooks:
          - type: prompt
            prompt: "You are evaluating whether Claude should stop. Context: $ARGUMENTS\n\nA prompt hook is a single-turn LLM call with no tool access — you can only evaluate based on the input fields provided, not by reading files.\n\nIf stop_hook_active is true in the input, respond {\"ok\": true} immediately to prevent infinite loops.\n\nOtherwise, examine last_assistant_message. Claude should have delegated to a qa-verifier subagent and received a completeness verdict. Based on Claude's last message, determine if the test plan covers every acceptance criterion, FR-N, RC-N, and phase deliverable from the source requirements.\n\nRespond with {\"ok\": true} if Claude's message indicates the plan is complete, or {\"ok\": false, \"reason\": \"what appears to be missing based on Claude's message\"} if gaps remain."
            model: haiku
  ```
- **Important**: A `type: "prompt"` hook is a single-turn LLM call with no tool access. It evaluates based on the Stop hook input fields (`last_assistant_message`, `stop_hook_active`, etc.), not by reading files directly. The heavy verification is performed by the `qa-verifier` subagent; the prompt hook only evaluates Claude's stated results.
- Prompt hook returns `{"ok": true}` when plan is complete, or `{"ok": false, "reason": "..."}` to block and feed missing items back to Claude
- The skill instructions must guide Claude to attempt completion after each verification round so the Stop hook can evaluate
- Loop exits when the test plan fully covers all inputs from source documents

### FR-4: `documenting-qa` - Test Plan Output

- Save test plan to `test/test-plans/QA-plan-{type}-{id}.md`
- Present test plan to user for review before execution begins

### FR-5: `executing-qa` - QA Verification Ralph Loop

- Load the test plan from `test/test-plans/QA-plan-{type}-{id}.md`
- Delegate verification to the `qa-verifier` subagent each iteration
- `qa-verifier` runs tests, analyzes coverage, and verifies code paths against acceptance criteria
- If issues found, auto-fix them (write missing tests, fix broken tests, address coverage gaps, correct logic mismatches)
- The skill instructions must guide Claude to attempt completion after each fix-and-verify round so the Stop hook can evaluate
- Define a `Stop` hook (`type: "prompt"`) in SKILL.md frontmatter:
  ```yaml
  hooks:
    Stop:
      - hooks:
          - type: prompt
            prompt: "You are evaluating whether Claude should stop. Context: $ARGUMENTS\n\nA prompt hook is a single-turn LLM call with no tool access — you can only evaluate based on the input fields provided, not by reading files.\n\nIf stop_hook_active is true in the input, respond {\"ok\": true} immediately to prevent infinite loops.\n\nOtherwise, examine last_assistant_message to determine the current phase:\n(1) If QA verification is in progress: does Claude's message indicate the qa-verifier returned a clean pass verdict with no remaining issues?\n(2) If verification passed and documentation reconciliation is in progress: does Claude's message indicate all reconciliation areas are covered (affected files updated, acceptance criteria modifications documented, implementation steps updated, deviation summary added where needed)?\n\nRespond {\"ok\": true} if the current phase is complete based on Claude's message, or {\"ok\": false, \"reason\": \"what appears to remain\"} if not."
            model: haiku
  ```
- **Important**: A `type: "prompt"` hook is a single-turn LLM call with no tool access. It evaluates based on the Stop hook input fields (`last_assistant_message`, `stop_hook_active`, etc.), not by reading files directly. The heavy verification is performed by the `qa-verifier` subagent; the prompt hook only evaluates Claude's stated results.
- Prompt hook returns `{"ok": true}` to allow completion, or `{"ok": false, "reason": "..."}` to block and feed remaining work back to Claude
- Stop hook uses `stop_hook_active` input field to detect re-entry and prevent infinite loops — when `true`, the hook allows stop
- Loop exits when all criteria pass cleanly

### FR-6: `executing-qa` - Type-Specific Verification

- **FEAT-XXX**: Verify each functional requirement (FR-N) has corresponding test coverage; validate acceptance criteria against implementation
- **CHORE-XXX**: Verify acceptance criteria met; confirm changes are minimal and scoped
- **BUG-XXX**: Verify each root cause (RC-N) has targeted tests; confirm reproduction steps no longer reproduce the bug

### FR-7: `executing-qa` - Documentation Reconciliation

After the QA verification loop completes, perform documentation reconciliation with its own lighter verification loop:

- Compare actual changes (PR diff) against requirements doc
- Update affected files lists to match actual changes
- Mark acceptance criteria that were modified, added, or descoped during implementation
- Update implementation steps to reflect what was actually done (plan phases)
- Ensure any new root causes discovered during implementation are documented with their acceptance criteria (bug fixes)
- Add a brief deviation summary when the implementation diverged from the plan, including rationale
- Reconciliation loop verifies all areas are covered before allowing stop

### FR-8: `executing-qa` - Per-Type Reconciliation

- **FEAT-XXX**: Reconcile feature requirements doc and implementation plan — update FRs, acceptance criteria, affected files, and phase steps/deliverables
- **CHORE-XXX**: Reconcile chore doc — update acceptance criteria, affected files, and add scope notes if needed
- **BUG-XXX**: Reconcile bug doc — update root causes, acceptance criteria (including RC-N tags), affected files, and reproduction steps if they changed

### FR-9: `executing-qa` - Test Results Output

- Save results to `test/test-results/QA-results-{type}-{id}.md`
- Preserve existing document functionality (status tracking, deliverable checkboxes, root cause tracking) when reconciling

### FR-10: `qa-verifier` Subagent

- Defined in `agents/qa-verifier.md` within the `lwndev-sdlc` plugin
- Runs on Sonnet model for cost efficiency
- Has isolated context window (keeps verbose test output out of main conversation)
- Tools limited to Bash, Read, Grep, Glob
- Capabilities:
  - Run all existing tests and verify they pass
  - Analyze new/modified tests for meaningfulness (not trivial, add real value)
  - Identify test coverage gaps for new/changed functionality
  - Verify code paths match acceptance criteria
  - Verify test plan completeness against source documents (for `documenting-qa`)
  - Return clear pass/fail verdict with actionable details
- Bug-specific: Each root cause (RC-N) has targeted test verification
- Feature-specific: Each functional requirement (FR-N) has test coverage verification

### FR-11: Plugin Structure

New files added to the existing `lwndev-sdlc` plugin:

```
plugins/lwndev-sdlc/
├── .claude-plugin/
│   └── plugin.json         # Updated: version bump, description (agents field optional)
├── skills/
│   ├── documenting-qa/
│   │   ├── SKILL.md
│   │   ├── assets/
│   │   └── references/
│   └── executing-qa/
│       ├── SKILL.md
│       ├── assets/
│       └── references/
├── agents/
│   └── qa-verifier.md
└── (existing files unchanged)
```

### FR-12: Plugin Manifest Agents Field

The `agents/` directory at the plugin root is **auto-discovered** by Claude Code (per the plugins reference, `agents/` is a default location alongside `skills/` and `commands/`). An explicit `"agents"` field in `plugin.json` is optional but can be added for clarity:

```json
{
  "agents": "./agents/"
}
```

Note: The existing `plugin.json` does not declare a `skills` field — skills are auto-discovered from the default `skills/` directory. The same auto-discovery applies to `agents/`.

### FR-13: Allowed-Tools Declarations

- `documenting-qa`: Read, Write, Edit, Glob, Grep, Agent (needs Agent for `qa-verifier` subagent delegation)
- `executing-qa`: Read, Write, Edit, Bash, Glob, Grep, Agent

## Non-Functional Requirements

### NFR-1: Cost Efficiency

- The `qa-verifier` subagent runs on Sonnet to minimize API costs for verification tasks that are read-heavy and don't require Opus-level reasoning
- Stop hook prompt evaluations use Haiku (`model: haiku`) for minimal cost — these are lightweight pass/fail checks that don't require stronger models

### NFR-2: Context Isolation

- Test output, coverage analysis, and code path tracing stay in the `qa-verifier` subagent's isolated context window, keeping the main conversation clean

### NFR-3: Loop Termination

- Stop hooks must check the `stop_hook_active` boolean field in the hook input JSON to detect re-entry and prevent infinite loops — when `true`, the hook must return `{"ok": true}` to allow stop
- Each loop has a clear exit condition (plan complete, all criteria pass, reconciliation complete)
- Skill instructions must guide Claude to attempt completion after each verification round, since the ralph loop is driven by the Stop hook evaluating Claude's attempt to finish

### NFR-4: Existing Functionality Preservation

- Reconciliation must preserve existing document structure and functionality (status tracking, deliverable checkboxes, root cause tracking)
- No changes to existing skills' behavior

### NFR-5: Plugin Compatibility

- Plugin must remain loadable with `claude --plugin-dir` for testing
- Plugin manifest (`plugin.json`) updated with version bump and updated description (`"agents"` field is optional since `agents/` is auto-discovered)
- Plugin README updated to document new QA skills and workflow chain

## Dependencies

- `ai-skills-manager` — for skill validation (`validate()` API)
- Claude Code plugin system — for `allowed-tools`, `Stop` hooks (`type: "prompt"`), and `agents/` directory support
- Existing `lwndev-sdlc` plugin skills and structure

## Edge Cases

1. **Requirements document not found for given ID**: Display clear error with expected path
2. **No implementation plan for a FEAT-XXX ID**: Proceed with feature requirements doc only; note absence in test plan
3. **No test plan exists when `executing-qa` runs**: Error with guidance to run `documenting-qa` first
4. **All tests already pass with full coverage**: Verification loop completes on first iteration; reconciliation still runs
5. **Reconciliation finds no divergence**: Brief "no divergence" note added to results; no doc modifications needed
6. **Mixed ID formats**: Validate ID matches expected pattern (FEAT-XXX, CHORE-XXX, BUG-XXX) before proceeding
7. **Stop hook re-entry**: `stop_hook_active` field prevents infinite loop; hook allows stop on re-entry detection

## Testing Requirements

### Unit Tests

- Test plan generation covers all FR-N, AC, and RC-N from source documents
- Type detection correctly routes FEAT/CHORE/BUG IDs to the right requirements directory
- Test plan file naming follows `QA-plan-{type}-{id}.md` convention
- Test results file naming follows `QA-results-{type}-{id}.md` convention
- `allowed-tools` frontmatter is present and correct for both skills

### Integration Tests

- Both skills pass `ai-skills-manager` validation
- Plugin validates successfully with new skills and agents directory
- `qa-verifier` subagent definition is valid and references correct model/tools

### Manual Testing

- Run `documenting-qa` against an existing FEAT-XXX with implementation plan
- Run `documenting-qa` against an existing CHORE-XXX
- Run `documenting-qa` against an existing BUG-XXX
- Run `executing-qa` after `documenting-qa` produces a test plan
- Verify reconciliation updates requirements doc correctly
- Test with a case where implementation diverged from requirements
- Verify `qa-verifier` subagent runs on Sonnet and returns structured verdicts

## Acceptance Criteria

### Plugin integration

- [ ] New skills are added to the existing `lwndev-sdlc` plugin under `plugins/lwndev-sdlc/skills/`
- [ ] New `agents/` directory is created in `plugins/lwndev-sdlc/` for the `qa-verifier` subagent
- [ ] Plugin manifest (`plugin.json`) is updated with a version bump and updated description
- [ ] Plugin README is updated to document the new QA skills and workflow chain
- [ ] Plugin can be loaded with `claude --plugin-dir` for testing

### `documenting-qa` skill

- [ ] Accepts FEAT-XXX, CHORE-XXX, and BUG-XXX IDs
- [ ] Locates and reads the correct requirements document by ID and type
- [ ] Loads implementation plans for feature IDs when they exist
- [ ] Generates a structured test plan with type-specific logic
- [ ] Defines a `Stop` hook (`type: "prompt"`, `model: haiku`) in SKILL.md frontmatter for plan completeness loop
- [ ] Stop hook returns `{"ok": true/false}` format per Claude Code prompt hook spec
- [ ] Stop hook evaluates `last_assistant_message` (not files — prompt hooks have no tool access)
- [ ] Stop hook checks `stop_hook_active` boolean in hook input and returns `{"ok": true}` when `true` to prevent infinite loops
- [ ] Delegates plan completeness verification to `qa-verifier` subagent
- [ ] Skill instructions guide Claude to attempt completion after each verification round
- [ ] Loops until test plan covers every AC, FR-N, RC-N, and phase deliverable from source documents
- [ ] Test plan is saved to `test/test-plans/QA-plan-{type}-{id}.md`
- [ ] Test plan is presented to user for review before execution
- [ ] Follows existing skill structure (SKILL.md, assets/, references/)
- [ ] Includes `allowed-tools` declarations in frontmatter (including Agent)

### `executing-qa` skill

- [ ] Loads the test plan and orchestrates the QA verification ralph loop
- [ ] Defines a `Stop` hook (`type: "prompt"`, `model: haiku`) in SKILL.md frontmatter
- [ ] Stop hook returns `{"ok": true/false}` format per Claude Code prompt hook spec
- [ ] Stop hook evaluates `last_assistant_message` (not files — prompt hooks have no tool access)
- [ ] Stop hook handles both verification phase and reconciliation phase via phase detection in prompt
- [ ] Stop hook checks `stop_hook_active` boolean in hook input and returns `{"ok": true}` when `true` to prevent infinite loops
- [ ] Delegates verification to `qa-verifier` subagent each iteration
- [ ] Auto-fixes issues identified by the verifier (missing tests, broken tests, logic mismatches)
- [ ] QA verification loop exits when all criteria pass cleanly
- [ ] Performs documentation reconciliation after verification passes
- [ ] Reconciliation loop verifies all areas are covered (affected files, acceptance criteria, scope notes, implementation steps)
- [ ] Reconciliation updates affected files lists to match actual changes
- [ ] Reconciliation documents acceptance criteria modifications
- [ ] Reconciliation captures implementation step changes (plan phases)
- [ ] Reconciliation includes deviation summary when implementation diverged
- [ ] Existing document functionality (status tracking, deliverable checkboxes, root cause tracking) is preserved
- [ ] Test results are saved to `test/test-results/QA-results-{type}-{id}.md`
- [ ] Follows existing skill structure (SKILL.md, assets/, references/)
- [ ] Includes `allowed-tools` declarations in frontmatter (including Agent)

### `qa-verifier` subagent

- [ ] Defined in `agents/qa-verifier.md` within the `lwndev-sdlc` plugin
- [ ] Runs on Sonnet model for cost efficiency
- [ ] Has isolated context window
- [ ] Tools limited to Bash, Read, Grep, Glob
- [ ] Runs all existing tests and verifies they pass
- [ ] Analyzes new/modified tests for meaningfulness
- [ ] Identifies test coverage gaps for new/changed functionality
- [ ] Verifies code paths match acceptance criteria
- [ ] Verifies test plan completeness against source documents (for `documenting-qa`)
- [ ] Returns clear pass/fail verdict with actionable details
- [ ] Bug-specific: Each root cause (RC-N) has targeted test verification
- [ ] Feature-specific: Each functional requirement (FR-N) has test coverage verification
