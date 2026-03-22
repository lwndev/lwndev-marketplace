# Chore: Changelog Summarization

## Chore ID

`CHORE-019`

## GitHub Issue

[#59](https://github.com/lwndev/lwndev-marketplace/issues/59)

## Category

`refactoring`

## Description

Refactor changelog generation in the release script to produce concise, user-facing summaries instead of one bullet per commit. The current approach dumps every commit verbatim, resulting in noisy changelogs filled with entries like "address review feedback" and "mark CHORE-015 as completed" that provide no value to users.

## Affected Files

- `scripts/release.ts` — `generateChangelog()` and `groupCommitsByType()` (lines 121–177)
- `scripts/lib/git-utils.ts` — `getCommitsSinceTag()` (lines 65–87)
- `.claude/skills/releasing-plugins/SKILL.md` — skill workflow instructions
- `plugins/lwndev-sdlc/CHANGELOG.md` — existing changelog (will reflect new format on next release)

## Acceptance Criteria

### Script-level (`scripts/release.ts`, `scripts/lib/git-utils.ts`)
- [x] Noise commits are filtered out before changelog generation (e.g., "address review feedback", "mark * as completed", "update * status", merge commits)
- [x] Related commits are collapsed by scope/feature into single descriptive entries
- [x] `generateChangelog()` produces a concise, user-facing summary rather than one bullet per commit
- [x] The release script (`npm run release`) continues to run non-interactively
- [x] New tests cover the filtering and collapsing logic

### Skill-level (`.claude/skills/releasing-plugins/SKILL.md`)
- [x] The releasing-plugins skill workflow integrates summarization (either as a pre-step before the script or a post-step edit of the generated changelog)

### General
- [x] Existing tests pass after changes

## Completion

**Status:** `Completed`

**Completed:** 2026-03-22

**Pull Request:** [#61](https://github.com/lwndev/lwndev-marketplace/pull/61)

## Notes

- The release script runs non-interactively and commits automatically, so any AI-assisted summarization must happen in the skill workflow (before or after the script), not within the script itself.
- The skill already reviews the release commit (step 6 in SKILL.md) — summarization could be added as a pre-step or as a post-step edit of the generated changelog before final commit.
- A hybrid approach is likely best: script-level filtering of noise commits + skill-level summarization of remaining entries into meaningful changelog lines.
