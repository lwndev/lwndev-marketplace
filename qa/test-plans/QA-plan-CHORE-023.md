# QA Test Plan: Add Finalizing Workflow Skill

## Metadata

| Field | Value |
|-------|-------|
| **Plan ID** | QA-plan-CHORE-023 |
| **Requirement Type** | CHORE |
| **Requirement ID** | CHORE-023 |
| **Source Documents** | `requirements/chores/CHORE-023-add-finalizing-workflow-skill.md` |
| **Date Created** | 2026-03-26 |

## Existing Test Verification

Tests that already exist and must continue to pass (regression baseline):

| Test File | Description | Status |
|-----------|-------------|--------|
| `scripts/__tests__/build.test.ts` | Validates all plugins via `npm run validate`, checks skill count (currently expects 10 — must be updated to 11) | PENDING |
| `scripts/__tests__/skill-utils.test.ts` | Verifies plugin discovery and skill enumeration; new skill must appear in `getSourceSkills('lwndev-sdlc')` results | PENDING |
| `scripts/__tests__/scaffold.test.ts` | Scaffold tool tests; should be unaffected | PENDING |
| `scripts/__tests__/constants.test.ts` | Path constant tests; should be unaffected | PENDING |

## New Test Analysis

New or modified tests that should be created or verified during QA execution:

| Test Description | Target File(s) | Requirement Ref | Priority |
|-----------------|----------------|-----------------|----------|
| Update skill count assertions from 10 to 11 (two locations: validation count and readdir count) | `scripts/__tests__/build.test.ts` | AC6 | High |
| Verify `finalizing-workflow` appears in `getSourceSkills` output | `scripts/__tests__/skill-utils.test.ts` | AC1 | Medium |

## Coverage Gap Analysis

Code paths and functionality that lack test coverage:

| Gap Description | Affected Code | Requirement Ref | Recommendation |
|----------------|---------------|-----------------|----------------|
| SKILL.md YAML frontmatter validity | `plugins/lwndev-sdlc/skills/finalizing-workflow/SKILL.md` | AC2 | Covered by `npm run validate` (build.test.ts) — no additional test needed |
| Edge case handling (no PR, merge conflicts, dirty directory) | `plugins/lwndev-sdlc/skills/finalizing-workflow/SKILL.md` | AC5 | Manual review — edge case instructions are prompt-level, not executable code |
| Merge and checkout sequence correctness | `plugins/lwndev-sdlc/skills/finalizing-workflow/SKILL.md` | AC3, AC4 | Manual review — skill prompt describes a deterministic git sequence executed by the LLM at runtime |

## Code Path Verification

Traceability from acceptance criteria to implementation:

| Requirement | Description | Expected Code Path | Verification Method |
|-------------|-------------|-------------------|-------------------|
| AC1 | Skill directory exists with valid SKILL.md | `plugins/lwndev-sdlc/skills/finalizing-workflow/SKILL.md` | Glob for file existence + `npm run validate` |
| AC2 | SKILL.md has correct YAML frontmatter (name, description) and prompt instructions | `plugins/lwndev-sdlc/skills/finalizing-workflow/SKILL.md` frontmatter | `npm run validate` checks frontmatter; code review for prompt content |
| AC3 | Skill identifies current branch and associated PR before merging | SKILL.md prompt instructions | Code review — verify prompt instructs branch/PR identification before merge |
| AC4 | Skill merges PR via `gh pr merge`, checks out `main`, fetches, and pulls | SKILL.md prompt instructions | Code review — verify prompt describes the full 4-step sequence |
| AC5 | Skill handles edge cases: no PR, merge conflicts, dirty working directory | SKILL.md prompt instructions | Code review — verify prompt includes handling for all three edge cases |
| AC6 | Plugin validates successfully (`npm run validate`) | `scripts/build.ts` validation pipeline | Automated test — `npm run validate` exits 0; update `build.test.ts` skill count to 11 |
| AC7 | Plugin README updated to list the new skill in workflow chains | `plugins/lwndev-sdlc/README.md` | Code review — verify skill table includes `finalizing-workflow` entry |
| AC8 | CLAUDE.md updated to reflect new skill in workflow chains and skill listing | `CLAUDE.md` | Code review — verify workflow chains and skill directory tree include `finalizing-workflow` |
| AC9 | `npm audit fix` resolves all high/critical vulnerabilities | `package-lock.json` | Automated — `npm audit --audit-level=high` exits 0 |
| AC10 | Pre-commit hook updated to `--audit-level=high` | `.husky/pre-commit` | Code review — verify hook uses `npm audit --audit-level=high` |

## Deliverable Verification

| Deliverable | Source | Expected Path | Exists |
|-------------|--------|---------------|--------|
| Skill directory with SKILL.md | AC1 | `plugins/lwndev-sdlc/skills/finalizing-workflow/SKILL.md` | PENDING |
| Updated plugin README | AC7 | `plugins/lwndev-sdlc/README.md` | YES (to be modified) |
| Updated project CLAUDE.md | AC8 | `CLAUDE.md` | YES (to be modified) |
| Updated package-lock.json | AC9 | `package-lock.json` | YES (to be modified) |
| Updated pre-commit hook | AC10 | `.husky/pre-commit` | YES (to be modified) |

## Verification Checklist

- [ ] All existing tests pass (regression baseline)
- [ ] All AC entries (AC1–AC10) have corresponding test plan entries
- [ ] Coverage gaps are identified with recommendations
- [ ] Code paths trace from requirements to implementation
- [ ] New test recommendations are actionable and prioritized
- [ ] `build.test.ts` skill count updated from 10 to 11
