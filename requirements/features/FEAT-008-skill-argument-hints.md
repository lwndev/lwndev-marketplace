# Feature Requirements: Skill Argument-Hint Support

## Overview

Add `argument-hint` frontmatter to all skills in the `lwndev-sdlc` plugin and update skill instructions to handle arguments, enabling users to pass context directly when invoking a skill (e.g., `/executing-chores CHORE-007`) instead of relying on interactive prompts or directory scanning.

## Feature ID
`FEAT-008`

## GitHub Issue
[#14](https://github.com/lwndev/lwndev-marketplace/issues/14)

## Priority
Medium - Quality-of-life improvement that streamlines existing workflows without adding new capabilities

## User Story

As a plugin user, I want to pass arguments directly when invoking skills so that I can skip discovery prompts and immediately target the document or context I need.

## Functional Requirements

### FR-1: Add `argument-hint` Frontmatter to Execution Skills

Add the `argument-hint` field to the YAML frontmatter in SKILL.md for execution-oriented skills that accept a document identifier:

| Skill | `argument-hint` value |
|-------|----------------------|
| `executing-chores` | `<chore-id>` |
| `executing-bug-fixes` | `<bug-id>` |
| `implementing-plan-phases` | `<plan-file> [phase-number]` |
| `executing-qa` | `<requirement-id>` |

- The hint must be ≤ 200 characters (enforced by `ai-skills-manager` check `argumentHintFormat`)
- The hint should use `<angle-brackets>` for required arguments and `[square-brackets]` for optional ones

### FR-2: Add `argument-hint` Frontmatter to Documentation Skills

Add the `argument-hint` field for documentation skills that accept an optional name or title:

| Skill | `argument-hint` value |
|-------|----------------------|
| `documenting-features` | `[feature-name or #issue-number]` |
| `documenting-chores` | `[chore-title]` |
| `documenting-bugs` | `[bug-title]` |
| `documenting-qa` | `<requirement-id>` |

### FR-3: Add `argument-hint` Frontmatter to Planning/Review Skills

| Skill | `argument-hint` value |
|-------|----------------------|
| `creating-implementation-plans` | `<requirements-file>` |
| `reviewing-requirements` | `<requirements-file>` |

### FR-4: Update Skill Instructions for Argument Handling

Each skill's SKILL.md body must include an argument-handling section that describes:

- **When argument is provided**: How to interpret and use the argument to locate the target document or pre-fill input, skipping the discovery/prompting step
- **When no argument is provided**: Fall back to current behavior (scan directories, prompt interactively)

Skills should rely on the default appended `ARGUMENTS: <value>` delivery mechanism (which applies when `$ARGUMENTS` is not present in the SKILL.md body) rather than inline `$ARGUMENTS` substitution, since all arguments are optional or conditional. See `docs/shared/docs/anthropic/docs/en/skills.md` (lines 202-226) for the full substitution reference.

This ensures backward compatibility — skills continue to work identically when invoked without arguments.

### FR-5: Argument Resolution for Execution Skills

When an execution skill receives an argument:

- Match the argument against files in the relevant `requirements/` subdirectory (e.g., `requirements/chores/` for `executing-chores`)
- Support matching by ID prefix (e.g., `CHORE-007` matches `CHORE-007-migrate-config.md`)
- If no match is found, inform the user and fall back to interactive selection
- If multiple matches are found, present the matches and ask the user to choose

### FR-6: Argument Resolution for Documentation Skills

When a documentation skill receives an argument:

- Use the argument as a pre-filled name/title for the document being created
- For `documenting-features`, support `#<number>` syntax to fetch a GitHub issue for context
- If the argument is ambiguous, ask the user for clarification

### FR-7: Finalizing-Workflow Skill Exclusion

The `finalizing-workflow` skill does not accept arguments and should not have an `argument-hint` added. It operates on the current branch context and has no document-targeting behavior.

## Non-Functional Requirements

### NFR-1: Validation Compatibility

- All `argument-hint` values must pass `ai-skills-manager` ^1.8.1 validation (check `argumentHintFormat`, max 200 characters)
- `argument-hint` is a Claude Code-specific frontmatter extension, not part of the open Agent Skills specification (`docs/shared/docs/agent-skills/specification.md`). Validation comes from `ai-skills-manager`, not the spec.
- The full plugin must continue to pass `npm run validate` after changes

### NFR-2: Backward Compatibility

- Skills invoked without arguments must behave identically to current behavior
- No changes to skill output format or workflow steps
- Existing automation or documentation referencing skill invocations without arguments must remain valid

### NFR-3: Consistency

- All argument hints should follow a consistent syntax convention: `<angle-brackets>` for expected arguments, `[square-brackets]` for optional ones. Both are display-only hints — neither enforces behavior at runtime.
- Values that start with a square bracket must be quoted in YAML frontmatter (e.g., `argument-hint: "[feature-name]"`) to prevent YAML from parsing them as sequences. Values where brackets appear after other text (e.g., `<plan-file> [phase-number]`) do not require quoting.
- Argument-handling sections in SKILL.md should follow a consistent pattern across all skills

## References

- `docs/shared/docs/anthropic/docs/en/skills.md` — Authoritative documentation for `argument-hint` frontmatter field, `$ARGUMENTS` substitution, and skill invocation with arguments
- `docs/shared/docs/agent-skills/specification.md` — Open Agent Skills specification (does not include `argument-hint`; it is a Claude Code-specific extension)

## Dependencies

- `ai-skills-manager` ^1.8.1 (already in use — supports `argument-hint` validation via `argumentHintFormat` check)
- Existing skill SKILL.md files in `plugins/lwndev-sdlc/skills/`

## Edge Cases

1. **Argument matches no document**: Display a clear message and fall back to interactive selection
2. **Argument matches multiple documents**: Present matches and ask user to choose
3. **Argument with typo in ID**: If no prefix match is found, fall back to interactive selection
4. **Empty argument string**: Treat as no argument; use current interactive behavior
5. **Argument for `implementing-plan-phases` with phase number**: Parse both the plan file identifier and optional phase number from the argument string (e.g., `FEAT-001 3`)
6. **`documenting-features` with `#14` syntax**: Fetch the GitHub issue and use its content to pre-fill the requirements template
7. **Out-of-range phase number for `implementing-plan-phases`**: If the phase number exceeds the plan's phase count (e.g., `FEAT-001 99` for a 3-phase plan), display available phases and ask the user to choose
8. **GitHub issue API failure for `documenting-features`**: If the `#N` issue cannot be fetched (non-existent issue, network error, auth failure), warn the user and continue with manual input

## Testing Requirements

### Unit Tests
- Verify `argument-hint` is present in frontmatter for all skills that support arguments
- Verify `finalizing-workflow` does not have `argument-hint` in frontmatter
- Validate hint values are ≤ 200 characters
- Validate hint format follows `<required>` / `[optional]` convention
- Verify argument resolution matches files by ID prefix in the correct `requirements/` subdirectory

### Integration Tests
- Full plugin validation passes (`npm run validate`) with updated frontmatter
- Build script processes updated SKILL.md files without errors

### Manual Testing
- Invoke each skill with an argument and verify it resolves correctly
- Invoke each skill without an argument and verify current behavior is preserved
- Test edge cases: no match, multiple matches, empty argument

## Acceptance Criteria

- [ ] Execution skills (`executing-chores`, `executing-bug-fixes`, `implementing-plan-phases`, `executing-qa`) have `argument-hint` in frontmatter
- [ ] Documentation skills (`documenting-features`, `documenting-chores`, `documenting-bugs`, `documenting-qa`) have `argument-hint` in frontmatter
- [ ] Planning/review skills (`creating-implementation-plans`, `reviewing-requirements`) have `argument-hint` in frontmatter
- [ ] `finalizing-workflow` does not have `argument-hint` (intentionally excluded)
- [ ] All skills with `argument-hint` include an argument-handling section with "When argument is provided" and "When no argument is provided" guidance
- [ ] All skills behave identically to their pre-FEAT-008 behavior when invoked without arguments
- [ ] Execution skills resolve arguments by prefix-matching files in the relevant `requirements/` subdirectory
- [ ] `documenting-features` resolves `#N` arguments by fetching the corresponding GitHub issue
- [ ] `argument-hint` values pass `ai-skills-manager` validation (≤ 200 chars, correct format)
- [ ] `npm run validate` passes for the full plugin
- [ ] Tests verify frontmatter includes `argument-hint` and skill body includes argument-handling instructions
