# QA Test Plan: Releasing Stop Hook False Positive

## Metadata

| Field | Value |
|-------|-------|
| **Plan ID** | QA-plan-BUG-008 |
| **Requirement Type** | BUG |
| **Requirement ID** | BUG-008 |
| **Source Documents** | `requirements/bugs/BUG-008-releasing-stop-hook-false-positive.md` |
| **Date Created** | 2026-04-05 |

## Existing Test Verification

Tests that already exist and must continue to pass (regression baseline):

| Test File | Description | Status |
|-----------|-------------|--------|
| `scripts/__tests__/build.test.ts` | Validates all plugins pass `npm run validate` | PASS |

## New Test Analysis

New or modified tests that should be created or verified during QA execution:

| Test Description | Target File(s) | Requirement Ref | Priority | Status |
|-----------------|----------------|-----------------|----------|--------|
| Stop hook allows stop when message contains no release-related keywords (non-release message) | `.claude/skills/releasing-plugins/scripts/stop-hook.sh` | RC-1, RC-2, AC-1 | High | PASS |
| Stop hook blocks when Phase 1 criteria not met (message has release keywords but no PR/reinvoke) | `.claude/skills/releasing-plugins/scripts/stop-hook.sh` | RC-1, AC-2 | High | PASS |
| Stop hook allows stop when Phase 1 is complete (PR created + re-invoke mentioned) | `.claude/skills/releasing-plugins/scripts/stop-hook.sh` | AC-2 | High | PASS |
| Stop hook blocks during Phase 2 when tag not pushed | `.claude/skills/releasing-plugins/scripts/stop-hook.sh` | AC-3 | High | PASS |
| Stop hook allows stop during Phase 2 when tag is pushed | `.claude/skills/releasing-plugins/scripts/stop-hook.sh` | AC-3 | Medium | PASS |
| Fix does not modify Claude Code harness or hook input schema | `.claude/skills/releasing-plugins/scripts/stop-hook.sh` | RC-2, AC-4 | Medium | PASS |

## Coverage Gap Analysis

| Gap Description | Affected Code | Requirement Ref | Recommendation |
|----------------|---------------|-----------------|----------------|
| End-to-end test of stop hook during live `/releasing-plugins` invocation | Stop hook stdin JSON format | RC-1 | Manual testing: invoke `/releasing-plugins`, complete Phase 1, perform unrelated task, verify no false positive |

## Code Path Verification

| Requirement | Description | Expected Code Path | Verification Method | Status |
|-------------|-------------|-------------------|-------------------|--------|
| RC-1 | Hook evaluates only `last_assistant_message` — non-release messages should be allowed | `.claude/skills/releasing-plugins/scripts/stop-hook.sh` — early exit for non-release messages | Code review: verify non-release message detection exits 0 | PASS |
| RC-2 | Hook has no state persistence — fix must add state or use pattern exclusion | `.claude/skills/releasing-plugins/scripts/stop-hook.sh` — state check or keyword detection | Code review: verify the chosen approach handles stateless-ness | PASS |
| AC-1 | No block on non-release messages after Phase 1 | Stop hook script | Test: pipe non-release JSON to hook, verify exit 0 | PASS |
| AC-2 | Still blocks during Phase 1 when criteria not met | Stop hook script | Test: pipe incomplete Phase 1 JSON to hook, verify exit 2 | PASS |
| AC-3 | Still blocks during Phase 2 when tag not pushed | Stop hook script | Test: pipe Phase 2 JSON without tag-pushed to hook, verify exit 2 | PASS |
| AC-4 | No harness or schema changes | Stop hook script | Code review: only `.claude/skills/releasing-plugins/scripts/stop-hook.sh` modified | PASS |

## Deliverable Verification

| Deliverable | Source | Expected Path | Status |
|-------------|--------|---------------|--------|
| Updated stop hook script | Bug fix | `.claude/skills/releasing-plugins/scripts/stop-hook.sh` | PASS |

## Plan Completeness Checklist

- [x] All existing tests pass (regression baseline)
- [x] All RC-N entries have corresponding test plan entries
- [x] All AC entries have corresponding test plan entries
- [x] Coverage gaps are identified with recommendations
- [x] Code paths trace from requirements to implementation
- [x] New test recommendations are actionable and prioritized
