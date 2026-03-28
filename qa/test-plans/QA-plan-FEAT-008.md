# QA Test Plan: Skill Argument-Hint Support

## Metadata

| Field | Value |
|-------|-------|
| **Plan ID** | QA-plan-FEAT-008 |
| **Requirement Type** | FEAT |
| **Requirement ID** | FEAT-008 |
| **Source Documents** | `requirements/features/FEAT-008-skill-argument-hints.md`, `requirements/implementation/FEAT-008-skill-argument-hints.md` |
| **Date Created** | 2026-03-28 |

## Existing Test Verification

Tests that already exist and must continue to pass (regression baseline):

| Test File | Description | Status |
|-----------|-------------|--------|
| `scripts/__tests__/build.test.ts` | Validates all 11 skills pass `npm run validate`; verifies plugin structure | PENDING |
| `scripts/__tests__/skill-utils.test.ts` | Verifies skill discovery and SKILL.md frontmatter parsing | PENDING |
| `scripts/__tests__/scaffold.test.ts` | Tests `argument-hint` scaffold support (lines 113-134) | PENDING |
| `scripts/__tests__/documenting-features.test.ts` | Validates documenting-features SKILL.md frontmatter and structure | PENDING |
| `scripts/__tests__/documenting-chores.test.ts` | Validates documenting-chores SKILL.md frontmatter and structure | PENDING |
| `scripts/__tests__/documenting-bugs.test.ts` | Validates documenting-bugs SKILL.md frontmatter and structure | PENDING |
| `scripts/__tests__/executing-chores.test.ts` | Validates executing-chores SKILL.md frontmatter and structure | PENDING |
| `scripts/__tests__/executing-bug-fixes.test.ts` | Validates executing-bug-fixes SKILL.md frontmatter and structure | PENDING |
| `scripts/__tests__/implementing-plan-phases.test.ts` | Validates implementing-plan-phases SKILL.md frontmatter and structure | PENDING |
| `scripts/__tests__/reviewing-requirements.test.ts` | Validates reviewing-requirements SKILL.md frontmatter and structure | PENDING |
| `scripts/__tests__/documenting-qa.test.ts` | Validates documenting-qa SKILL.md frontmatter and structure | PENDING |
| `scripts/__tests__/executing-qa.test.ts` | Validates executing-qa SKILL.md frontmatter and structure | PENDING |
| `scripts/__tests__/creating-implementation-plans.test.ts` | Validates creating-implementation-plans SKILL.md frontmatter and structure | PENDING |

## New Test Analysis

New or modified tests that should be created or verified during QA execution:

| Test Description | Target File(s) | Requirement Ref | Priority |
|-----------------|----------------|-----------------|----------|
| Verify `argument-hint` present in frontmatter for 10 target skills | All 10 SKILL.md files | FR-1, FR-2, FR-3 | High |
| Verify `finalizing-workflow` does NOT have `argument-hint` | `finalizing-workflow/SKILL.md` | FR-7 | High |
| Validate all hint values are ≤ 200 characters | All 10 SKILL.md files | NFR-1 | High |
| Validate YAML quoting: values starting with `[` parse as strings | SKILL.md files with `[` hints | NFR-3 | High |
| Verify argument-handling section present in SKILL.md body | All 10 SKILL.md files | FR-4, AC-5 | High |
| Validate `argumentHintFormat` check via `validate()` API | Temp skill with representative hints | NFR-1 | Medium |
| Verify argument resolution matches files by ID prefix | Execution skill SKILL.md instructions | FR-5, AC-7 | Medium |

## Coverage Gap Analysis

Code paths and functionality that lack test coverage:

| Gap Description | Affected Code | Requirement Ref | Recommendation |
|----------------|---------------|-----------------|----------------|
| Argument delivery mechanism (`ARGUMENTS:` appended) is runtime behavior | Claude Code runtime | FR-4 | Manual verify — confirmed working via test skills |
| Argument resolution logic is instruction-based, not code | SKILL.md body text | FR-5, FR-6 | Manual verify — invoke skills with arguments |
| Backward compatibility (no-argument invocation) | All 10 SKILL.md files | NFR-2, AC-6 | Manual verify — invoke each skill without arguments |
| `documenting-features` GitHub issue resolution (`#N` syntax) | `documenting-features/SKILL.md` | FR-6, AC-8 | Manual verify — invoke `/documenting-features #14` |
| Edge case: out-of-range phase number | `implementing-plan-phases/SKILL.md` | Edge Case 7 | Manual verify |
| Edge case: GitHub API failure for `documenting-features` | `documenting-features/SKILL.md` | Edge Case 8 | Manual verify |
| Edge case: empty argument string treated as no argument | All 10 SKILL.md files | FR-4, NFR-2, Edge Case 4 | Manual verify — invoke skill with empty string |
| Edge case: argument matches no document | Execution skill SKILL.md instructions | Edge Case 1 | Manual verify |
| Edge case: argument matches multiple documents | Execution skill SKILL.md instructions | Edge Case 2 | Manual verify |

