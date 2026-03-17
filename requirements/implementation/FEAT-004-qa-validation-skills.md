# Implementation Plan: QA Validation Skills

## Overview

Add two new skills (`documenting-qa`, `executing-qa`), a subagent (`qa-verifier`), and stop hooks to the existing `lwndev-sdlc` plugin. These provide a systematic QA validation gate after execution skills create a PR — generating test plans, running automated verification via ralph loops, and reconciling requirements documents with actual implementation. This introduces the plugin's first subagent and its first use of stop hooks.

## Features Summary

| Feature ID | GitHub Issue | Feature Document | Priority | Complexity | Status |
|------------|--------------|------------------|----------|------------|--------|
| FEAT-004   | [#23](https://github.com/lwndev/lwndev-marketplace/issues/23) | [FEAT-004-qa-validation-skills.md](../features/FEAT-004-qa-validation-skills.md) | High | High | Pending |

## Recommended Build Sequence

### Phase 1: qa-verifier Subagent and Plugin Infrastructure
**Feature:** [FEAT-004](../features/FEAT-004-qa-validation-skills.md) | [#23](https://github.com/lwndev/lwndev-marketplace/issues/23)
**Status:** ✅ Complete

#### Rationale
- The subagent is a dependency for both skills — build it first so skills can delegate to it immediately
- Establishes the new `agents/` directory pattern in the plugin
- Updates plugin manifest and README early so subsequent phases don't need to worry about plugin-level changes
- Low coupling to skill logic — the subagent prompt can be refined independently
- Validates that the `agents/` directory is compatible with plugin validation before building skills on top of it

#### Implementation Steps
1. Create `plugins/lwndev-sdlc/agents/` directory
2. Create `plugins/lwndev-sdlc/agents/qa-verifier.md` with:
   - Model declaration: Sonnet
   - Tools: Bash, Read, Grep, Glob
   - Prompt defining the verifier's responsibilities:
     - Run the full test suite and collect pass/fail results
     - Analyze new/modified tests for meaningfulness
     - Identify test coverage gaps for new/changed code
     - Verify code paths match acceptance criteria
     - Verify test plan completeness against source documents
     - Return structured pass/fail verdict with actionable details
   - Type-specific verification instructions (FEAT: FR-N coverage, BUG: RC-N targeting, CHORE: scope validation)
3. Update `plugins/lwndev-sdlc/.claude-plugin/plugin.json`:
   - Bump version (e.g., `1.0.0` → `1.1.0`)
   - Update description to mention QA validation capabilities
   - Optionally add `"agents": "./agents/"` field for explicitness (the `agents/` directory is auto-discovered by default, same as `skills/`)
4. Update `plugins/lwndev-sdlc/README.md`:
   - Add QA workflow chain: `documenting-qa` → `executing-qa`
   - Document the `qa-verifier` subagent
   - Update the skill count and workflow overview
5. Run `npm run validate` to confirm plugin still validates with the new `agents/` directory
6. Add tests for the `qa-verifier` agent definition (file exists, contains expected model/tools declarations)

#### Deliverables
- [x] `plugins/lwndev-sdlc/agents/qa-verifier.md` — subagent definition
- [x] `plugins/lwndev-sdlc/.claude-plugin/plugin.json` — version bump and description update
- [x] `plugins/lwndev-sdlc/README.md` — updated with QA workflow documentation
- [x] Plugin validates successfully with `npm run validate`
- [x] Tests for qa-verifier agent definition

---

### Phase 2: documenting-qa Skill
**Feature:** [FEAT-004](../features/FEAT-004-qa-validation-skills.md) | [#23](https://github.com/lwndev/lwndev-marketplace/issues/23)
**Status:** Pending

#### Rationale
- `documenting-qa` is the entry point for the QA workflow — users run it first to generate a test plan
- Follows the existing plugin pattern of documenting skills being simpler and lower-risk than execution skills
- The test plan it produces is a prerequisite for `executing-qa` in Phase 3
- Introduces stop hooks with a simpler single-phase loop (plan completeness only) before Phase 3 adds the more complex multi-phase loop

#### Implementation Steps
1. Create skill directory structure:
   ```
   plugins/lwndev-sdlc/skills/documenting-qa/
   ├── SKILL.md
   ├── assets/
   │   └── test-plan-template.md
   └── references/
   ```
2. Write `SKILL.md` with frontmatter:
   ```yaml
   ---
   name: documenting-qa
   description: Builds a QA test plan from requirements documents. Use when the user says "document qa", "create test plan", "qa plan", or provides a requirement ID (FEAT-XXX, CHORE-XXX, BUG-XXX) for QA planning.
   allowed-tools:
     - Read
     - Write
     - Edit
     - Glob
     - Grep
     - Agent
   hooks:
     Stop:
       - hooks:
           - type: prompt
             prompt: "You are evaluating whether Claude should stop. Context: $ARGUMENTS\n\nA prompt hook is a single-turn LLM call with no tool access — you can only evaluate based on the input fields provided, not by reading files.\n\nIf stop_hook_active is true in the input, respond {\"ok\": true} immediately to prevent infinite loops.\n\nOtherwise, examine last_assistant_message. Claude should have delegated to a qa-verifier subagent and received a completeness verdict. Based on Claude's last message, determine if the test plan covers every acceptance criterion, FR-N, RC-N, and phase deliverable from the source requirements.\n\nRespond with {\"ok\": true} if Claude's message indicates the plan is complete, or {\"ok\": false, \"reason\": \"what appears to be missing based on Claude's message\"} if gaps remain."
             model: haiku
   ---
   ```
3. Write SKILL.md body with workflow instructions:
   - Accept a requirement ID (FEAT-XXX, CHORE-XXX, BUG-XXX) as input
   - ID parsing and type detection logic (FEAT → `requirements/features/`, CHORE → `requirements/chores/`, BUG → `requirements/bugs/`)
   - Load implementation plan from `requirements/implementation/` for FEAT IDs when available
   - Analyze all acceptance criteria, functional requirements (FR-N), and root causes (RC-N)
   - Build structured test plan using template from `assets/test-plan-template.md`
   - Type-specific plan sections:
     - FEAT: map each FR-N and AC to test plan entries; include phase deliverable verification
     - CHORE: map each AC; verify scope is correctly bounded
     - BUG: map each RC-N and associated AC; include reproduction step verification
   - Ralph loop: delegate to `qa-verifier` subagent to verify plan completeness; iterate until all inputs covered
   - **Critical**: instruct Claude to attempt to finish after each verification round — the Stop hook evaluates completion and blocks with `{"ok": false, "reason": "..."}` if gaps remain, feeding missing items back to Claude to continue work
   - Save test plan to `test/test-plans/QA-plan-{type}-{id}.md`
   - Present test plan to user for review
4. Create `assets/test-plan-template.md` with structured sections:
   - Test plan metadata (ID, type, source documents, date)
   - Existing test verification section
   - New test analysis section
   - Coverage gap analysis section
   - Code path verification section (mapped from AC/FR-N/RC-N)
   - Verification checklist
5. Add tests:
   - SKILL.md frontmatter validation (name, description, allowed-tools including Agent)
   - Skill passes `ai-skills-manager` validation
6. Run `npm run validate` and `npm test`

#### Deliverables
- [ ] `plugins/lwndev-sdlc/skills/documenting-qa/SKILL.md` — skill definition with stop hook
- [ ] `plugins/lwndev-sdlc/skills/documenting-qa/assets/test-plan-template.md` — test plan template
- [ ] `plugins/lwndev-sdlc/skills/documenting-qa/references/` — directory created (empty initially)
- [ ] Tests for documenting-qa frontmatter and validation
- [ ] Skill passes `npm run validate`

---

### Phase 3: executing-qa Skill
**Feature:** [FEAT-004](../features/FEAT-004-qa-validation-skills.md) | [#23](https://github.com/lwndev/lwndev-marketplace/issues/23)
**Status:** Pending

#### Rationale
- Depends on Phase 1 (subagent) and Phase 2 (test plan output) — must come last
- Most complex skill: orchestrates two sequential ralph loops (verification + reconciliation) with a single stop hook managing both phases
- Follows the existing pattern where execution skills are more permissive (include Bash) and more complex than their documenting counterparts
- Documentation reconciliation is the final step that closes the loop on implementation drift

#### Implementation Steps
1. Create skill directory structure:
   ```
   plugins/lwndev-sdlc/skills/executing-qa/
   ├── SKILL.md
   ├── assets/
   │   └── test-results-template.md
   └── references/
   ```
2. Write `SKILL.md` with frontmatter:
   ```yaml
   ---
   name: executing-qa
   description: Executes QA verification and documentation reconciliation from a test plan. Use when the user says "execute qa", "run qa", "verify implementation", or wants to validate a PR against its requirements.
   allowed-tools:
     - Read
     - Write
     - Edit
     - Bash
     - Glob
     - Grep
     - Agent
   hooks:
     Stop:
       - hooks:
           - type: prompt
             prompt: "You are evaluating whether Claude should stop. Context: $ARGUMENTS\n\nA prompt hook is a single-turn LLM call with no tool access — you can only evaluate based on the input fields provided, not by reading files.\n\nIf stop_hook_active is true in the input, respond {\"ok\": true} immediately to prevent infinite loops.\n\nOtherwise, examine last_assistant_message to determine the current phase:\n(1) If QA verification is in progress: does Claude's message indicate the qa-verifier returned a clean pass verdict with no remaining issues?\n(2) If verification passed and documentation reconciliation is in progress: does Claude's message indicate all reconciliation areas are covered (affected files updated, acceptance criteria modifications documented, implementation steps updated, deviation summary added where needed)?\n\nRespond {\"ok\": true} if the current phase is complete based on Claude's message, or {\"ok\": false, \"reason\": \"what appears to remain\"} if not."
             model: haiku
   ---
   ```
3. Write SKILL.md body with workflow instructions:
   - Accept a requirement ID (FEAT-XXX, CHORE-XXX, BUG-XXX) as input
   - Load test plan from `test/test-plans/QA-plan-{type}-{id}.md` — error if not found with guidance to run `documenting-qa` first
   - **Verification ralph loop:**
     - Delegate to `qa-verifier` subagent with the test plan and source documents
     - `qa-verifier` runs tests, checks coverage, verifies code paths
     - If issues found: auto-fix (write missing tests, fix broken tests, correct logic mismatches)
     - **Critical**: after each fix-and-verify round, attempt to finish — the Stop hook evaluates and blocks with `{"ok": false, "reason": "..."}` if verification hasn't passed, feeding remaining issues back to Claude
     - Loop until `qa-verifier` returns a clean pass verdict
   - **Reconciliation loop** (runs after verification passes):
     - Compare PR diff against requirements document
     - Update affected files lists to match actual changes
     - Mark modified/added/descoped acceptance criteria
     - Update implementation steps for plan phases (FEAT)
     - Document new root causes if discovered (BUG)
     - Add deviation summary when implementation diverged
     - After each reconciliation pass, attempt to finish — the same Stop hook detects the reconciliation phase and blocks with `{"ok": false, "reason": "..."}` if areas remain uncovered
     - Loop until all reconciliation areas are covered
   - The single Stop hook manages both phases by detecting which phase Claude is in from `last_assistant_message` context
   - When `stop_hook_active` is `true` in the hook input, the hook returns `{"ok": true}` to prevent infinite loops
   - Type-specific execution:
     - FEAT: verify FR-N coverage, reconcile feature req doc + implementation plan
     - CHORE: verify AC met and scope minimal, reconcile chore doc
     - BUG: verify RC-N targeted tests, reconcile bug doc including reproduction steps
   - Preserve existing document functionality (status tracking, deliverable checkboxes, root cause tracking)
   - Save results to `test/test-results/QA-results-{type}-{id}.md`
4. Create `assets/test-results-template.md` with structured sections:
   - Results metadata (ID, type, date, verdict)
   - Test suite results (pass/fail counts, failures)
   - Coverage analysis (gaps identified, gaps resolved)
   - Code path verification results
   - Reconciliation summary (changes made to requirements docs)
   - Deviation notes
5. Add tests:
   - SKILL.md frontmatter validation (name, description, allowed-tools including Bash and Agent)
   - Skill passes `ai-skills-manager` validation
6. Run `npm run validate` and `npm test`

#### Deliverables
- [ ] `plugins/lwndev-sdlc/skills/executing-qa/SKILL.md` — skill definition with multi-phase stop hook
- [ ] `plugins/lwndev-sdlc/skills/executing-qa/assets/test-results-template.md` — test results template
- [ ] `plugins/lwndev-sdlc/skills/executing-qa/references/` — directory created (empty initially)
- [ ] Tests for executing-qa frontmatter and validation
- [ ] Skill passes `npm run validate`

---

## Shared Infrastructure

### New Directories
- `plugins/lwndev-sdlc/agents/` — new directory for subagent definitions; first entry is `qa-verifier.md`
- `test/test-plans/` — output directory for test plan artifacts (created at runtime by `documenting-qa`)
- `test/test-results/` — output directory for test result artifacts (created at runtime by `executing-qa`)

### New Patterns Introduced
- **Subagent delegation**: Skills use the Agent tool to delegate verification work to `qa-verifier`, which runs on Sonnet in an isolated context. This is the first use of subagents in the plugin.
- **Stop hooks (`type: "prompt"`)**: Skills define `Stop` hooks in SKILL.md frontmatter `hooks` field. The hook sends a prompt to a Haiku model that evaluates completion criteria and returns `{"ok": true}` (allow stop) or `{"ok": false, "reason": "..."}` (block and feed reason back to Claude). The `stop_hook_active` boolean in hook input prevents infinite re-entry — when `true`, the hook must return `{"ok": true}`. **Important**: A `type: "prompt"` hook is a single-turn LLM call with **no tool access** — it can only evaluate based on `last_assistant_message` and other Stop input fields, not by reading files. The heavy verification is done by the `qa-verifier` subagent; the prompt hook evaluates Claude's stated results. (If file access were needed, `type: "agent"` would be required instead, at higher cost.)
- **Ralph loop pattern**: An orchestrator that allocates an array of requirements, delegates verification, and loops until all pass. The loop is driven by Claude attempting to finish after each round, with the Stop hook blocking if criteria aren't met. Used for both plan completeness and QA verification.
- **Plugin agents auto-discovery**: The `agents/` directory at the plugin root is auto-discovered by Claude Code (same mechanism as `skills/`). An explicit `"agents"` field in `plugin.json` is optional.

### Existing Infrastructure Reused
- `ai-skills-manager` `validate()` API for skill validation
- Existing `allowed-tools` frontmatter pattern
- Existing skill directory structure (SKILL.md, assets/, references/)
- Plugin manifest and README patterns

## Testing Strategy

**Unit Tests (per skill):**
- Verify SKILL.md frontmatter fields: name, description, allowed-tools
- `documenting-qa`: allowed-tools includes Agent but not Bash
- `executing-qa`: allowed-tools includes both Bash and Agent
- `qa-verifier`: agent definition file exists with expected model and tools declarations

**Integration Tests:**
- All skills pass `ai-skills-manager` validation via `npm run validate`
- Plugin validates successfully with the new `agents/` directory and skills

**Manual Testing:**
- Run `documenting-qa` against FEAT-003 (completed feature with implementation plan)
- Run `documenting-qa` against a CHORE-XXX
- Run `executing-qa` after test plan is generated
- Verify `qa-verifier` subagent runs on Sonnet with isolated context
- Verify stop hooks create functional ralph loops
- Verify reconciliation updates requirements docs without breaking existing structure

## Dependencies and Prerequisites

| Dependency | Version | Status |
|------------|---------|--------|
| `ai-skills-manager` | latest | Installed — provides `validate()` API for skill validation |
| Claude Code plugin system | latest | Required — provides `allowed-tools`, stop hooks (`type: "prompt"`), `agents/` directory support |
| Existing `lwndev-sdlc` plugin | v1.0.0 | Installed — 7 existing skills, plugin manifest, README |

### Prerequisites
- Claude Code supports `agents/` directory in plugins (for subagent definitions)
- Claude Code supports `Stop` hooks with `type: "prompt"` in skill frontmatter
- Claude Code supports `stop_hook_active` field for loop re-entry detection

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| `agents/` directory not supported by plugin validation | High | Medium | Test in Phase 1 before building skills that depend on it; fall back to inline agent prompts if needed |
| Stop hook `type: "prompt"` not supported in skill frontmatter | High | Medium | Test in Phase 2 with simpler single-loop skill first; document manual loop alternative if hooks unavailable |
| `stop_hook_active` re-entry detection not available | Med | Medium | Implement iteration counter as fallback; cap loop iterations at a reasonable maximum |
| `qa-verifier` Sonnet model insufficient for complex verification | Med | Low | Allow model override in agent definition; escalate to Opus for specific verification tasks if needed |
| Plugin validation fails with new directory structure | Med | Low | Validate early in Phase 1; `agents/` directory may be ignored by validator (acceptable) |
| Ralph loop runs indefinitely due to unfixable issues | Med | Low | Stop hooks include escape hatch; user can always interrupt; cap iterations in skill instructions |
| Reconciliation corrupts existing requirement doc formatting | Med | Low | Instruct skill to preserve existing structure; test against real documents in manual testing |

## Success Criteria

### Per-Phase
- Phase 1: `qa-verifier.md` exists with correct model/tools; plugin validates; README updated
- Phase 2: `documenting-qa` generates a test plan from any requirement type; stop hook creates functional completeness loop
- Phase 3: `executing-qa` runs verification and reconciliation loops; produces test results; reconciles requirements docs

### Overall
- Both new skills pass `ai-skills-manager` validation
- Plugin manifest reflects new version and capabilities
- QA workflow chain (`documenting-qa` → `executing-qa`) works end-to-end
- Existing 7 skills are unaffected — no regressions
- All tests pass (`npm test`)

## Code Organization
```
plugins/lwndev-sdlc/
├── .claude-plugin/
│   └── plugin.json                          # Phase 1 — version bump, description update
├── agents/                                  # Phase 1 — NEW directory
│   └── qa-verifier.md                       # Phase 1 — subagent definition
├── skills/
│   ├── documenting-qa/                      # Phase 2 — NEW skill
│   │   ├── SKILL.md
│   │   ├── assets/
│   │   │   └── test-plan-template.md
│   │   └── references/
│   ├── executing-qa/                        # Phase 3 — NEW skill
│   │   ├── SKILL.md
│   │   ├── assets/
│   │   │   └── test-results-template.md
│   │   └── references/
│   ├── documenting-features/                # existing — unchanged
│   ├── creating-implementation-plans/       # existing — unchanged
│   ├── implementing-plan-phases/            # existing — unchanged
│   ├── documenting-chores/                  # existing — unchanged
│   ├── executing-chores/                    # existing — unchanged
│   ├── documenting-bugs/                    # existing — unchanged
│   └── executing-bug-fixes/                 # existing — unchanged
└── README.md                                # Phase 1 — updated
```
