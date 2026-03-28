# Feature Requirements: Code-Review Reconciliation Mode for Reviewing Requirements

## Overview

Add a third operating mode to the `reviewing-requirements` skill — **code-review reconciliation** — that runs after a PR has been reviewed and its findings addressed. This mode produces an advisory drift report covering areas that `executing-qa`'s reconciliation loop does not: test plan staleness, GitHub issue updates, and a preview of requirements-to-code drift before QA execution begins.

## Feature ID
`FEAT-007`

## GitHub Issue
[#66](https://github.com/lwndev/lwndev-marketplace/issues/66)

## Priority
High - Fills a gap between code review and QA execution; without it, test plan staleness and requirements drift go undetected until QA fails or produces misleading results.

## User Story

As a developer using the SDLC plugin, I want the reviewing-requirements skill to detect when a PR exists for my requirement and report test plan staleness, suggest GitHub issue updates, and preview requirements drift so that I can address documentation gaps before QA execution begins.

## Skill Invocation

The skill is invoked the same way as existing modes:

```
/reviewing-requirements <path-or-id>
```

### Arguments
- `<path-or-id>` (required) - Path to a requirement document, or a requirement ID (e.g., `FEAT-007`, `CHORE-003`, `BUG-001`)

Mode is auto-detected based on context:
- **Standard review** — no test plan or PR exists
- **Test-plan reconciliation** — test plan exists, no PR yet
- **Code-review reconciliation** — PR exists for the requirement ID (new)

### PR Detection
The skill detects an associated PR via:
1. **Branch naming convention**: Search for a PR from a branch matching `feat/{ID}-*`, `chore/{ID}-*`, or `fix/{ID}-*` (case-insensitive on the ID portion)
2. **User-provided PR number**: The user may pass a PR number directly (e.g., `/reviewing-requirements FEAT-007 --pr 85`)

If both a test plan and a PR exist, code-review reconciliation takes precedence (it is the later workflow step).

### Examples
```
/reviewing-requirements FEAT-007
/reviewing-requirements FEAT-007 --pr 85
/reviewing-requirements requirements/features/FEAT-007-code-review-reconciliation-mode.md
```

## Functional Requirements

### FR-1: PR Detection and Mode Entry
- After resolving the requirement document (existing Step 1) and checking for a test plan (existing Step 1.5), check for an associated PR
- Use `gh pr list --head <branch-pattern> --json number,headRefName,state` to search for PRs matching the branch naming conventions `feat/{ID}-*`, `chore/{ID}-*`, `fix/{ID}-*`
- If a `--pr` flag is provided, use that PR number directly via `gh pr view <number>`
- If a PR is found, enter code-review reconciliation mode
- If multiple PRs match the branch pattern, use the most recently updated open PR; if no open PRs exist, list all matching PRs and ask the user to specify
- If both a test plan and a PR exist, code-review reconciliation takes precedence
- If the PR is a draft, note it in the mode display (e.g., `Draft PR`)
- Display the detected mode: `Detected mode: Code-review reconciliation (found PR #N from branch <branch-name>)` (or `found Draft PR #N` for draft PRs)

### FR-2: Test Plan ↔ Code Drift Detection
- Fetch the PR diff using `gh pr diff <number>`
- Load the test plan from `qa/test-plans/QA-plan-{ID}.md`
- If no test plan exists, skip this step and note it as Info: "No test plan found; test plan drift detection skipped"
- Compare test plan entries (Code Path Verification, New Test Analysis, Coverage Gap Analysis) against the PR diff
- Flag test plan entries that reference:
  - **Changed function signatures or APIs**: Parameter changes, renamed functions, modified return types visible in the diff
  - **Removed or renamed files**: Test entries referencing files deleted or renamed in the PR
  - **Modified behavior**: Test entries whose "Expected Code Path" or "Description" describes behavior that the diff alters
- For each flagged entry, describe specifically what changed in the PR diff and how it affects the test plan entry

### FR-3: GitHub Issue Update Suggestions
- Compare the PR diff and requirement document against the linked GitHub issue (from the requirement document's "GitHub Issue" field)
- Suggest updates to the GitHub issue for:
  - **Scope changes**: Behavior added or removed during implementation that differs from the original issue description
  - **Decisions made during review**: Design choices or trade-offs resolved during code review that should be documented on the issue
  - **Deferred work**: Items from the original issue or requirements that were intentionally deferred and should be noted for follow-up
- Each suggestion should include a draft comment or edit description the user can review before posting
- Do NOT post or modify the GitHub issue directly — suggestions only

### FR-4: Advisory Requirements ↔ Code Drift Summary
- Compare the PR diff against the requirement document's functional requirements (FR-N), acceptance criteria, and edge cases
- Identify divergences where the implementation differs from what the requirements specify:
  - FRs that describe behavior not present in the PR diff (potentially unimplemented or changed)
  - PR changes that introduce behavior not described in any FR (potentially undocumented additions)
  - Acceptance criteria that may not hold given the actual implementation
- If `gh pr diff` is unavailable (e.g., `gh` CLI not authenticated), fall back to `git diff <base-branch>...HEAD` for local comparison
- Present findings as an advisory summary only — no auto-fixes
- Explicitly note that `executing-qa`'s reconciliation loop will handle the actual document updates

### FR-5: Scope Boundary Enforcement
- The code-review reconciliation mode must NOT perform or duplicate work that `executing-qa`'s reconciliation handles:
  - No updates to affected files lists
  - No updates to implementation plan phases, deliverables, or status
  - No deviation summaries added to documents
  - No auto-fix of requirements documents
- The mode reports findings only; it is advisory in nature
- Findings should reference the appropriate downstream handler when relevant (e.g., "This drift will be addressed by `executing-qa` reconciliation")

### FR-6: Existing Mode Preservation
- Standard review behavior (Steps 1-9 in current SKILL.md) must remain unchanged
- Test-plan reconciliation behavior (Steps R1-R7 in current SKILL.md) must remain unchanged
- Mode detection logic must correctly route to all three modes without regressions

### FR-7: Findings Presentation
- Use the same severity classification as existing modes (Error/Warning/Info)
- Organize findings by category:
  1. **Test Plan Staleness** (FR-2) — entries that may fail or verify the wrong thing
  2. **GitHub Issue Suggestions** (FR-3) — recommended issue updates
  3. **Requirements ↔ Code Drift** (FR-4) — advisory divergence preview
- Display a summary count: `Code-review reconciliation for {ID} (PR #{N}): Found **N errors**, **N warnings**, **N info**`
- Each finding includes: severity identifier (`[E1]`, `[W1]`, `[I1]`), category, description, and actionable suggestion

### FR-8: SKILL.md Updates
- Update the `reviewing-requirements` SKILL.md to document the code-review reconciliation mode
- Update the "Relationship to Other Skills" section to reflect the new workflow position:
  ```
  PR review → reviewing-requirements (code-review reconciliation) → executing-qa
  ```
- Update the description in YAML frontmatter to mention the third mode
- Update the mode detection table and verification checklist
- Per the token budget note on #66, consider trimming existing verbosity to keep the file under ~6500 tokens after adding the new mode

## Output Format

```
## Requirements Review: FEAT-007

### Mode
Code-review reconciliation (PR #85 from branch `feat/FEAT-007-code-review-reconciliation`)

### Summary
Found **1 error**, **3 warnings**, **2 info** in FEAT-007-code-review-reconciliation-mode.md

### Test Plan Staleness

**[E1] Code Path Verification — CPV-3**
Test entry references `validatePR()` which was renamed to `detectPR()` in the PR diff (src/reviewer.ts +42).
Suggestion: Update test plan entry CPV-3 to reference `detectPR()`.

**[W1] New Test Analysis — NTA-2**
Test entry expects error response for missing branch, but PR adds a fallback to `--pr` flag (src/reviewer.ts +67).
Suggestion: Update test expectation to account for the fallback behavior.

### GitHub Issue Suggestions

**[I1] Scope Change**
The PR adds `--pr` flag support not mentioned in the original issue #66.
Suggestion: Post a comment noting the `--pr` flag addition as a usability enhancement.

**[I2] Deferred Work**
FR-3 (GitHub issue suggestions) was implemented as read-only; auto-posting was deferred.
Suggestion: Note on #66 that auto-posting is out of scope for this PR.

### Requirements ↔ Code Drift

**[W2] FR-2 — Test Plan Drift Detection**
Requirement specifies checking "Modified behavior" but implementation only checks function signature changes and file renames.
Note: This drift will be addressed by `executing-qa` reconciliation.

**[W3] Acceptance Criteria — AC-4**
Criterion "advisory summary does NOT duplicate executing-qa work" — implementation includes an affected-files mention in the summary output.
Note: This drift will be addressed by `executing-qa` reconciliation.

---
Findings are advisory. Run `/executing-qa` after addressing any test plan staleness issues.
```

## Non-Functional Requirements

### NFR-1: Performance
- PR diff fetching should use `gh pr diff` with no file-count limit but should process only changed files (not the entire repo)
- Test plan comparison should use targeted string matching against diff hunks, not line-by-line full-file comparison
- Complete analysis of a typical PR (< 50 changed files) within a single interaction

### NFR-2: Error Handling
- If `gh` CLI is not authenticated or unavailable: report as Warning and skip PR-dependent checks (FR-1, FR-2, FR-3), proceeding with FR-4 only using the branch diff
- If the PR is closed or merged: proceed normally but note the PR state in the mode banner
- If the test plan does not exist: skip FR-2 (test plan drift), note as Info, continue with FR-3 and FR-4
- If the GitHub issue referenced in the requirement doc is inaccessible: skip FR-3, note as Warning

### NFR-3: Non-Destructive
- This mode is entirely advisory — no documents are modified
- GitHub issue suggestions are presented as draft text for user review, never posted automatically
- No test plan entries are updated automatically

## Dependencies

- `gh` CLI for PR detection, diff fetching, and issue access
- Existing `reviewing-requirements` skill infrastructure (document resolution, mode detection, findings presentation)
- QA test plan format as produced by `documenting-qa` skill
- `executing-qa` reconciliation loop (downstream consumer of this mode's output)

## Edge Cases

1. **No PR exists for the requirement**: Mode detection falls through to test-plan reconciliation or standard review — no change to existing behavior
2. **PR exists but no test plan**: Skip FR-2 (test plan staleness), run FR-3 and FR-4 only, note the skip as Info
3. **PR is a draft**: Proceed normally but note "Draft PR" in the mode banner — drift may change before the PR is finalized
4. **Multiple PRs match the branch pattern**: List all matching PRs and ask the user to specify which one, or use the most recently updated open PR
5. **PR diff is very large (> 100 changed files)**: Warn the user that analysis may be incomplete and focus on files referenced in the requirements and test plan
6. **Requirement has no GitHub Issue field**: Skip FR-3, note as Info ("No GitHub issue linked; issue suggestions skipped")
7. **Branch naming does not follow convention**: PR is not auto-detected; user must provide `--pr` flag. Display: "No PR detected via branch naming convention. Use `--pr <number>` to specify a PR."
8. **PR is from a fork**: `gh pr diff` should still work; proceed normally
9. **Invalid `--pr` value**: If the provided PR number does not exist or is non-numeric, display an error and fall back to branch-based PR detection

## Testing Requirements

### Unit Tests
- Mode detection logic: verify code-review reconciliation is entered when a PR exists
- Mode precedence: verify code-review reconciliation takes precedence over test-plan reconciliation when both a PR and test plan exist
- Branch pattern matching for all conventions (`feat/`, `chore/`, `fix/`)
- `--pr` flag parsing and validation

### Integration Tests
- End-to-end code-review reconciliation with a sample PR diff, test plan, and requirement document
- Verify FR-2 flags stale test plan entries correctly
- Verify FR-3 produces relevant GitHub issue suggestions
- Verify FR-4 detects requirements-to-code drift
- Verify FR-7 findings are organized by the three categories (Test Plan Staleness, GitHub Issue Suggestions, Requirements ↔ Code Drift) with correct severity identifiers and summary format
- Verify FR-5 scope boundary: no auto-fixes applied, no implementation plan modifications
- Verify existing modes (standard review, test-plan reconciliation) remain unaffected

### Manual Testing
- Run against a real PR with known drift between requirements and implementation
- Verify findings are actionable and correctly categorized
- Confirm no documents are modified during the review
- Test with missing test plan, missing GitHub issue, and draft PR edge cases

## Acceptance Criteria

- [ ] The skill detects an associated PR via branch naming convention (`feat/{ID}-*`, `chore/{ID}-*`, `fix/{ID}-*`) or user-provided `--pr` flag and enters code-review reconciliation mode
- [ ] Test plan entries that reference changed behavior, structure, or interfaces are flagged with specific descriptions of what changed
- [ ] GitHub issue update suggestions are included (scope changes, decisions, deferred work) as draft text for user review
- [ ] An advisory summary of requirements ↔ code drift is presented (findings only, no auto-fix)
- [ ] The advisory summary does NOT duplicate work that `executing-qa`'s reconciliation handles (no affected files updates, no implementation plan updates, no deviation summaries)
- [ ] Existing standard review and test-plan reconciliation behaviors are unchanged
- [ ] The "Relationship to Other Skills" section in SKILL.md is updated to reflect the new workflow position and the boundary with `executing-qa`
- [ ] Severity classification (Error/Warning/Info) applies to code-review reconciliation findings using the same conventions as other modes
- [ ] SKILL.md description frontmatter is updated to mention all three modes
- [ ] Mode detection correctly routes to all three modes: standard review, test-plan reconciliation, code-review reconciliation
- [ ] Token budget is respected: SKILL.md stays under ~6500 tokens after additions (trim existing verbosity if needed)