## Code Path Verification

Traceability from requirements to implementation:

| Requirement | Description | Expected Code Path | Verification Method |
|-------------|-------------|-------------------|-------------------|
| FR-1 | Add `argument-hint` to execution skills (4 skills) | `executing-chores/SKILL.md`, `executing-bug-fixes/SKILL.md`, `implementing-plan-phases/SKILL.md`, `executing-qa/SKILL.md` — frontmatter field | Automated test + `asm validate` |
| FR-2 | Add `argument-hint` to documentation skills (4 skills) | `documenting-features/SKILL.md`, `documenting-chores/SKILL.md`, `documenting-bugs/SKILL.md`, `documenting-qa/SKILL.md` — frontmatter field | Automated test + `asm validate` |
| FR-3 | Add `argument-hint` to planning/review skills (2 skills) | `creating-implementation-plans/SKILL.md`, `reviewing-requirements/SKILL.md` — frontmatter field | Automated test + `asm validate` |
| FR-4 | Argument-handling section in SKILL.md body | All 10 SKILL.md files — section after "Quick Start" with "When argument is provided" / "When no argument is provided" | Automated test (grep for section markers) |
| FR-5 | Argument resolution for execution skills (prefix matching) | Execution skill SKILL.md instructions — describe prefix matching, no-match fallback, multi-match disambiguation | Code review + manual verify |
| FR-6 | Argument resolution for documentation skills | Documentation skill SKILL.md instructions — describe name pre-fill, `#N` GitHub issue fetch, API failure handling | Code review + manual verify |
| FR-7 | `finalizing-workflow` exclusion | `finalizing-workflow/SKILL.md` — no `argument-hint` field present | Automated test (negative assertion) |
| NFR-1 | Validation compatibility | All 10 hint values pass `argumentHintFormat` check (≤ 200 chars, non-empty string) | `asm validate` per skill + `npm run validate` |
| NFR-2 | Backward compatibility | Skills invoked without arguments behave identically to pre-FEAT-008 | Manual verify |
| NFR-3 | Consistency — bracket convention and YAML quoting | All hints follow `<expected>` / `[optional]` convention; values starting with `[` are quoted | Automated test + code review |

## Deliverable Verification

| Deliverable | Source Phase | Expected Path | Exists |
|-------------|-------------|---------------|--------|
| executing-chores SKILL.md update | Phase 1 | `plugins/lwndev-sdlc/skills/executing-chores/SKILL.md` | PENDING |
| executing-bug-fixes SKILL.md update | Phase 1 | `plugins/lwndev-sdlc/skills/executing-bug-fixes/SKILL.md` | PENDING |
| implementing-plan-phases SKILL.md update | Phase 1 | `plugins/lwndev-sdlc/skills/implementing-plan-phases/SKILL.md` | PENDING |
| executing-qa SKILL.md update | Phase 1 | `plugins/lwndev-sdlc/skills/executing-qa/SKILL.md` | PENDING |
| documenting-features SKILL.md update | Phase 2 | `plugins/lwndev-sdlc/skills/documenting-features/SKILL.md` | PENDING |
| documenting-chores SKILL.md update | Phase 2 | `plugins/lwndev-sdlc/skills/documenting-chores/SKILL.md` | PENDING |
| documenting-bugs SKILL.md update | Phase 2 | `plugins/lwndev-sdlc/skills/documenting-bugs/SKILL.md` | PENDING |
| documenting-qa SKILL.md update | Phase 2 | `plugins/lwndev-sdlc/skills/documenting-qa/SKILL.md` | PENDING |
| creating-implementation-plans SKILL.md update | Phase 2 | `plugins/lwndev-sdlc/skills/creating-implementation-plans/SKILL.md` | PENDING |
| reviewing-requirements SKILL.md update | Phase 2 | `plugins/lwndev-sdlc/skills/reviewing-requirements/SKILL.md` | PENDING |
| argument-hint test file | Phase 3 | `scripts/__tests__/argument-hint.test.ts` | PENDING |
| Full plugin validation passing | Phase 3 | `npm run validate` exit code 0 | PENDING |
| Full test suite passing | Phase 3 | `npm test` exit code 0 | PENDING |

## Verification Checklist

- [ ] All existing tests pass (regression baseline)
- [ ] All FR-N entries have corresponding test plan entries (FR-1 through FR-7)
- [ ] All NFR entries have corresponding test plan entries (NFR-1 through NFR-3)
- [ ] All acceptance criteria are covered (AC-1 through AC-11)
- [ ] Coverage gaps are identified with recommendations
- [ ] Code paths trace from requirements to implementation
- [ ] Phase deliverables are accounted for (Phase 1: 4, Phase 2: 6, Phase 3: 3)
- [ ] New test recommendations are actionable and prioritized
- [ ] Edge cases 1-8 are covered in gap analysis
