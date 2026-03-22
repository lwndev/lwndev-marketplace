# Chore: Remove Unneeded .gitkeep Files

## Chore ID

`CHORE-008`

## GitHub Issue

[#15](https://github.com/lwndev/lwndev-marketplace/issues/15)

## Category

`cleanup`

## Description

Remove `.gitkeep` placeholder files from skill directories where they serve no purpose. Two `.gitkeep` files exist in empty `references/` directories for skills that don't use reference documentation. Since `references/` is optional per the skill structure spec, these directories and their `.gitkeep` files can be removed entirely.

## Affected Files

- `plugins/lwndev-sdlc/skills/documenting-qa/references/.gitkeep`
- `plugins/lwndev-sdlc/skills/executing-qa/references/.gitkeep`

## Acceptance Criteria

- [ ] `.gitkeep` files removed from `documenting-qa/references/` and `executing-qa/references/`
- [ ] Empty `references/` directories no longer tracked by git
- [ ] No skill SKILL.md files reference the removed directories
- [ ] Build validates successfully (`npm run validate`)
- [ ] All tests pass (`npm test`)

## Completion

**Status:** `Completed`

**Completed:** 2026-03-21

**Pull Request:** [#53](https://github.com/lwndev/lwndev-marketplace/pull/53)

## Notes

- The original issue (#15) referenced `.gitkeep` files in `src/skills/executing-bug-fixes/` which no longer exist after the repo restructure from `src/` to `plugins/`. The actual remaining `.gitkeep` files are in different skills (`documenting-qa` and `executing-qa`).
- Both `references/` directories are empty (`.gitkeep` is the sole content) and neither skill's SKILL.md references them.
- GitHub issue #15 should be updated to reflect the corrected file paths.
